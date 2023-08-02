from "%globalsDarg/darg_library.nut" import *
let { Contact } = require("%rGui/contacts/contact.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { markRead, onNotifyRemove, onNotifyApply } = require("invitationsState.nut")
let { darkenBgColor, borderWidth, rowHeight, gap,
  contactNameBlock, contactAvatar, contactLevelBlock
} = require("%rGui/contacts/contactInfoPkg.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { secondsToHoursLoc } = require("%rGui/globals/timeToText.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")

let maxWidth = hdpx(1300)
let btnSize = [evenPx(120), evenPx(55)]

let unreadMark = priorityUnseenMark.__merge({ margin  = 2 * borderWidth })

let function mkTimeMark(notify) {
  let { time } = notify
  let timeText = Computed(function() {
    local showTime = serverTime.value - time
    showTime = showTime - (showTime % 60)
    if (showTime <= 0)
      return loc("justNow")
    return loc("timeAgo", { time = secondsToHoursLoc(showTime) })
  })
  return @() {
    watch = timeText
    rendObj = ROBJ_TEXT
    color = 0xFF808080
    text = timeText.value
    hplace = ALIGN_RIGHT
  }.__update(fontVeryTiny)
}

let mkNotifyBg = @(notify, rowIdx, children) {
  key = rowIdx
  size = [flex(), rowHeight]
  maxWidth
  padding = borderWidth
  rendObj = ROBJ_SOLID
  color = (rowIdx % 2) ? 0 : darkenBgColor

  behavior = Behaviors.Button
  onClick = @() markRead(notify.id)
  xmbNode = {}

  children = [
    {
      size = flex()
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap
      children
    }
    notify.isRead ? null : unreadMark
    mkTimeMark(notify)
  ]
}

let mkTextArea = @(text, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFE0E0E0
  colorTable = {
    mark = 0xFFFFB70B
    darken = 0xFF8898CC
  }
  text
}.__update(fontTiny, ovr)

let btnDefOvr = { size = btnSize, vplace = ALIGN_BOTTOM }
let btnRemove = @(notify) framedImageBtn("ui/gameuiskin#btn_trash.svg",
  @() onNotifyRemove(notify),
  btnDefOvr)

let mkTextNotify = @(notify, rowIdx) mkNotifyBg(notify, rowIdx,
  [
    mkTextArea(notify.text, { margin = [0, 0.5 * rowHeight] })
    btnRemove(notify)
  ])

let function mkPlayerNotify(notify, rowIdx, addChild = null) {
  let { playerUid } = notify
  let userId = playerUid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  return @() mkNotifyBg(notify, rowIdx,
    [
      contactLevelBlock(info.value)
      contactAvatar(info.value)
      contactNameBlock(contact.value, info.value)
      mkTextArea(notify.text, { halign = ALIGN_RIGHT })
      addChild ?? btnRemove(notify)
    ]
  ).__update({
    watch = [contact, info]
    key = playerUid
    onAttach = @() refreshPublicInfo(userId)
  })
}

let mkInviteFromPlayer = @(notify, rowIdx) mkPlayerNotify(notify, rowIdx,
  {
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap
    children = [
      framedImageBtn("ui/gameuiskin#icon_party_not_ready.svg",
        @() onNotifyRemove(notify),
        btnDefOvr)
      framedImageBtn("ui/gameuiskin#icon_party_ready.svg",
        @() onNotifyApply(notify),
        btnDefOvr)
    ]
  })

let ctors = {
  PLAYER_INVITE = mkInviteFromPlayer
}

let function mkNotifyRow(notify, rowIdx) {
  let { styleId, playerUid } = notify
  let ctor = ctors?[styleId]
    ?? (playerUid != null ? mkPlayerNotify : mkTextNotify)
  return ctor(notify, rowIdx)
}

return mkNotifyRow