from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/subsPresentation.nut" import mkSubsIcon
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/profileStates.nut" import myUserName, myUserRealName
from "%appGlobals/squadState.nut" import isInSquad, squadId, isInvitedToSquad, squadMembers
from "%appGlobals/user/nickTools.nut" import getPlayerName
from "%rGui/components/levelBlockPkg.nut" import mkLevelBg
from "%rGui/components/starLevel.nut" import starLevelSmall
from "%rGui/style/stdColors.nut" import leaderColor, memberNotReadyColor, memberReadyColor, selectColor


let nameColor = selectColor
const titleColor = 0xFFFFFFFF
const darkenBgColor = 0x80000000

let onlineStatusColorsList = {
  in_battle = 0xFFDDA339
  offline = 0xFFFF4020
  online = 0xFF20E040
}

const borderWidth = hdpx(3)
const avatarSize = hdpxi(90)
let contactLevelSize = avatarSize * 0.8
let rowHeight = avatarSize + 2 * borderWidth
const gap = hdpx(10)
const premIconSize = hdpxi(25)


function contactNameBlock(contact, info, addChildren = [], styles = {}) {
  let { realnick } = contact
  let { decorators = {}, hasPremium = false, hasPrem = false, hasVip = false } = info
  let { nickFrame = null, title = null } = decorators
  let { nameStyle = fontTiny, titleStyle = fontTiny } = styles
  return {
    size = FLEX_V
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = [
      @() {
        watch = [myUserRealName, myUserName]
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        color = nameColor
        vplace = title || hasPremium ? ALIGN_TOP : ALIGN_CENTER
        text = frameNick(getPlayerName(realnick, myUserRealName.get(), myUserName.get()), nickFrame)
      }.__update(nameStyle)
      {
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap
        children = [
          !title ? null
            : {
                valign = ALIGN_BOTTOM
                rendObj = ROBJ_TEXT
                color = titleColor
                text = loc($"title/{title}")
              }.__update(titleStyle)
          !hasPremium ? null
            : mkSubsIcon(hasVip ? "vip"
                : hasPrem ? "prem"
                : "prem_deprecated",
              premIconSize)
        ]
      }
    ].extend(addChildren)
  }
}

function contactAvatar(info, size = avatarSize) {
  let { avatar = null } = info?.decorators
  return {
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(avatar)}:{size}:{size}:P")
  }
}

let levelBg = freeze(mkLevelBg())
let starLevelOvr = { pos = const [0, ph(45)] }
let levelMark = @(level, starLevel) {
  size = hdpx(40)
  margin = hdpx(10)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    levelBg
    {
      rendObj = ROBJ_TEXT
      text = level - starLevel
    }.__update(fontVeryTinyAccented)
    starLevelSmall(starLevel, starLevelOvr)
  ]
}

function contactLevelBlock(info, ovr = {}) {
  let { playerLevel = null, playerStarLevel = 0, playerStarHistoryLevel = 0 } = info
  let starAdd = max(0, playerStarHistoryLevel - playerStarLevel)
  return {
    size = [contactLevelSize, FLEX]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = playerLevel == null ? null : levelMark(playerLevel + starAdd, playerStarLevel + starAdd)
  }.__update(ovr)
}

function contactOnlineStatusBlock(onlineStatus, battleUnit) {
  let status = Computed(@() onlineStatus.get() == null ? ""
    : !onlineStatus.get() ? "offline"
    : battleUnit.get() != null ? "in_battle"
    : "online")

  return @() {
    watch = status
    size = hdpx(16)
    rendObj = ROBJ_BOX
    fillColor = onlineStatusColorsList?[status.get()] ?? 0x00000000
    borderRadius = hdpx(8)
  }
}

function contactSquadStatusBlock(uid, ovr = {}) {
  let squadText = Computed(@() !isInSquad.get() ? ""
    : squadId.get() == uid ? colorize(leaderColor, loc("status/squad_leader"))
    : squadMembers.get()?[uid].ready ? colorize(memberReadyColor, loc("status/squad_ready"))
    : uid in squadMembers.get() ? colorize(memberNotReadyColor, loc("status/squad_not_ready"))
    : isInvitedToSquad.get()?[uid] ? loc("status/squad_invited")
    : "")

  return @() {
    watch = squadText
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    maxWidth = hdpx(250)
    behavior = Behaviors.TextArea
    text = squadText.get()
  }.__update(fontTiny, ovr)
}

return {
  contactNameBlock
  contactAvatar
  contactLevelBlock
  contactOnlineStatusBlock
  contactSquadStatusBlock

  contactLevelSize
  darkenBgColor
  borderWidth
  avatarSize
  rowHeight
  gap
}