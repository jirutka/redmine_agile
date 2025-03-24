class agileBoardConsumer {
  constructor(url, chatId) {
    this.channel = "ActionCable::Channels::AgileChannel";
    this.url = url;
    this.chatId = chatId;

    this.baseConsumer = new activeCableConsumer(this);
  }

  isOpen() {
    return this.baseConsumer.isOpen();
  }

  process(message) {
    switch (message.type) {
      case "issueMoved":
        this.#moveIssue(
          message.actor_id,
          message.avatar,
          message.issue_id,
          message.swimlane_id,
          message.from,
          message.to
        );
        break;
      case "issueUpdated":
        this.#updateIssue(
          message.actor_id,
          message.avatar,
          message.issue_id,
          message.swimlane_id,
          message.html
        );
        break;
      case "issueCreated":
        this.#createIssue(
          message.actor_id,
          message.avatar,
          message.status_id,
          message.swimlane_id,
          message.html
        );
        break;
      case "issueDeleted":
        this.#deleteIssue(
          message.actor_id,
          message.avatar,
          message.status_id,
          message.swimlane_id,
          message.issue_id
        );
        break;
      default:
        console.log("Unknown message type: " + message.rcrm_type);
    }
  }

  #moveIssue(actorId, avatar, issueId, swimlaneId, fromData, toData) {
    if (this.#notAvailable(actorId, swimlaneId)) return;

    const columnSelector =
      (swimlaneId ? "tr.swimlane[data-id=" + swimlaneId + "]" : "") +
      " .issue-status-col[data-id=" +
      toData.status_id +
      "]";
    const $card = $(".issue-card[data-id=" + issueId + "]");
    const $destColumn = $($(columnSelector));

    if ($card && $destColumn.length === 0) {
      $card.fadeOut({
        duration: 400,
        complete: function () {
          $card.remove();
        },
      });
    }

    if ($card && $destColumn) {
      $card.fadeOut({
        duration: 400,
        complete: function () {
          const aboveIssue =
            toData.position > 0 &&
            $destColumn.find(".issue-card[data-id!=" + issueId + "]")[
              toData.position - 1
            ];
          if (aboveIssue) {
            $card.insertAfter(aboveIssue);
          } else if ($destColumn.hasClass("empty") || toData.position === 0) {
            $destColumn.prepend($card);
          }

          const $from_headers = $(
            ".issues-board th[data-column-id=" + fromData.status_id + "]"
          );
          const $to_headers = $(
            ".issues-board th[data-column-id=" + toData.status_id + "]"
          );
          $from_headers.each(function (_idx, th) {
            $(th).find("span.hours").html(fromData.points_label);
          });
          $to_headers.each(function (_idx, th) {
            $(th).find("span.hours").html(toData.points_label);
          });

          $card.fadeIn(400);
        },
      });
      this.#showAvatar(avatar);
    }
  }

  #updateIssue(actorId, avatar, issueId, swimlaneId, html) {
    if (this.#notAvailable(actorId, swimlaneId)) return;

    const $card = $(".issue-card[data-id=" + issueId + "]");
    if ($card) {
      $card.replaceWith(html);
      this.#showAvatar(avatar);
    }
  }

  #createIssue(actorId, avatar, statusId, swimlaneId, html) {
    if (this.#notAvailable(actorId, swimlaneId)) return;

    const columnSelector =
      (swimlaneId ? "tr.swimlane[data-id=" + swimlaneId + "]" : "") +
      " .issue-status-col[data-id=" +
      statusId +
      "]";
    const $destColumn = $($(columnSelector));

    if ($destColumn) {
      const $lastCard = $destColumn.find(".issue-card").last();
      $lastCard.length > 0 ? $lastCard.after(html) : $destColumn.prepend(html);
      this.#showAvatar(avatar);
    }
  }

  #deleteIssue(actorId, avatar, statusId, swimlaneId, issueId) {
    if (this.#notAvailable(actorId, swimlaneId)) return;

    const $card = $(".issue-card[data-id=" + issueId + "]");

    if ($card) {
      $card.fadeOut({
        duration: 400,
        complete: function () {
          $card.remove();
        },
      });
      this.#showAvatar(avatar);
    }
  }

  #notAvailable(actorId, swimlaneId) {
    return (
      actorId === $(".agile-board").data("actor") ||
      ($("tr.group").length > 0 && !swimlaneId)
    );
  }

  #showAvatar(avatar) {
    const $avatarWrapper = $(".ws-actors-wrapper");
    const $avatarTarget = $(".ws-actor");

    if ($avatarWrapper && $avatarTarget) {
      $avatarTarget.html(avatar);
      $avatarWrapper.fadeIn({
        duration: 400,
        complete: function () {
          $avatarWrapper.fadeOut(400);
        },
      });
    }
  }
}
