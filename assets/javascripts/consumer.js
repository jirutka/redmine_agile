class activeCableConsumer {
  OPEN = 1

  constructor(url, channel, chatId, consumer) {
    this.url = url
    this.socket = this.intializeSocket(channel, chatId, consumer)
  }

  static processMessage(consumer, message) {
    consumer.process(message)
  }

  intializeSocket(channel, chatId, consumer) {
    const socket = new WebSocket(this.url)

    socket.onopen = function() {
      const message = {
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: channel,
          chat_id: chatId
        })
      }
      socket.send(JSON.stringify(message))
    }

    socket.onclose = function() {
      console.log("WebSocket is closed")
    }

    socket.onmessage = function(event) {
      const messageData = (event.data && JSON.parse(event.data)) || {}
      if (messageData.type === 'ping' || !messageData.message) { return }
      const message = messageData.message

      activeCableConsumer.processMessage(consumer, message)
    }

    socket.onerror = function(error) {
      console.log(error)
    }

    return socket
  }

  isOpen() {
    return this.socket.readyState === this.OPEN
  }
}
