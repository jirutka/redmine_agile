# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2018 RedmineUP
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
        base.extend(ClassMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
        end
      end

      module ClassMethods
        def before_action(*filters, &block)
          before_filter(*filters, &block)
        end
      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedmineAgile::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineAgile::Patches::ApplicationControllerPatch)
end
