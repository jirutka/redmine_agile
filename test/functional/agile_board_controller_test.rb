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
    assert_equal [@subissue.id, child2.id], assigns[:issues].map(&:id)
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

  def test_get_index_with_all_fields
    get :index, agile_query_params.merge({:f => AgileQuery.available_columns.map(&:name)})
    assert_response :success
    assert_template :index
  end

  private

  def agile_query_params
    {:set_filter => "1", :f => ["status_id", ""], :op => {:status_id => "o"}, :c => ["tracker", "assigned_to"],  :project_id => "ecookbook"}
  end

end
