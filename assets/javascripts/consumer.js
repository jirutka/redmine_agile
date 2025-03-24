class activeCableConsumer {
  OPEN = 1;

  constructor(consumer) {
    this.consumer = consumer;
    this._isConnecting = true;

    this.connect();
  }

  connect() {
    this.socket = this.intializeSocket(this, this.consumer);
    this._isConnecting = false;
  }

  reconnect() {
    if (!this._isConnecting) {
      setTimeout(this.connect.bind(this), 3000);
      this._isConnecting = true;
    }
  }

  processMessage(message) {
    this.consumer.process(message);
  }

  isOpen() {
    return this.socket.readyState === this.OPEN;
  }

  intializeSocket(self, consumer) {
    const socket = new WebSocket(consumer.url);

    socket.onopen = function () {
      const message = {
        command: "subscribe",
        identifier: JSON.stringify({
          channel: consumer.channel,
          chat_id: consumer.chatId,
        }),
      };
      socket.send(JSON.stringify(message));
    };

    socket.onclose = function () {
      self.reconnect();
    };

    socket.onmessage = function (event) {
      const messageData = (event.data && JSON.parse(event.data)) || {};
      if (messageData.type === "ping" || !messageData.message) {
        return;
      }
      const message = messageData.message;

      self.processMessage(message);
    };

    socket.onerror = function (error) {
      console.log(error);
      self.reconnect();
    };

    return socket;
  }
}
