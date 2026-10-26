from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/permissions.nut" import allow_clans_chat
from "%rGui/chat/chatPkg.nut" import mkChatTextInput, mkChatLog, msgListGap
from "%rGui/clans/clanChatState.nut" import clanChatId
from "%rGui/clans/clanChatLog.nut" import clanChatLogItems
from "%rGui/options/optionsStyle.nut" import contentWidthFull
from "%rGui/style/listConst.nut" import selLineSize
from "%rGui/style/stdColors.nut" import selectColor


let selLine = {
  size = [FLEX, selLineSize]
  rendObj = ROBJ_SOLID
  color = selectColor
}

function chatContent() {
  let chatId = !allow_clans_chat.get() ? null : clanChatId.get()
  return {
    watch = [allow_clans_chat, clanChatId]
    size = FLEX
    padding = [0, msgListGap, msgListGap, msgListGap]
    flow = FLOW_VERTICAL
    children = [
      mkChatLog(chatId, contentWidthFull - 2 * msgListGap, "", clanChatLogItems)
      chatId == null ? null : mkChatTextInput(chatId)
    ]
  }
}

return {
  size = [contentWidthFull, FLEX]
  rendObj = ROBJ_SOLID
  color = 0x80202020
  flow = FLOW_VERTICAL

  children = [
    selLine
    chatContent
  ]
}