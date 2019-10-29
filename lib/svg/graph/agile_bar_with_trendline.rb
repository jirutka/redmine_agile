# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2017 RedmineUP
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

require 'SVG/Graph/Bar'

module SVG
  module Graph
    class AgileBarWithTrendline < Bar
      def draw_data
        minvalue = min_value
        fieldwidth = field_width

        unit_size = (@graph_height.to_f - font_size * 2 * top_font) / (get_y_labels.max - get_y_labels.min)
        bargap = bar_gap ? (fieldwidth < 10 ? fieldwidth / 2 : 10) : 0

        bar_width = fieldwidth - bargap
        bar_width /= @data.length if stack == :side
        x_mod = (@graph_width - bargap) / 2 - (stack == :side ? bar_width / 2 : 0)

        bottom = @graph_height

        field_count = 0
        @config[:fields].each_index do |i|
          dataset_count = 0
          for dataset in @data
            value = dataset[:data][i]
            left = fieldwidth * field_count
            length = (value.abs - (minvalue > 0 ? minvalue : 0)) * unit_size
            # top is 0 if value is negative
            top = bottom - (((value < 0 ? 0 : value) - minvalue) * unit_size)
            left += bar_width * dataset_count if stack == :side

            @graph.add_element('rect', { 'x' => left.to_s,
                                         'y' => top.to_s,
                                         'width' => bar_width.to_s,
                                         'height' => length.to_s,
                                         'class' => "fill#{dataset_count + 1}" })

            make_datapoint_text(left + bar_width/2.0, top - 6, value.to_s)
            dataset_count += 1
          end
          field_count += 1
        end

        dataset_count = 0
        @data.each do |dataset|
          x_points, y_points = trendline_data(dataset[:data])
          x_step = @graph_width.to_f / (x_points.count - 1)

          lpath = 'L'
          x_start = 0
          y_start = 0

          x_points.each_index do |idx|
            x = idx.zero? ? 0 : x_step * x_points[idx - 1] + fieldwidth
            y = @graph_height - y_points[idx] * unit_size
            x_start, y_start = x, y if idx == 0
            lpath << "#{x} #{y > @graph_height ? @graph_height : y} "
          end
          @graph.add_element('path', { 'd' => "M#{x_start} #{y_start} #{lpath}", 'class' => "trendline#{dataset_count + 1}" })
          dataset_count +=1
        end
      end

      def trendline_data(y_values)
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

        [0.upto(size - 1).map { |y| y }, x_values.map { |x| predict(x, slope, intercept) }]
      end

      def predict(x, slope, intercept)
        slope * x + intercept
      end
    end
  end
end
