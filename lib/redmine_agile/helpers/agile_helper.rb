# encoding: utf-8
#
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

module RedmineAgile
  module AgileHelper

    def retrieve_agile_query
      if !params[:query_id].blank?
        cond = "project_id IS NULL"
        cond << " OR project_id = #{@project.id}" if @project
        @query = AgileQuery.where(cond).find(params[:query_id])
        raise ::Unauthorized unless @query.visible?
        @query.project = @project
        session[:agile_query] = {:id => @query.id, :project_id => @query.project_id}
        sort_clear
      elsif api_request? || params[:set_filter] || session[:agile_query].nil? || session[:agile_query][:project_id] != (@project ? @project.id : nil)
        unless @query
          @query = AgileQuery.new(:name => "_")
          @query.project = @project if @project
          @query.build_from_params(params)
        end
        session[:agile_query] = {:project_id => @query.project_id,
                                 :filters => @query.filters,
                                 :group_by => @query.group_by,
                                 :color_base => (@query.respond_to?(:color_base) && @query.color_base),
                                 :column_names => @query.column_names}
      else
        # retrieve from session
        @query = nil
        @query ||= AgileQuery.find_by_id(session[:agile_query][:id]) if session[:agile_query][:id]
        @query ||= AgileQuery.new(:name => "_",
                                  :filters => session[:agile_query][:filters],
                                  :group_by => session[:agile_query][:group_by],
                                  :color_base => session[:agile_query][:color_base],
                                  :column_names => session[:agile_query][:column_names])
        @query.project = @project
      end
    end

    def retrieve_versions_query
      @query = AgileVersionsQuery.new
      @query.project = @project if @project
    end

    def options_charts_for_select(selected, options={})
      options_for_select([[l(:label_agile_charts_issues_burndown), "issues_burndown"],
        [l(:label_agile_charts_work_burndown), "work_burndown"],
        nil].compact,
        selected)
    end

    def render_agile_chart(chart_name, issues_scope)
      render :partial => "agile_charts/chart", :locals => {:chart => chart_name, :issues_scope => issues_scope}
    end

  end
end

ActionView::Base.send :include, RedmineAgile::AgileHelper
