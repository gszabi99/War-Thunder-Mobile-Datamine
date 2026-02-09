from "%globalsDarg/darg_library.nut" import *
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { iconButtonCommon } = require("%rGui/components/textButton.nut")
let { gap, rowHeight } = require("%rGui/contacts/contactInfoPkg.nut")
let { onNotifyRemove, onNotifyApply, invitations } = require("%rGui/invitations/invitationsState.nut")


let btnIconSize = evenPx(50)
let btnMargin = hdpx(8)
let btnDefOvr = {
  iconSize = btnIconSize,
  ovr = {
    size = [hdpx(130), rowHeight - btnMargin * 2],
    minWidth = btnIconSize
    vplace = ALIGN_CENTER
  }
}

function mkTimeMark(uid) {
  let timeText = Computed(function() {
    let notify = invitations.get().findvalue(@(v) v.playerUid == uid)
    let { time = 0 } = notify
    local showTime = serverTime.get() - time
    showTime = showTime - (showTime % 60)
    if (showTime <= 0)
      return loc("justNow")
    return loc("timeAgo", { time = secondsToHoursLoc(showTime) })
  })

  return @() {
    watch = timeText
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(100)
    color = 0xFFFFFFFF
    text = timeText.get()
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
  }.__update(fontVeryTiny)
}

let mkSquadResponse = @(uidStr) @() {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  margin = hdpx(8)
  children = [
    mkTimeMark(uidStr.tointeger())
    iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg", @() onNotifyRemove(uidStr.tointeger()), btnDefOvr)
    iconButtonCommon("ui/gameuiskin#icon_party_ready.svg", @() onNotifyApply(uidStr.tointeger()), btnDefOvr)
  ]
}

return mkSquadResponse
