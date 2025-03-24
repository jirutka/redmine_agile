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
  module Server
    class RupConfiguration < ActionCable::Server::Configuration

      def initialize(connection_klass: 'ActionCable::Connection::Base')
        super()

        @connection_class = -> { connection_klass.constantize }
        @logger ||= ::Rails.logger
        @disable_request_forgery_protection = true
      end

      def cable
        @cable ||= { 'adapter' => detect_adapter_type }.with_indifferent_access
      end

      private

      def detect_adapter_type
        ActionCable.server.config.cable ? (ActionCable.server.config.cable.fetch('adapter') { 'async' }) : 'async'
      end
    end
  end
end
