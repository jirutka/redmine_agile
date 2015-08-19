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

require File.expand_path('../../test_helper', __FILE__)

class AgileBoardsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries
  fixtures :email_addresses if Redmine::VERSION.to_s > '3.0'

  def setup
    @project_1 = Project.find(1)
    @project_2 = Project.find(5)
    EnabledModule.create(:project => @project_1, :name => 'agile')
    EnabledModule.create(:project => @project_2, :name => 'agile')
    @request.session[:user_id] = 1
  end

  def test_get_index
    get :index
    assert_response :success
    assert_template :index
  end

  def test_get_index_with_project
    get :index, :project_id => "ecookbook"
    assert_response :success
    assert_template :index
  end

  def test_get_index_truncated
    with_agile_settings "board_items_limit" => 1 do
      get :index, agile_query_params
      assert_response :success
      assert_template :index
      assert_select 'div#content p.warning', 1
      assert_select 'td.issue-status-col .issue-card', 1
    end
  end

  def test_get_index_with_filters
    get :index, agile_query_params.merge({:op => {:status_id => "!"}, :v => {:status_id => ["1"]}})
    assert_response :success
    assert_template :index
  end

  def create_subissue
    @issue1 = Issue.find(1)
    @subissue = Issue.create!(
      :subject         => 'Sub issue',
      :project         => @issue1.project,
      :tracker         => @issue1.tracker,
      :author          => @issue1.author,
      :parent_issue_id => @issue1.id,
      :fixed_version   => Version.last
    )
  end

  def test_get_index_with_filter_on_parent_tracker
    create_subissue
    get :index, agile_query_params.merge({
      :op => {:parent_issue_tracker_id => '='},
      :v => {:parent_issue_tracker_id => [ Tracker.find(1).name ]},
      :f => [:parent_issue_tracker_id],
      :project_id => Project.order(:id).first.id
    })
    assert_response :success
    assert_template :index
    assert_equal [@subissue.id], assigns[:issues].map(&:id)
  end if Redmine::VERSION.to_s > '2.4'

  def test_get_index_with_filter_on_two_parent_id
    create_subissue
    issue2 = Issue.generate!
    child2 =  issue2.generate_child!

    get :index, agile_query_params.merge({
      :op => {:parent_issue_id => '='},
      :v => {:parent_issue_id => [ "#{@issue1.id}, #{issue2.id}" ]},
      :f => [:parent_issue_id],
      :project_id => Project.order(:id).first.id
    })
    assert_response :success
    assert_template :index
    assert_equal [@subissue.id, child2.id].sort, assigns[:issues].map(&:id).sort
  end if Redmine::VERSION.to_s > '2.4'



  def test_get_index_with_filter_on_parent_tracker_inversed
    create_subissue
    get :index, agile_query_params.merge({
      :op => {:parent_issue_tracker_id => '!'},
      :v => {:parent_issue_tracker_id => [ Tracker.find(1).name ]},
      :f => [:parent_issue_tracker_id],
      :project_id => Project.order(:id).first.id
    })
    assert_response :success
    assert_template :index
    assert_not_include @subissue.id, assigns[:issues].map(&:id)
  end if Redmine::VERSION.to_s > '2.4'

  def test_get_index_with_filter_on_has_subissues
    create_subissue
    get :index, agile_query_params.merge({
      :op => {:has_sub_issues => '='},
      :v => {:has_sub_issues => [ 'yes' ]},
      :f => [:has_sub_issues],
      :project_id => Project.order(:id).first.id
    })
    assert_response :success
    assert_template :index
    assert_equal [@issue1.id], assigns[:issues].map(&:id)
  end if Redmine::VERSION.to_s > '2.4'

  def test_get_index_with_filter_and_field_time_in_state
    create_subissue
    columns_group_by = AgileQuery.new.groupable_columns
    columns_group_by.each do |col|
      get :index, agile_query_params.merge({
        :project_id => Project.order(:id).first.id,
        :group_by => col.name.to_s
        })
      assert_response :success, "Error with group by #{col.name}"
      assert_template :index
    end
  end if Redmine::VERSION.to_s > '2.4'

  def test_put_update_status
    status_id = 1
    first_issue_id = 1
    second_issue_id = 3
    first_pos = 1
    second_pos = 2
    positions = { first_issue_id.to_s => { 'position' => first_pos }, second_issue_id.to_s => { 'position' => second_pos } }
    xhr :put, :update, :id => first_issue_id, :issue => { :status_id => status_id }, :positions => positions
    assert_response :success
    assert_equal status_id, Issue.find(first_issue_id).status_id
    assert_equal first_pos, Issue.find(first_issue_id).agile_rank.position
    assert_equal second_pos, Issue.find(second_issue_id).agile_rank.position
  end

  def test_put_update_version
    fixed_version_id = 3
    first_issue_id = 1
    second_issue_id = 3
    first_pos = 1
    second_pos = 2
    positions = { first_issue_id.to_s => { 'position' => first_pos }, second_issue_id.to_s => { 'position' => second_pos } }
    xhr :put, :update, :id => first_issue_id, :issue => { :fixed_version_id => fixed_version_id }, :positions => positions
    assert_response :success
    assert_equal fixed_version_id, Issue.find(first_issue_id).fixed_version_id
    assert_equal first_pos, Issue.find(first_issue_id).agile_rank.position
    assert_equal second_pos, Issue.find(second_issue_id).agile_rank.position
  end

  def test_put_update_assigned
    assigned_to_id = 3
    issue_id = 1
    xhr :put, :update, :id => issue_id, :issue => {:assigned_to_id => assigned_to_id}
    assert_response :success
    assert_equal assigned_to_id, Issue.find(issue_id).assigned_to_id
  end

  def test_get_index_with_all_fields
    get :index, agile_query_params.merge({:f => AgileQuery.available_columns.map(&:name)})
    assert_response :success
    assert_template :index
  end

  def test_short_card_for_closed_issue
    with_agile_settings "hide_closed_issues_data" => "1" do
      closed_issues = Issue.where(:status_id => IssueStatus.where(:is_closed => true))
      project = closed_issues.first.project
      get :index, agile_query_params.merge("f"=>[""])
      assert_response :success
      assert_template :index
      assert_select '.closed-issue', project.issues.where(:status_id => IssueStatus.where(:is_closed => true)).count
    end
  end

  def test_get_tooltip_for_issue
    issue = Issue.where(:status_id => IssueStatus.where(:is_closed => true)).first
    get :issue_tooltip, :id => issue.id
    assert_response :success
    assert_template "agile_boards/_issue_tooltip"
    assert_select 'a.issue', 1
    assert_select 'strong', 6
    assert_match issue.status.name, @response.body
  end

  def test_empty_node_for_tooltip
    with_agile_settings "hide_closed_issues_data" => "1" do
      closed_issues = Issue.where(:status_id => IssueStatus.where(:is_closed => true))
      project = closed_issues.first.project
      get :index, agile_query_params.merge("f"=>[""])
      assert_select "span.tip", {:text => ""}
    end
  end

  def test_setting_for_closed_issues
    with_agile_settings "hide_closed_issues_data" => "0" do
      closed_issues = Issue.where(:status_id => IssueStatus.where(:is_closed => true))
      project = closed_issues.first.project
      get :index, agile_query_params.merge("f"=>[""])
      assert_response :success
      assert_template :index
      assert_select '.closed-issue', 0
    end
  end

  def test_index_with_js_format
    with_agile_settings "hide_closed_issues_data" => "1" do
      closed_issues = Issue.where(:status_id => IssueStatus.where(:is_closed => true))
      project = closed_issues.first.project
      xhr :get, :index, agile_query_params.merge("f"=>[""], :format => :js)
      assert_response :success
      assert_match "$('.tooltip').mouseenter(getToolTipInfo)", @response.body
    end
  end

  def test_get_index_with_day_in_state_and_parent_group
    get :index, agile_query_params.merge(:c => ["day_in_state"], :group_by => "parent")
    assert_response :success
    assert_template :index
  end

  private

  def agile_query_params
    {:set_filter => "1", :f => ["status_id", ""], :op => {:status_id => "o"}, :c => ["tracker", "assigned_to"],  :project_id => "ecookbook"}
  end

end
