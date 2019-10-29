# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2018 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module RedmineAgile
  class AgileChart
    include Redmine::I18n
    include Redmine::Utils::DateCalculation

    attr_reader :line_colors

    def initialize(data_scope, options={})
      @data_scope = data_scope
      @data_from ||= options[:data_from]
      @data_to ||= options[:data_to]
      @period_count, @scale_division = chart_periods
      @step_x_labels = @period_count > 18 ? @period_count / 12 + 1 : 1
      @fields = chart_fields_by_period
      @weekend_periods = weekend_periods
      @estimated_unit = options[:estimated_unit] || 'hours'
      @line_colors = {}
    end

    def data
      { :title => '', :y_title => '', :labels => [], :datasets => [] }
    end

    def self.data(data_scope, options = {})
      new(data_scope, options).data
    end

    protected

    def current_date_period
      date_period = (@date_to <= Date.today ? @period_count : (@period_count - (@date_to - Date.today).to_i / @scale_division - 1) + 1).round
      @current_date_period ||= date_period > 0 ? date_period : 0
    end

    def due_date_period
      due_date = (@due_date && @due_date > @date_from) ? @due_date : @date_from
      @due_date_period ||= (@due_date ? @period_count - (@date_to - due_date).to_i / @scale_division - 1 : @period_count - 1) + 1
    end

    def date_short_period?
      (@date_to - @date_from).to_i <= 31
    end

    def date_effort(issues, effort_date)
      cumulative_left = 0
      total_left = 0
      total_done = 0
      issues.each do |issue|
        done_ratio_details = issue.journals.map(&:details).flatten.select { |detail| 'done_ratio' == detail.prop_key }
        details_today_or_earlier = done_ratio_details.select { |a| a.journal.created_on.localtime.to_date <= effort_date }

        last_done_ratio_change = details_today_or_earlier.sort_by { |a| a.journal.created_on }.last
        ratio = if issue.closed? && issue.closed_on.localtime.to_date <= effort_date
                  100
                elsif last_done_ratio_change
                  last_done_ratio_change.value
                elsif (done_ratio_details.size > 0) || (issue.closed? && issue.closed_on > effort_date)
                  0
                else
                  issue.done_ratio.to_i
                end

        if @estimated_unit == 'hours'
          cumulative_left += (issue.estimated_hours.to_f * ratio.to_f / 100.0)
          total_left += (issue.estimated_hours.to_f * (100 - ratio.to_f) / 100.0)
          total_done += (issue.estimated_hours.to_f * ratio.to_f / 100.0)
        else
          cumulative_left += (issue.story_points.to_f * ratio.to_f / 100.0)
          total_left += (issue.story_points.to_f * (100 - ratio.to_f) / 100.0)
          total_done += (issue.story_points.to_f * ratio.to_f / 100.0)
        end
      end
      [total_left, cumulative_left, total_done]
    end

    def use_subissue_done_ratio
      !Setting.respond_to?(:parent_issue_done_ratio) || Setting.parent_issue_done_ratio == 'derived' || Setting.parent_issue_done_ratio.nil?
    end

    private

    def scope_by_created_date
      @data_scope.
        where("#{Issue.table_name}.created_on >= ?", @date_from).
        where("#{Issue.table_name}.created_on < ?", @date_to.to_date + 1).
        where("#{Issue.table_name}.created_on IS NOT NULL").
        group("#{Issue.table_name}.created_on").
        count
    end

    def scope_by_closed_date
      @data_scope.
        open(false).
        where("#{Issue.table_name}.closed_on >= ?", @date_from).
        where("#{Issue.table_name}.closed_on < ?", @date_to.to_date + 1).
        where("#{Issue.table_name}.closed_on IS NOT NULL").
        group("#{Issue.table_name}.closed_on").
        count
    end

    # options
    # color    - Line color in RGB format (e.g '255,255,255') (random)
    # fill     - Fille background under line (false)
    # dashed   - Draw dached line (solid)
    # nopoints - Doesn't show points on line (false)

    def dataset(dataset_data, label, options = {})
      color = options[:color] || [rand(255), rand(255), rand(255)].join(',')
      dataset_color = "rgba(#{color}, 1)"
      {
        :type => (options[:type] || 'line'),
        :data => dataset_data,
        :label => label,
        :fill => (options[:fill] || false),
        :backgroundColor => "rgba(#{color}, 0.2)",
        :borderColor => dataset_color,
        :borderDash => (options[:dashed] ? [5, 5] : []),
        :borderWidth => (options[:dashed] ? 1.5 : 2),
        :pointRadius => (options[:nopoints] ? 0 : 3),
        :pointBackgroundColor => dataset_color
      }
    end

    def chart_periods
      raise "Dates can't be blank" if [@date_to, @date_from].any?(&:blank?)
      period_count = (@date_to.to_date + 1 - @date_from.to_date).to_i
      scale_division = period_count > 31 ? period_count / 31.0 : 1

      [(period_count / scale_division).round, scale_division]
    end

    def issues_count_by_period(issues_scope)
      data = [0] * @period_count
      issues_scope.each do |c|
        next if c.first.localtime.to_date > @date_to.to_date
        period_num = ((@date_to.to_date - c.first.localtime.to_date).to_i / @scale_division).to_i
        data[period_num] += c.last unless data[period_num].blank?
      end
      data.reverse
    end

    def issues_avg_count_by_period(issues_scope)
      count_by_date = {}
      issues_scope.each {|x, y| count_by_date[x.localtime.to_date] = count_by_date[x.localtime.to_date].to_i + y }
      data = [0] * @period_count
      count_by_date.each do |x, y|
        next if x.to_date > @date_to.to_date
        period_num = ((@date_to.to_date - x.to_date).to_i / @scale_division).to_i
        if data[period_num]
          data[period_num] = y unless data[period_num].to_i > 0
          data[period_num] = (data[period_num] + y) / 2.0
        end
      end
      data.reverse
    end

    def chart_fields_by_period
      chart_dates_by_period.map do |d|
        if @scale_division >= 365
          d.year
        elsif @scale_division >= 13
          month_abbr_name(d.at_beginning_of_week.to_time.month) + ' ' + d.at_beginning_of_week.to_time.year.to_s
        elsif @scale_division >= 7
          d.at_beginning_of_week.to_time.day.to_s + ' ' + month_name(d.at_beginning_of_week.to_time.month)
        else
          d.to_time.day.to_s + ' ' + month_name(d.to_time.month)
        end
      end
    end

    def weekend_periods
      periods = []
      @period_count.times do |m|
        period_date = ((@date_to.to_date - 1 - m * @scale_division) + 1)
        periods << @period_count - m - 1 if non_working_week_days.include?(period_date.cwday)
      end
      periods.compact
    end

    def chart_data_pairs(chart_data)
      chart_data.inject([]) { |accum, value| accum << value }
      data_pairs = []
      for i in 0..chart_data.count - 1
        data_pairs << [chart_dates_by_period[i], chart_data[i]]
      end
      data_pairs
    end

    def chart_dates_by_period
      @chart_dates_by_period ||= @period_count.times.inject([]) do |accum, m|
        period_date = ((@date_to.to_date - 1 - m * @scale_division) + 1)
        accum << if m == 0 || m == @period_count - 1
                   period_date.to_date
                 elsif @scale_division >= 13
                   period_date.at_beginning_of_week.to_date
                 elsif @scale_division >= 7
                   period_date.at_beginning_of_week.to_date
                 else
                   period_date.to_date
                 end
      end.reverse
    end

    def month_abbr_name(month)
      l('date.abbr_month_names')[month]
    end

    def trendline(y_values)
      size = y_values.size
      x_values = (1..size).to_a
      sum_x = 0
      sum_y = 0
      sum_xx = 0
      sum_xy = 0
      y_values.zip(x_values).each do |y, x|
        sum_xy += x * y
        sum_xx += x * x
        sum_x  += x
        sum_y  += y
      end

      slope = 1.0 * ((size * sum_xy) - (sum_x * sum_y)) / ((size * sum_xx) - (sum_x * sum_x))
      intercept = 1.0 * (sum_y - (slope * sum_x)) / size

      line_values = x_values.map { |x| predict(x, slope, intercept) }
      line_values.select { |val| val >= 0 }
    end

    def predict(x, slope, intercept)
      slope * x + intercept
    end
  end
end
