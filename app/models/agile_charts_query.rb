# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
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

class AgileChartsQuery < AgileQuery
  unloadable

  validate :validate_query_dates

  attr_writer :date_from, :date_to

  def initialize(attributes = nil, *args)
    super attributes
    self.filters.delete('status_id')
    self.filters['chart_period'] = { operator: 'm', values: [''] } unless has_filter?('chart_period')
  end

  self.operators_by_filter_type[:chart_period] = ['><', 'w', 'lw', 'l2w', 'm', 'lm', 'y']

  def initialize_available_filters
    super

    add_available_filter 'chart_period', type: :date_past, name: l(:label_date)
  end

  def sprint_values
    AgileSprint.for_project(project).available.map { |s| [s.to_s, s.id.to_s] }
  end

  def default_columns_names
    @default_columns_names = [:id, :subject, :estimated_hours, :spent_hours, :done_ratio, :assigned_to]
  end

  def sql_for_chart_period_field(_field, _operator, _value)
    '1=1'
  end

  def chart
    @chart ||= RedmineAgile::Charts.valid_chart_name_by(options[:chart])
  end

  def chart=(arg)
    options[:chart] = arg
  end

  def date_from
    @date_from ||= chart_period[:from]
  end

  def date_to
    @date_to ||= chart_period[:to]
  end

  def interval_size
    if RedmineAgile::AgileChart::TIME_INTERVALS.include?(options[:interval_size])
      options[:interval_size]
    else
      RedmineAgile::AgileChart::DAY_INTERVAL
    end
  end

  def interval_size=(value)
    options[:interval_size] = value
  end

  def build_from_params(params)
    if params[:fields] || params[:f]
      self.filters = {}.merge(chart_period_filter(params))
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    self.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    self.date_from = params[:date_from] || (params[:query] && params[:query][:date_from])
    self.date_to = params[:date_to] || (params[:query] && params[:query][:date_to])
    self.chart = params[:chart] || (params[:query] && params[:query][:chart]) || params[:default_chart] || RedmineAgile.default_chart
    self.interval_size = params[:interval_size] || (params[:query] && params[:query][:interval_size]) || RedmineAgile::AgileChart::DAY_INTERVAL
    self.chart_unit = params[:chart_unit] || (params[:query] && params[:query][:chart_unit]) || RedmineAgile::Charts::UNIT_ISSUES

    self
  end

  private

  def chart_period_filter(params)
    return {} if (params[:fields] || params[:f]).include?('chart_period')
    { 'chart_period' => { operator: 'm', values: [''] } }
  end

  def validate_query_dates
    if (self.date_from && self.date_to && self.date_from >= self.date_to)
      errors.add(:base, l(:label_agile_chart_dates) + ' ' + l(:invalid, scope: 'activerecord.errors.messages'))
    end
  end

  def db_timestamp_regex
    /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:.\d*))/
  end

  def chart_period
    @chart_period ||= {
      from: chart_period_statement.match("chart_period > '#{db_timestamp_regex}") { |m| Time.zone.parse(m[1]) },
      to: chart_period_statement.match("chart_period <= '#{db_timestamp_regex}") { |m| Time.zone.parse(m[1]) }
    }
  end

  def chart_period_statement
    @chart_period_statement ||= build_chart_period_statement
  end

  def build_chart_period_statement
    field = 'chart_period'
    operator = filters[field][:operator]
    values = filters[field][:values]
    date = User.current.today

    case operator
    when 'w'
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = date.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql_for_field(field, '><t-', [days_ago], Issue.table_name, field)
    when 'm'
      days_ago = date - date.beginning_of_month
      sql_for_field(field, '><t-', [days_ago], Issue.table_name, field)
    when 'y'
      days_ago = date - date.beginning_of_year
      sql_for_field(field, '><t-', [days_ago], Issue.table_name, field)
    else
      sql_for_field(field, operator, values, Issue.table_name, field)
    end
  end
end
