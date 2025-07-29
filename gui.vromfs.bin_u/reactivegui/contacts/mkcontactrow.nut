from "%globalsDarg/darg_library.nut" import *
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { Contact } = require("contact.nut")
let { mkPublicInfo, refreshPublicInfo } = require("contactPublicInfo.nut")
let { mkContactOnlineStatus, presences } = require("contactPresence.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { darkenBgColor, borderWidth, rowHeight, gap,
  contactNameBlock, contactAvatar, contactLevelBlock
} = require("contactInfoPkg.nut")
let { isInSquad, squadId, isInvitedToSquad, squadMembers } = require("%appGlobals/squadState.nut")
let { onlineColor, offlineColor, leaderColor, memberNotReadyColor, memberReadyColor } = require("%rGui/style/stdColors.nut")

function onlineBlock(uid, onlineStatus, battleUnit) {
  let onlineText = Computed(@() onlineStatus.value == null ? ""
    : !onlineStatus.value ? colorize(offlineColor, loc("contacts/offline"))
    : battleUnit.value != null
      ? "\n".concat(loc("status/in_battle"), loc(getCampaignPresentation(battleUnit.value?.campaign).headerLocId))
    : colorize(onlineColor, loc("contacts/online")))
  let squadText = Computed(@() !isInSquad.get() ? ""
    : squadId.get() == uid ? colorize(leaderColor, loc("status/squad_leader"))
    : squadMembers.get()?[uid].ready ? colorize(memberReadyColor, loc("status/squad_ready"))
    : uid in squadMembers.get() ? colorize(memberNotReadyColor, loc("status/squad_not_ready"))
    : isInvitedToSquad.get()?[uid] ? loc("status/squad_invited")
    : "")
  return @() {
    watch = [onlineText, squadText]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = "\n".join([squadText.value, onlineText.value], true)
  }.__update(fontVeryTiny)
}

function mkContactRow(uid, rowIdx, isSelected, onClick, responseAction = null) {
  let userId = uid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  let onlineStatus = mkContactOnlineStatus(userId)
  let battleUnit = Computed(@() serverConfigs.get()?.allUnits[presences.get()?[userId].battleUnit])
  let stateFlags = Watched(0)
  let isHovered = Computed(@() (stateFlags.value & S_HOVER) != 0)
  return @() {
    watch = [contact, info, isSelected, isHovered]
    key = uid
    size = [flex(), rowHeight]
    padding = borderWidth
    rendObj = ROBJ_BOX
    fillColor = (rowIdx % 2) ? 0 : darkenBgColor
    borderWidth = isSelected.value || isHovered.value ? borderWidth : 0
    borderColor = isSelected.value ? 0xFF52C7E4 : 0xFF3E95AB

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    xmbNode = {}
    onAttach = @() refreshPublicInfo(uid)

    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap

    children = [
      contactLevelBlock(info.value)
      contactAvatar(info.value)
      contactNameBlock(contact.value, info.value)
      {
        size = flex()
      }
      responseAction
      onlineBlock(uid.tointeger(), onlineStatus, battleUnit)
    ]
  }
}

return mkContactRow