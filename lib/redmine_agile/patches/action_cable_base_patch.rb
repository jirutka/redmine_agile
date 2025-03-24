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
    module ActionCableBasePatch
      def self.included(base)
        base.send(:extend, ClassMethods)
        delegate :rup_broadcast_to, to: :class
      end

      module ClassMethods
        def rup_broadcast_to(klass, model, message)
          ActionCable.rup_server(klass).broadcast(broadcasting_for(model), message)
        end
      end
    end
  end
end

unless ActionCable::Channel::Base.included_modules.include?(RedmineAgile::Patches::ActionCableBasePatch)
  ActionCable::Channel::Base.send(:include, RedmineAgile::Patches::ActionCableBasePatch)
end
