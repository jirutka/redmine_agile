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

class AgileBoardsController < ApplicationController
  unloadable

  menu_item :agile

  before_filter :find_issue, :only => [:update, :issue_tooltip]
  before_filter :find_optional_project, :only => [:index]

  helper :issues
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include RedmineAgile::AgileHelper

  def index
    retrieve_agile_query

    if @query.valid?
      @issues = @query.issues
      @issue_board = @query.issue_board
      @board_columns = @query.board_statuses
      
      if @query.has_column_name?(:day_in_state)
        @journals_for_state = Journal.joins(:details).where(
          :journals => {
            :journalized_id => @issues.map{|issue| (issue.id rescue nil)}, 
            :journalized_type => "Issue"
          }, 
          :journal_details => {:prop_key => 'status_id'}).order("created_on DESC") 
      end

      respond_to do |format|
        format.html { render :template => 'agile_boards/index', :layout => !request.xhr? }
        format.js
      end
    else
      respond_to do |format|
        format.html { render(:template => 'agile_boards/index', :layout => !request.xhr?) }
        format.js
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update
    (render_403; return false) unless @issue.editable?
    retrieve_agile_query_from_session
    @issue.init_journal(User.current)
    @issue.safe_attributes = params[:issue]
    saved = params[:issue] && params[:issue].inject(true) do |total, attribute|
       total &&= @issue.attributes[attribute.first].to_i == attribute.last.to_i
    end
    call_hook(:controller_agile_boards_update_before_save, { :params => params, :issue => @issue})
    @update = true
    if saved && @issue.save
      call_hook(:controller_agile_boards_update_after_save, { :params => params, :issue => @issue})
      AgileRank.transaction do
        Issue.eager_load(:agile_rank).find(params[:positions].keys).each do |issue|
          issue.agile_rank.position = params[:positions][issue.id.to_s]['position']
          issue.agile_rank.save
        end
      end if params[:positions]
      respond_to do |format|
        format.html { render(:partial => 'issue_card', :locals => {:issue => @issue}, :status => :ok, :layout => nil) }
      end
    else
      respond_to do |format|
        messages = @issue.errors.full_messages
        messages = [l(:text_agile_move_not_possible)] if messages.empty?
        format.html { render :json => messages, :status => :fail, :layout => nil }
      end
    end
  end

  def issue_tooltip
    render :partial => 'issue_tooltip'
  end

end
