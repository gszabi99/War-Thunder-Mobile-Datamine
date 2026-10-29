from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "chat" import is_chat_message_allowed
from "%sqstd/platform.nut" import is_pc
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/dirtyWordsFilter.nut" import checkPhrase
from "%rGui/components/circleBtn.nut" import mkCircleImgBtn, circleBtnStyles
from "%rGui/chat/chatMsgCtors.nut" import getChatMessageCreator
from "%rGui/chat/chatState.nut" import MAX_CHAT_LOG_LEN, chatLogs, chatInputs, chatMembers, sendMessage, markChatSeen,
  chatLastSeenMsg, hasUnseen, getFirstUnseenMessageId, addSystemMessage
from "%darg/helpers/emojiLib.nut" import mkEmojiParams, prepareTextForEmojiSubst, mkTextareaWithEmoji
from "%rGui/contacts/contact.nut" import Contact
from "%rGui/contacts/contactInfoPkg.nut" import contactAvatar, contactNameBlockNoTitle
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo
from "%rGui/mpStatistics/viewProfile.nut" import viewProfile
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/style/stdColors.nut" import onlineColor, offlineColor, localPlayerColor, nameColor, hoverColor


const chatFont = fontTiny
const chatFontShaded = fontTinyShaded
const headerHeight = evenPx(60)
const inputHeight = evenPx(80)
const paddingToSendBtn = hdpxi(6)
const circleBtnSize = inputHeight - 2 * paddingToSendBtn
const borderWidth = hdpx(2)
let chatFontEmojiParams = mkEmojiParams(chatFont)
let chatFontLineH = chatFontEmojiParams.lineH
const needShowEmojiInTextInput = !is_pc

const msgBlockOffset = evenPx(300)
const msgListGap = hdpx(20)
const msgRadius = evenPx(20)
const msgCornerSize = hdpx(30)
const avatarSize = evenPx(90)
const onlineMarkSize = evenPx(14)
const eventIconGap = msgRadius / 2

const headerBgColor = 0xD0101010
const inputBgColor = 0xFF101010
const msgBgColor = 0xFF676767
const myMsgBgColor = 0xFF6F83A4

const CHAT_REPORT_LOG_MAX = 50

let scrollDownBtnStyle = freeze({ ...circleBtnStyles.COMMON, size = circleBtnSize })
let sendBtnStyle = freeze({ ...circleBtnStyles.PRIMARY, size = circleBtnSize })

function getChatReportSlicedLog(chatId, refMessageId = null) {
  let res = chatLogs.get()?[chatId] ?? []
  local endIdx = res.len() - 1
  if (refMessageId != null) {
    let idx = res.findindex(@(m) m?.messageId == refMessageId)
    if (idx != null)
      endIdx = idx
  }
  return res.slice(max(0, endIdx - CHAT_REPORT_LOG_MAX + 1), endIdx + 1)
}

let isScrollBottom = @(scrollHandler) (scrollHandler.elem?.getScrollOffsY() ?? 0)
  >= (scrollHandler.elem?.getContentHeight() ?? 0) - (scrollHandler.elem?.getHeight() ?? 0)
let scrollToBottom = @(scrollHandler) scrollHandler.scrollToY(
  max(0, (scrollHandler.elem?.getContentHeight() ?? 0) - (scrollHandler.elem?.getHeight() ?? 0)))


let mkChatHeader = @(text) {
  size = const [SIZE_TO_CONTENT, headerHeight]
  pos = const [0, msgListGap]
  hplace = ALIGN_CENTER
  padding = const [0, headerHeight / 2]

  rendObj = ROBJ_BOX
  fillColor = headerBgColor
  borderColor = headerBgColor
  borderWidth
  borderRadius = headerHeight / 2

  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(chatFont)
}

function mkScrollDownButton(scrollHandler) {
  let isVisible = Computed(@() !isScrollBottom(scrollHandler))
  return @() {
    watch = isVisible
    margin = const [0, paddingToSendBtn, msgListGap, 0 ]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = !isVisible.get() ? null
      : mkCircleImgBtn("ui/gameuiskin#scroll_down.svg", @() scrollToBottom(scrollHandler), scrollDownBtnStyle,
          loc("chat/toLastMessage"))
  }
}

let mkSendBtn = @(onClick) mkCircleImgBtn("ui/gameuiskin#chat_send.svg", onClick, sendBtnStyle, loc("chat/btnSend"))

let msgTextareaParamsBase = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  ...chatFont
}

let inputTextareaParams = {
  maxWidth = sw(100)
  ...msgTextareaParamsBase
}

function mkChatTextInput(chatId, onEscapeExt = null, hasFloodFilter = false) {
  let text = Computed(@() chatInputs.get()?[chatId] ?? "")
  function sendCurMessage() {
    let val = checkPhrase(text.get().strip())
    if (val == "")
      return
    if (hasFloodFilter && !is_chat_message_allowed(val)) {
      addSystemMessage(chatId, loc("chat/send_disabled_hint"))
      return
    }
    sendMessage(chatId, val)
    chatInputs.mutate(@(ci) ci.$rawset(chatId, ""))
  }

  return {
    size = const [FLEX, inputHeight]
    padding = const [0, paddingToSendBtn, 0, inputHeight / 2]
    rendObj = ROBJ_BOX
    fillColor = inputBgColor
    borderColor = inputBgColor
    borderWidth
    borderRadius = inputHeight / 2

    flow = FLOW_HORIZONTAL
    gap = paddingToSendBtn
    valign = ALIGN_CENTER
    children = [
      {
        size = [FLEX, chatFontLineH]
        valign = ALIGN_CENTER
        children = [
          @() {
            watch = text
            key = chatId
            size = [FLEX, chatFontLineH]

            rendObj = ROBJ_TEXT
            behavior = Behaviors.TextInput
            maxChars = 512
            text = text.get()
            color = needShowEmojiInTextInput ? 0x00000000 : 0xFFFFFFFF
            onChange = @(v) chatInputs.mutate(@(ci) ci.$rawset(chatId, v))
            onReturn = sendCurMessage
            function onEscape() {
              set_kb_focus(null)
              onEscapeExt?()
            }
            onAttach = is_pc ? @() set_kb_focus(chatId) : null
            ...chatFont
          }
          !needShowEmojiInTextInput
            ? null
            : {
              size = [FLEX, chatFontLineH]
              clipChildren = true
              children = function() {
                let { textForSubst, substMap } = prepareTextForEmojiSubst(text.get())
                return mkTextareaWithEmoji(textForSubst, substMap, inputTextareaParams, chatFontEmojiParams)
                  .__update({ watch = text })
              }
            }
        ]
      }
      mkSendBtn(sendCurMessage)
    ]
  }
}

let mkOnlineComp = @(userId, members) {
  size = const [onlineMarkSize, avatarSize]
  valign = ALIGN_CENTER
  children = @() {
    watch = members
    size = onlineMarkSize
    rendObj = ROBJ_BOX
    fillColor = userId in members.get() ? onlineColor : offlineColor
    borderColor = userId in members.get() ? onlineColor : offlineColor
    borderWidth
    borderRadius = onlineMarkSize / 2
  }
}

let mkSystemMsg = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  halign = ALIGN_CENTER
  ...chatFont
}

let mkChatEventMsg = @(text, maxWidth, borderColor = null, icon = null) {
  hplace = ALIGN_CENTER
  padding = const [eventIconGap, msgRadius]
  rendObj = ROBJ_BOX
  fillColor = msgBgColor
  borderColor = borderColor ?? msgBgColor
  borderWidth = borderWidth * 2
  borderRadius = msgRadius
  flow = FLOW_HORIZONTAL
  gap = eventIconGap
  valign = ALIGN_CENTER
  children = [
    {
      maxWidth = icon == null
        ? maxWidth
        : maxWidth - (icon?.size ?? 0) - eventIconGap
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      text,
      ...chatFont
    }
    icon
  ]
}

let msgCorner = {
  size = msgCornerSize
  pos = const [0, msgRadius]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = 1
  color = msgBgColor
  fillColor = msgBgColor
  commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100]]
}

let msgCornerMy = msgCorner.__merge({
  color = myMsgBgColor
  fillColor = myMsgBgColor
  commands = [[VECTOR_POLY, 0, 0, 100, 0, 0, 100]]
})

function mkMessageText(text, contact, info, isMe, maxTextWidth) {
  let nameBlock = @() contactNameBlockNoTitle(contact.get(), info.get(),
    { color = isMe.get() ? localPlayerColor : nameColor }.__update(chatFontShaded),
    { watch = [ contact, info, isMe ] })
  let { textForSubst, substMap } = prepareTextForEmojiSubst(text)
  let msgTextareaParams = msgTextareaParamsBase.__merge({ maxWidth = maxTextWidth })
  return function() {
    let color = isMe.get() ? myMsgBgColor : msgBgColor
    let children = [{
      padding = const [msgRadius / 2, msgRadius]

      rendObj = ROBJ_BOX
      fillColor = color
      borderColor = color
      borderWidth
      borderRadius = msgRadius

      flow = FLOW_VERTICAL
      children = [
        nameBlock
        mkTextareaWithEmoji(textForSubst, substMap, msgTextareaParams, chatFontEmojiParams)
      ]
    }]
    if (isMe.get())
      children.append(msgCornerMy)
    else
      children.insert(0, msgCorner)

    return {
      watch = isMe
      size = FLEX_H
      halign = isMe.get() ? ALIGN_RIGHT : ALIGN_LEFT
      flow = FLOW_HORIZONTAL
      children
    }
  }
}

let onAvatarClick = @(chatId, userIdStr, messageId)
  viewProfile(userIdStr, { chatLog = getChatReportSlicedLog(chatId, messageId) })

let avatarBorder = {
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = hoverColor
  fillColor = 0
}

function mkAvatar(info, userIdStr, onClick) {
  let stateFlags = Watched(0)
  return @() contactAvatar(info.get(), avatarSize, {
    watch = [info, stateFlags]
    key = userIdStr
    behavior = Behaviors.Button
    onClick
    onElemState = @(sf) stateFlags.set(sf)
    sound = { click = "click" }
    children = stateFlags.get() & S_HOVER ? avatarBorder : null
    ...mkPressTransitionScale(stateFlags.get())
  })
}

function mkMessage(msg, members, maxTextWidth, chatId) {
  let { sender = null, text, messageId = null } = msg
  let { userId = null } = sender
  if (userId == null)
    return mkSystemMsg(text)

  let isMe = Computed(@() myUserId.get() == userId)
  let userIdStr = userId.tostring()
  let info = mkPublicInfo(userIdStr)
  let contact = Contact(userIdStr)
  let onAttach = messageId == null ? null : @() refreshPublicInfo(userIdStr)

  let avatar = mkAvatar(info, userIdStr, @() onAvatarClick(chatId, userIdStr, messageId))
  let msgText = mkMessageText(text, contact, info, isMe, maxTextWidth)
  return @() {
    watch = isMe
    key = messageId
    size = FLEX_H
    pos = [isMe.get() ? msgBlockOffset / 2 : -msgBlockOffset / 2, 0]
    onAttach

    halign = isMe.get() ? ALIGN_RIGHT : ALIGN_LEFT
    flow = FLOW_HORIZONTAL
    gap = msgListGap
    children = isMe.get()
      ? [msgText, avatar]
      : [mkOnlineComp(userId, members), avatar, msgText]
  }
}

let pannable = @(size, scrollHandler, content) {
  size
  clipChildren = true
  children = {
    size = FLEX
    behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
    touchMarginPriority = TOUCH_BACKGROUND
    skipDirPadNav = true
    scrollHandler
    children = content
  }
}

function scrollToFirstUnseen(scrollHandler, chatLog, chatId) {
  if (chatLog.get().len() == 0) {
    scrollToBottom(scrollHandler)
    return
  }
  let lastSeen = chatLastSeenMsg.get()?[chatId].id
  if (lastSeen == null)
    return
  if (!hasUnseen(chatLog.get(), lastSeen, myUserId.get())) {
    scrollToBottom(scrollHandler)
    return
  }

  local msgId = getFirstUnseenMessageId(chatLog.get(), lastSeen, myUserId.get())
  if (msgId == null)
    return

  scrollToBottom(scrollHandler)
  if (chatLog.get().top().messageId == msgId)
    return 

  scrollHandler.scrollToChildren(@(d) d?.key == msgId, 2, false, true)
}

function mergeMessages(messages, extras) {
  if (extras.len() == 0)
    return messages

  let minTs = messages.len() >= MAX_CHAT_LOG_LEN ? messages[0].timestamp : 0
  let res = [...messages]
  local idx = 0
  foreach (extra in extras) {
    if (extra.timestamp < minTs)
      continue
    while (idx < res.len() && res[idx].timestamp < extra.timestamp)
      idx++
    res.insert(idx++, extra)
  }
  return res
}

function mkChatLog(chatId, width, headerText = "", extraItems = Watched([])) {
  let blockSize = [width, FLEX]
  let chatLog = Computed(@() chatLogs.get()?[chatId] ?? [])
  let members = Computed(@() chatMembers.get()?[chatId] ?? {})
  let maxTextWidth = width - msgBlockOffset
    - avatarSize - onlineMarkSize - 2 * msgListGap
    - msgCornerSize - 2 * msgRadius

  let maxEventTextWidth = width - msgBlockOffset - 2 * msgRadius
  let listItems = Computed(@() mergeMessages(chatLog.get(), extraItems.get()))

  function mkMsgComp(msg) {
    let ctor = getChatMessageCreator(msg?.ctorId)
    return ctor == null ? mkMessage(msg, members, maxTextWidth, chatId) : ctor(msg, maxEventTextWidth)
  }

  let scrollHandler = ScrollHandler()
  let content = pannable(blockSize, scrollHandler,
    @() {
      watch = listItems
      size = [width, SIZE_TO_CONTENT]
      padding = [
        headerText == "" ? msgListGap : headerHeight + 2 * msgListGap, msgBlockOffset / 2,
        msgListGap, msgBlockOffset / 2
      ]
      flow = FLOW_VERTICAL
      gap = msgListGap
      children = listItems.get().map(mkMsgComp)
    })

  let scrollToBottomCurChat = @() scrollToBottom(scrollHandler)
  listItems.subscribe(@(_) !isScrollBottom(scrollHandler) ? null : deferOnce(scrollToBottomCurChat))
  scrollHandler.subscribe(@(_) isScrollBottom(scrollHandler) ? markChatSeen(chatId) : null)

  return {
    size = blockSize
    key = scrollHandler
    onAttach = @() scrollToFirstUnseen(scrollHandler, chatLog, chatId)
    children = [
      content
      headerText == "" ? null : mkChatHeader(headerText)
      mkScrollDownButton(scrollHandler)
    ]
  }
}

return {
  msgListGap
  mkChatLog
  mkChatTextInput
  mkChatEventMsg
}