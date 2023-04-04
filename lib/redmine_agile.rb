# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
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

require 'douglas_peucker'

require 'redmine_agile/hooks/views_layouts_hook'
require 'redmine_agile/hooks/views_issues_hook'
require 'redmine_agile/hooks/views_versions_hook'
require 'redmine_agile/patches/issue_patch'

require 'redmine_agile/patches/compatibility_patch'

require 'redmine_agile/helpers/agile_helper'

require 'redmine_agile/charts/agile_chart'
require 'redmine_agile/charts/burndown_chart'
require 'redmine_agile/charts/work_burndown_chart'


module RedmineAgile

  ISSUES_PER_COLUMN = 10
  TIME_REPORTS_ITEMS = 1000
  BOARD_ITEMS = 500

  class << self
    def time_reports_items_limit
      by_settigns = Setting.plugin_redmine_agile['time_reports_items_limit'].to_i
      by_settigns > 0 ? by_settigns : TIME_REPORTS_ITEMS
    end

    def board_items_limit
      by_settigns = Setting.plugin_redmine_agile['board_items_limit'].to_i
      by_settigns > 0 ? by_settigns : BOARD_ITEMS
    end

    def issues_per_column
      by_settigns = Setting.plugin_redmine_agile['issues_per_column'].to_i
      by_settigns > 0 ? by_settigns : ISSUES_PER_COLUMN
    end

    def default_columns
      Setting.plugin_redmine_agile['default_columns'].to_a
    end

    def default_chart
      Setting.plugin_redmine_agile['default_chart'] || "issues_burndown"
    end

    def use_colors?
      false
          end

    def color_base
      "none"
          end

    def minimize_closed?
      Setting.plugin_redmine_agile['minimize_closed'].to_i > 0
    end

    def exclude_weekends?
      Setting.plugin_redmine_agile['exclude_weekends'].to_i > 0
    end

    def status_colors?
      false
          end

    def hide_closed_issues_data?
      Setting.plugin_redmine_agile['hide_closed_issues_data'].to_i > 0
    end

  end


end
