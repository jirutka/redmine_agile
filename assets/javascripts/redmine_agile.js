(function() {
  var AgileBoard = function() {};
  var PlanningBoard = function() {};

  PlanningBoard.prototype = {

    init: function(routes) {
      var self = this;
      self.routes = routes;

      $(function() {
        self.initSortable();
      });
    },

    successSortable: function($oldColumn, $column) {
      var r = new RegExp(/\d+/)
      var ids = [];

      ids.push({
        column: $column,
        id: $column.data('id'),
        to: true
      });
      ids.push({
        column: $oldColumn,
        id: $oldColumn.data('id'),
        from: true
      });

      for (var i = 0; i < ids.length; i++) {
        var current = ids[i];
        var headerSelector = '.version-planning-board thead tr th[data-column-id="' + current.id + '"]';
        var $columnHeader = $(headerSelector);
        var columnText = $columnHeader.text();
        var currentIssuesAmount = ~~columnText.match(r);
        currentIssuesAmount = (current.from) ? currentIssuesAmount - 1 : currentIssuesAmount + 1;
        $columnHeader.text(columnText.replace(r, currentIssuesAmount));
      }
    },

    errorSortable: function($oldColumn, responseText) {
      try {
        var errors = JSON.parse(responseText);
      } catch(e) {

      };
      var alertMessage = '';

      $oldColumn.sortable('cancel');

      if (errors && errors.length > 0) {
        for (var i = 0; i < errors.length; i++) {
          alertMessage += errors[i] + '\n';
        }
      }

      if (alertMessage) {
        alert(alertMessage);
      };
    },

    initSortable: function() {
      var self = this;
      var $issuesCols = $(".issue-version-col");

      $issuesCols.sortable({
        connectWith: ".issue-version-col",
        start: function(event, ui) {
          var $item = $(ui.item);
          $item.attr('oldColumnId', $item.parent().data('id'));
        },
        stop: function(event, ui) {
          var $item = $(ui.item);
          var sender = ui.sender;
          var $column = $item.parents('.issue-version-col');
          var issue_id = $item.data('id');
          var version_id = $column.data("id");
          var order = $column.sortable('serialize');
          var positions = {};
          var oldId = $item.attr('oldColumnId');
          var $oldColumn = $('.ui-sortable[data-id="' + oldId + '"]');

          $column.find('.issue-card').each(function(i, e) {
            var $e = $(e);
            positions[$e.data('id')] = { position: $e.index() };
          });

          $.ajax({
            url: self.routes.update_agile_board_path,
            type: 'PUT',
            data: {
              issue: {
                fixed_version_id: version_id
              },
              positions: positions,
              id: issue_id
            },
            success: function(data, status, xhr) {
              self.successSortable($oldColumn, $column);
            },
            error: function(xhr, status, error) {
              self.errorSortable($oldColumn, xhr.responseText);
            }
          });
        }
      }).disableSelection();

      $issuesCols.sortable( "option", "cancel", "div.pagination-wrapper" );

    },

  }

  AgileBoard.prototype = {

    init: function(routes) {
      var self = this;
      self.routes = routes;

      $(function() {
        self.initSortable();
        self.initDraggable();
        self.initDroppable();
      });
    },

    successSortable: function(oldStatusId, newStatusId, oldSwimLaneId, newSwimLaneId) {
      decHtmlNumber('th[data-column-id="' + oldStatusId + '"] span.count');
      incHtmlNumber('th[data-column-id="' + newStatusId + '"] span.count');
      decHtmlNumber('tr.group.swimlane[data-id="' + oldSwimLaneId + '"] td span.count');
      incHtmlNumber('tr.group.swimlane[data-id="' + newSwimLaneId + '"] td span.count');
    },

    errorSortable: function($oldColumn, responseText) {
      try {
        var errors = JSON.parse(responseText);
      } catch(e) {

      };

      var alertMessage = '';

      $oldColumn.sortable('cancel');

      if (errors && errors.length > 0) {
        for (var i = 0; i < errors.length; i++) {
          alertMessage += errors[i] + '\n';
        }
      }
      if (alertMessage) {
        alert(alertMessage);
      }
    },

    initSortable: function() {
      var self = this;
      var $issuesCols = $(".issue-status-col");

      $issuesCols.sortable({
        connectWith: ".issue-status-col",
        start: function(event, ui) {
          var $item = $(ui.item);
          $item.attr('oldColumnId', $item.parent().data('id'));
          $item.attr('oldSwimLaneId', $item.parents('tr.swimlane').data('id'));
          $item.attr('oldSwimLaneField', $item.parents('tr.swimlane').attr('data-field'));
        },
        stop: function(event, ui) {
          var $item = $(ui.item);
          var sender = ui.sender;
          var $column = $item.parents('.issue-status-col');
          var $swimlane = $item.parents('tr.swimlane');
          var issue_id = $item.data('id');
          var newStatusId = $column.data("id");
          var order = $column.sortable('serialize');
          var swimLaneId = $swimlane.data('id')
          var swimLaneField = $swimlane.attr('data-field');
          var positions = {};
          var oldStatusId = $item.attr('oldColumnId');
          var oldSwimLaneId = $item.attr('oldSwimLaneId');
          var oldSwimLaneField = $item.attr('oldSwimLaneField');
          var $oldColumn = $('.ui-sortable[data-id="' + oldStatusId + '"]');

          $column.find('.issue-card').each(function(i, e) {
            var $e = $(e);
            positions[$e.data('id')] = { position: $e.index() };
          });

          var params = {
              issue: {
                status_id: newStatusId
              },
              positions: positions,
              id: issue_id
            }
            params['issue'][swimLaneField] = swimLaneId;

          $.ajax({
            url: self.routes.update_agile_board_path,
            type: 'PUT',
            data: params,
            success: function(data, status, xhr) {
              self.successSortable(oldStatusId, newStatusId, oldSwimLaneId, swimLaneId);
            },
            error: function(xhr, status, error) {
              self.errorSortable($oldColumn, xhr.responseText);
            }
          });
        }
      }).disableSelection();

    },

    initDraggable: function() {
      $(".assignable-user").draggable({
        helper: "clone",
        start: function startDraggable(event, ui) {
          $(ui.helper).addClass("draggable-active")
        }
      });
    },

    initDroppable: function() {
      var self = this;

      $(".issue-card").droppable({
        activeClass: 'droppable-active',
        hoverClass: 'droppable-hover',
        accept: '.assignable-user',
        tolerance: 'pointer',
        drop: function(event, ui) {
          var $self = $(this);

          $.ajax({
            url: self.routes.issues_path + '/' + $self.data("id"),
            type: "PUT",
            dataType: "json",
            data: {
              issue: {
                assigned_to_id: ui.draggable.data("id")
              }
            }
          });
          $self.find("p.info").show();
          $self.find("p.info").html(ui.draggable.clone());
        }
      });
    },

  }

  window.AgileBoard = AgileBoard;
  window.PlanningBoard = PlanningBoard;
})();


function incHtmlNumber(element) {
  $(element).html(~~$(element).html() + 1);
}

function decHtmlNumber(element) {
  $(element).html(~~$(element).html() - 1);
}


function observeIssueSearchfield(fieldId, url) {
  $('#'+fieldId).each(function() {
    var $this = $(this);
    $this.addClass('autocomplete');
    $this.attr('data-value-was', $this.val());
    var check = function() {
      var val = $this.val();
      if ($this.attr('data-value-was') != val){
        $this.attr('data-value-was', val);
        $.ajax({
          url: url,
          type: 'get',
          data: {q: $this.val()},
          beforeSend: function(){ $this.addClass('ajax-loading'); },
          complete: function(){ $this.removeClass('ajax-loading'); }
        });
      }
    };
    var reset = function() {
      if (timer) {
        clearInterval(timer);
        timer = setInterval(check, 300);
      }
    };
    var timer = setInterval(check, 300);
    $this.bind('keyup click mousemove', reset);
  });
}