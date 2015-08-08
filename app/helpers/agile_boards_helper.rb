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

module AgileBoardsHelper
  def agile_color_class(issue, options={})
    ''
      end

  def header_th(name, rowspan = 1, colspan = 1, leaf = nil)
    th_attributes = {}
    if leaf
      th_attributes[:"data-column-id"] = leaf.id
      issue_count = leaf.instance_variable_get("@issue_count")
      count_tag = " (#{content_tag(:span, issue_count.to_i, :class => 'count')})".html_safe
    end
    content_tag :th, h(name) + count_tag, th_attributes
  end

  def render_board_headers(columns)
    "<tr>#{columns.map{|column| header_th(column.name, 1, 1, column)}.join}</tr>".html_safe
      end

  def color_by_name(name)
    "##{"%06x" % (name.unpack('H*').first.hex % 0xffffff)}"
  end

  def render_board_fields_selection(query)
    query.available_inline_columns.reject(&:frozen?).map do |column|
      label_tag('', check_box_tag('c[]', column.name, query.columns.include?(column)) + column.caption, :class => "floating" )
    end.join(" ").html_safe
  end

  def render_issue_card_hours(query, issue)
    hours = []
    hours << "%.2f" % issue.total_spent_hours.to_f if query.has_column_name?(:spent_hours) && issue.total_spent_hours > 0
    hours << "%.2f" % issue.estimated_hours.to_f if query.has_column_name?(:estimated_hours) && issue.estimated_hours
    content_tag(:span, "(#{hours.join('/')}h)", :class => 'hours') unless hours.blank?
  end

  def agile_progress_bar(pcts, options={})
    pcts = [pcts, pcts] unless pcts.is_a?(Array)
    pcts = pcts.collect(&:round)
    pcts[1] = pcts[1] - pcts[0]
    pcts << (100 - pcts[1] - pcts[0])
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed') : ''.html_safe) +
        (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done') : ''.html_safe) +
        (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo') : ''.html_safe) +
        (legend ? content_tag('td', content_tag('p', legend, :class => 'percent'), :class => 'legend') : ''.html_safe)
      ), :class => "progress progress-#{pcts[0]}", :style => "width: #{width};").html_safe
  end

  def issue_children(issue)
    return unless issue.children.any?
    content_tag :ul do
      issue.children.select{ |x| x.visible? }.each do |child|
        id = if @query.has_column_name?(:tracker) || @query.has_column_name?(:id) then "##{child.id}:&nbsp;" else '' end
        concat "<li class='#{'task-closed' if child.closed?}'><a href='#{issue_path(child)}'>#{id}#{child.subject}</a></li>#{issue_children(child)}".html_safe
      end
    end
  end

  def time_in_state(distance=nil)
    return "" if !distance || !(distance.is_a? Time)
    distance = Time.now - distance
    hours = distance/(3600)
    return "#{I18n.t('datetime.distance_in_words.x_hours', :count => hours.to_i)}" if hours < 24
    "#{I18n.t('datetime.distance_in_words.x_days', :count => (hours/24).to_i)}"
  end

end
