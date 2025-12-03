# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2025 RedmineUP
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
  module Patches
    module ApplicationControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          helper :agile_boards
          include AgileBoardsHelper
          include RedmineAgile::Helpers::AgileHelper
          include ActionView::Helpers::AssetTagHelper
          include ERB::Util
        end
      end

      module InstanceMethods
        def web_socket_service_update(params, issue, options)
          return if !RedmineAgile.cable_available? || !RedmineAgile.cable_enabled? || options[:query].nil?

          query = options[:query]
          project = options[:project]
          changes = issue.previous_changes.except(:lock_version, :updated_on).keys

          if changes.include?('status_id') || (issue.notes.blank? && changes.empty?)
            from_id = issue.previous_changes['status_id']&.first || issue.status_id
            ActionCable::Producers::AgileBoardProducer.card_moved(
              params[:actor],
              { channel: "board-#{project.try(:id)}",
              avatar: avatar(User.current, size: 30, d: '1'), params: params, issue: issue, query: query, from_id: from_id }
            )
          else
            html = render_to_string(partial: 'agile_boards/issue_card', locals: { issue: issue }, layout: nil)
            ActionCable::Producers::AgileBoardProducer.card_updated(
              params[:actor],
              { channel: "board-#{project.try(:id)}",
              avatar: avatar(User.current, size: 30), params: params, issue: issue, query: query, html: html }
            )
          end
        end

        def web_socket_service_create(params, issue, options)
          return if !RedmineAgile.cable_available? || !RedmineAgile.cable_enabled?

          query = options[:query]
          project = options[:project]
          html = render_to_string(partial: 'agile_boards/issue_card', locals: {issue: issue}, layout: nil)

          ActionCable::Producers::AgileBoardProducer.card_created(
            params[:actor],
            { channel: "board-#{project.try(:id)}",
            avatar: avatar(User.current, size: 30), params: params, issue: issue, query: query, html: html }
          )
        end


        def web_socket_service_destroy(params, issue, options)
          return if !RedmineAgile.cable_available? || !RedmineAgile.cable_enabled?

          query = options[:query]
          project = options[:project]
          html = render_to_string(partial: 'agile_boards/issue_card', locals: {issue: issue}, layout: nil)

          ActionCable::Producers::AgileBoardProducer.card_deleted(
            params[:actor],
            { channel: "board-#{project.try(:id)}",
            avatar: avatar(User.current, size: 30), params: params, issue: issue, query: query, html: html }
          )
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedmineAgile::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineAgile::Patches::ApplicationControllerPatch)
end
