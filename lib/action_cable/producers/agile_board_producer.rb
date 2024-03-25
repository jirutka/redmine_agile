# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2024 RedmineUP
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
        def card_moved(actor, options)
          return unless options[:issue].present?

          channel = options[:channel]
          channel = ActionCable::Channels::AgileChannel::BASE_CHANNEL_NAME + ':' + channel if Rails::VERSION::STRING < '6.0'
          issue = options[:issue]
          query = options[:query]
          from_id = options[:from_id]
          to_id = issue.status_id
          issue.agile_data.reload if issue.agile_data.persisted?

          message = {
            type: "issueMoved",
            actor_id: actor,
            issue_id: issue.id,
            to: {
              status_id: to_id,
              position: issue.agile_data.position,
              issues_count: query.issue_count_by_status[to_id].to_i,
              points_label: status_label(query.issue_count_by_estimated_hours[to_id].to_f, query.issue_count_by_story_points[to_id].to_i)
            },
            from: {
              status_id: from_id,
              issues_count: query.issue_count_by_status[from_id].to_i,
              points_label: status_label(query.issue_count_by_estimated_hours[from_id].to_f, query.issue_count_by_story_points[from_id].to_i)
            }
          }

          Channels::AgileChannel.rcrm_broadcast_to(RedmineAgile::CABLE_CONNECTION, channel, message)
        end


        private

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
