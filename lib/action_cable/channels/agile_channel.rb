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
  module Channels
    class AgileChannel < ActionCable::Channel::Base
      BASE_CHANNEL_NAME = "action_cable:channels:agile"

      def subscribed
        return reject unless RedmineAgile.cable_enabled?
        return subscribe_to_board_stream if params[:chat_id].match(/board/)

        reject
      end

      private

      def subscribe_to_board_stream
        project = Project.find_by(id: params[:chat_id].split('board-').last)
        return reject if !current_user || !current_user.allowed_to?(:view_issues, project, global: true)

        stream_from "#{BASE_CHANNEL_NAME}:#{params[:chat_id]}"
      end
    end
  end
end
