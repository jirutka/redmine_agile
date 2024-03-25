class agileBoardConsumer {
  constructor(url, chatId) {
    this.channel = 'ActionCable::Channels::AgileChannel'
    this.baseConsumer = new activeCableConsumer(url, this.channel, chatId, this)
  }

  isOpen() {
    return this.baseConsumer.isOpen()
  }

  process(message) {
    switch (message.type) {
      case 'issueMoved':
        moveIssue(message.actor_id, message.issue_id, message.from, message.to)
        break
      default:
        console.log("Unknown type: " + message.rcrm_type)
    }
  }
}


function moveIssue(actorId, issueId, fromData, toData) {
  if (actorId === $(".agile-board").data("actor")) { return }
  const $card = $(".issue-card[data-id=" + issueId + "]")
  const $destColumn = $($(".issue-status-col[data-id=" + toData.status_id + "]"))

  if ($card && $destColumn) {
    $card.hide({ duration: 300, complete: function () {
      aboveIssue = toData.position > 0 && $destColumn.find(".issue-card[data-id!=" + issueId + "]")[toData.position - 1]
      if (aboveIssue) {
        $card.insertAfter(aboveIssue)
      } else if($destColumn.hasClass("empty") || toData.position === 0) {
        $destColumn.prepend($card)
      }

      const $from_headers = $(".issues-board th[data-column-id="+ fromData.status_id + "]")
      const $to_headers = $(".issues-board th[data-column-id="+ toData.status_id + "]")
      $from_headers.each(function(_idx, th) {
        $(th).find("span.hours").html(fromData.points_label)
      })
      $to_headers.each(function(_idx, th) {
        $(th).find("span.hours").html(toData.points_label)
      })

      $card.show(300)
    } })
  }
}
