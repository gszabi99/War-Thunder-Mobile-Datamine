from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { squadMembers, isInvitedToSquad, squadId, squadLeaderCampaign, isSquadLeader,
  squadLeaderReadyCheckTime
} = require("%appGlobals/squadState.nut")
let { Contact } = require("%rGui/contacts/contact.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkContactOnlineStatus } = require("%rGui/contacts/contactPresence.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { mkAnimGrowLines, mkAGLinesCfgOrdered } = require("%rGui/components/animGrowLines.nut")
let { gap, contactNameBlock, contactAvatar, contactLevelBlock, contactLevelSize
} = require("%rGui/contacts/contactInfoPkg.nut")
let { offlineColor, leaderColor, memberNotReadyColor, memberReadyColor } = require("%rGui/style/stdColors.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitInfo
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkContactActionBtn } = require("%rGui/contacts/mkContactActionBtn.nut")
let { REVOKE_INVITE, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, LEAVE_SQUAD } = require("%rGui/contacts/contactActions.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")


let WND_UID = "squad_member_info_wnd"

let headerWidth = hdpx(1250)
let avatarSize = hdpxi(200)
let wndGap = hdpx(24)
let statusSize = hdpxi(25)
let wndHSize = avatarSize + wndGap + defButtonHeight

let openParams = mkWatched(persist, "openParams", null)
let wndAABB = Watched(null)

let close = @() openParams(null)
openParams.subscribe(@(_) wndAABB(null))
squadMembers.subscribe(@(v) openParams.value == null || openParams.value.uid in v ? null
  : close())
isInvitedToSquad.subscribe(function(v) {
  let { uid = null } = openParams.value
  if (uid != null && uid not in squadMembers.value && uid not in v)
    close()
})
isSquadLeader.subscribe(@(_) close()) //bad view on change leadership, so better to close window or rebuild animated lines

let statusView = {
  leader = {
    text = colorize(leaderColor, loc("status/squad_leader"))
    icon = "icon_party_leader.svg"
    color = 0xFFFFFF00
  }
  memberReadyCheck = {
    text = colorize(0xFFC0C0C0, loc("squad/readyCheckWait"))
    icon = mkSpinner(statusSize)
  }
  memberReady = {
    text = colorize(memberReadyColor, loc("status/squad_ready"))
    icon = "icon_party_ready.svg"
  }
  memberNotReady = {
    text = colorize(memberNotReadyColor, loc("status/squad_not_ready"))
    icon = "icon_party_not_ready.svg"
  }
  memberOffline = {
    text = colorize(offlineColor, loc("contacts/offline"))
    icon = "icon_party_offline.svg"
  }
  invitee = {
    text = loc("status/squad_invited")
  }
}

let mkStatusRow = @(icon, iconColor, text, ovr = {}) {
  size = flex()
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    type(icon) != "string" ? icon
      : {
          size = [statusSize, statusSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#{icon}:{statusSize}:{statusSize}:P")
          color = iconColor ?? 0xFFFFFFFF
        }
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
    }.__update(fontVeryTiny)
  ]
}.__update(ovr)

function statusBlock(uid) {
  let onlineStatus = mkContactOnlineStatus(uid.tostring())
  let view = Computed(@() squadId.value == uid ? statusView.leader
    : squadMembers.value?[uid].ready ? statusView.memberReady
    : isInvitedToSquad.value?[uid] ? statusView.invitee
    : onlineStatus.value == false ? statusView.memberOffline
    : squadLeaderReadyCheckTime.value > (squadMembers.value?[uid].readyCheckTime ?? 0) ? statusView.memberReadyCheck
    : uid in squadMembers.value ? statusView.memberNotReady
    : null)
  return @() mkStatusRow(view.value?.icon, view.value?.color, view.value?.text,
    { watch = view })
}

function inBattleBlock(uid) {
  let isInBattle = Computed(@() squadMembers.value?[uid].inBattle ?? false)
  return @() !isInBattle.value ? { watch = isInBattle }
    : mkStatusRow("in_battle.svg", 0xFFFFFFFF, loc("status/in_battle"), { watch = isInBattle })
}

let unitInfo = @(unitW) function() {
  let res = { watch = unitW }
  let unit = unitW.value
  if (unit == null)
    return res

  let p = getUnitPresentation(unit)

  return res.__update({
    size = [ unitPlateWidth, unitPlateHeight ]
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(p.locId))
      mkUnitInfo(unit)
    ]
  })
}

function memberInfo(uid) {
  let userId = uid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  let status = statusBlock(uid)
  let battleStatus = inBattleBlock(uid)
  let bestUnit = Computed(function() {
    local list = squadMembers.get()?[uid].units[squadLeaderCampaign.get()] ?? []
    local res = null
    foreach(unitName in list) {
      let unit = serverConfigs.get()?.allUnits[unitName]
      if (unit != null && (res == null || unit.mRank > res.mRank))
        res = unit
    }
    return res
  })
  return @() {
    watch = [contact, info]
    size = [headerWidth, avatarSize]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap
    children = [
      contactLevelBlock(info.value)
      contactAvatar(info.value, avatarSize)
      contactNameBlock(contact.value, info.value, [status, battleStatus])
        .__update({ padding = [hdpx(40), 0], size = flex()})
      unitInfo(bestUnit)
    ]
  }
}

function buttons(uid) {
  let userId = uid.tostring()
  let needButtonsPlace = Computed(@() isSquadLeader.value || uid == myUserId.value)
  return @() !needButtonsPlace.value ? { watch = needButtonsPlace }
    : {
        watch = needButtonsPlace
        size = [flex(), defButtonHeight]
        flow = FLOW_HORIZONTAL
        padding = [0, 0, 0, contactLevelSize + gap]
        gap = wndGap
        children = [
          mkContactActionBtn(LEAVE_SQUAD, userId, { hotkeys = ["^J:LB"] })
          mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
          mkContactActionBtn(REMOVE_FROM_SQUAD, userId, { hotkeys = ["^J:LB"] })
          mkContactActionBtn(PROMOTE_TO_LEADER, userId, { hotkeys = ["^J:Y"] })
        ]
      }
}

let wndKey = {}
let mkWindow = @(uid) {
  key = wndKey
  stopMouse = true
  function onAttach() {
    refreshPublicInfo(uid.tostring())
    defer(@() wndAABB(gui_scene.getCompAABBbyKey(wndKey)))
  }

  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = wndGap
  gap = wndGap

  children = [
    memberInfo(uid)
    buttons(uid)
  ]
}

let animLines = @(rect) function() {
  let res = { watch = wndAABB }
  if (wndAABB.value == null)
    return res

  let { t, b, r, l } = rect
  let w = wndAABB.value
  let midX = (r + l) / 2
  let wMidX = (w.r + w.l) / 2

  let lines = [
    //member button
    [
      [midX, b, l, b],
      [midX, b, r, b],
    ],
    [
      [l, b, l, t],
      [r, b, r, t],
    ],
    [
      [l, t, midX, t],
      [r, t, midX, t],
    ],
    //middle line
    [[midX, t, midX, w.b]],
    //window
    [
      [midX, w.b, w.l, w.b],
      [midX, w.b, w.r, w.b],
    ],
    [
      [w.l, w.b, w.l, w.t],
      [w.r, w.b, w.r, w.t],
    ],
    [
      [w.l, w.t, wMidX, w.t],
      [w.r, w.t, wMidX, w.t],
    ]
  ]

  return res.__update({
    size = flex()
    children = mkAnimGrowLines(mkAGLinesCfgOrdered(lines, hdpx(3000)))
  })
}

function content() {
  if (openParams.value == null)
    return { watch = openParams }

  let { uid, rect } = openParams.get()
  let { r, l, t, b } = rect

  let buttonCenter = (l + r) / 2
  let isButtonInCenter = buttonCenter <  0.75 * saSize[0]

  let posX = isButtonInCenter ? buttonCenter - headerWidth / 2
    : (saSize[0] + saBordersRv[0]) - headerWidth
  let posY = t - ((b - t) + wndHSize)

  return {
    watch = openParams
    size = flex()
    children = [
      mkCutBg([rect])
      {
        pos = [posX, posY]
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkWindow(uid)
      }
      animLines(rect)
    ]
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  children = content
  onClick = close
})

if (openParams.value != null)
  openImpl()
openParams.subscribe(@(v) v != null ? openImpl() : removeModalWindow(WND_UID))


return @(uid, rect) openParams({ uid, rect })