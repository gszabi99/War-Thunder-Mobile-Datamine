from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { Contact } = require("contact.nut")
let { mkPublicInfo, refreshPublicInfo } = require("contactPublicInfo.nut")
let { mkContactOnlineStatus } = require("contactPresence.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")

let borderWidth = hdpx(3)
let avatarSize = hdpxi(90)
let rowHeight = avatarSize + 2 * borderWidth
let gap = hdpx(24)

let nameColor = 0xFF00FCFF
let titleColor = 0xFFFFFFFF
let onlineColor = 0xFFFFFFFF
let offlineColor = 0xFFFF4020
let darkenBgColor = 0x80001521

let function nameBlock(contact, info) {
  let { nickFrame = null, title = null } = info?.decorators
  return {
    size = flex()
    flow = FLOW_VERTICAL
    children = [
      {
        size = [SIZE_TO_CONTENT, flex()]
        valign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = nameColor
        text = frameNick(getPlayerName(contact.realnick), nickFrame)
      }.__update(fontTiny)
      {
        size = [SIZE_TO_CONTENT, flex()]
        valign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = titleColor
        text = title == null ? null
          : loc($"title/{title}")
      }.__update(fontTiny)
    ]
  }
}

let emptyAvatar = freeze({
  size = [avatarSize, avatarSize]
  rendObj = ROBJ_SOLID
  color = 0x80000000
})

let function avatar(info) {
  let { campaigns = null } = info
  if (campaigns == null)
    return emptyAvatar
  let { ships = 0, tanks = 0 } = campaigns
  let image = ships > tanks ? "cardicon_default" : "cardicon_tanker"
  return {
    size = [avatarSize, avatarSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/avatars/{image}.avif")
  }
}

let levelBg = freeze(mkLevelBg())
let levelMark = @(text) {
  size = array(2, hdpx(60))
  margin = hdpx(10)
  children = [
    levelBg
    {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      pos = [0, -hdpx(2)]
      text
    }.__update(fontSmall)
  ]
}

let function levelBlock(info) {
  let { playerLevel = null } = info
  return {
    size = [1.5 * avatarSize, flex()]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = playerLevel == null ? null
      : levelMark(playerLevel)
  }
}

let onlineBlock = @(onlineStatus) @() onlineStatus.value == null ? { watch = onlineStatus }
  : {
      watch = onlineStatus
      size = [1.5 * avatarSize, flex()]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXT
        color = onlineStatus.value ? onlineColor : offlineColor
        text = onlineStatus.value ? loc("contacts/online") : loc("contacts/offline")
      }.__update(fontVeryTiny)
    }

let function mkContactRow(uid, rowIdx, isSelected, onClick) {
  let userId = uid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  let onlineStatus = mkContactOnlineStatus(userId)
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
      levelBlock(info.value)
      avatar(info.value)
      nameBlock(contact.value, info.value)
      onlineBlock(onlineStatus)
    ]
  }
}

return mkContactRow