let chatMsgCtors = {}

function registerChatMessageCreator(id, ctor) {
  if (id in chatMsgCtors)
    assert(false, $"try to register duplicate chat message creator {id}")
  chatMsgCtors[id] <- ctor
}

let getChatMessageCreator = @(id) chatMsgCtors?[id]

return {
  getChatMessageCreator
  registerChatMessageCreator
}
