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

module ActionCable
  module Producers
    class AgileBoardProducer
      class << self
        require 'ostruct'

        include ActionView::Helpers::SanitizeHelper

        def card_moved(actor, options)
          return unless options[:issue].present?

          opts = options_object(options)
          from_id = options[:from_id]
          to_id = opts.issue.status_id

          message = {
            type: "issueMoved",
            actor_id: actor,
            avatar: opts.avatar,
            issue_id: opts.issue.id,
            swimlane_id: get_swimlane_id(opts),
            to: {
              status_id: to_id,
              position: opts.issue.agile_data.position,
              issues_count: opts.query.issue_count_by_status[to_id].to_i,
              points_label: status_label(opts.query.issue_count_by_estimated_hours[to_id].to_f, opts.query.issue_count_by_story_points[to_id].to_i)
            },
            from: {
              status_id: from_id,
              issues_count: opts.query.issue_count_by_status[from_id].to_i,
              points_label: status_label(opts.query.issue_count_by_estimated_hours[from_id].to_f, opts.query.issue_count_by_story_points[from_id].to_i)
            }
          }

          Channels::AgileChannel.rup_broadcast_to(RedmineAgile::CABLE_CONNECTION, opts.channel, message)
        end

        def card_updated(actor, options)
          return unless options[:issue].present?

          opts = options_object(options)
          html = options[:html]

          message = {
            type: "issueUpdated",
            actor_id: actor,
            avatar: opts.avatar,
            issue_id: opts.issue.id,
            swimlane_id: get_swimlane_id(opts),
            html: html.html_safe
          }

          Channels::AgileChannel.rup_broadcast_to(RedmineAgile::CABLE_CONNECTION, opts.channel, message)
        end

        def card_created(actor, options)
          return unless options[:issue].present?

          opts = options_object(options)
          html = options[:html]

          message = {
            type: "issueCreated",
            actor_id: actor,
            avatar: opts.avatar,
            status_id: opts.issue.status_id,
            swimlane_id: get_swimlane_id(opts),
            html: html.html_safe
          }

          Channels::AgileChannel.rup_broadcast_to(RedmineAgile::CABLE_CONNECTION, opts.channel, message)
        end

        def card_deleted(actor, options)
          return unless options[:issue].present?

          opts = options_object(options)

          message = {
            type: "issueDeleted",
            actor_id: actor,
            avatar: opts.avatar,
            status_id: opts.issue.status_id,
            swimlane_id: get_swimlane_id(opts),
            issue_id: opts.issue.id
          }

          Channels::AgileChannel.rup_broadcast_to(RedmineAgile::CABLE_CONNECTION, opts.channel, message)
        end


        private

        def options_object(options)
          ostruct =
          ::OpenStruct.new(
            channel: options[:channel],
            params: options[:params],
            issue: options[:issue],
            query: options[:query],
            avatar: options[:avatar]
          )

          ostruct[:channel] = ActionCable::Channels::AgileChannel::BASE_CHANNEL_NAME + ':' + options[:channel] if Rails::VERSION::STRING < '6.0'
          ostruct.issue.agile_data.reload if ostruct.issue.agile_data.persisted?
          ostruct
        end

        def get_swimlane_id(options)
          return nil unless options.query&.group_by&.present?

          options.issue.public_send(options.query.group_by + '_id')
        end

        def status_label(hours, sp)
          values  = []
          values <<  '%.2fh' % hours.to_f if hours > 0
          values << "#{sp}sp" if sp > 0
          values.join('/') if values.any?
        end
      end
    end
  end
end
