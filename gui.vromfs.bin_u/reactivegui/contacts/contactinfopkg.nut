from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkSubsIcon } = require("%appGlobals/config/subsPresentation.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelSmall } = require("%rGui/components/starLevel.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")

let nameColor = selectColor
let titleColor = 0xFFFFFFFF
let darkenBgColor = 0x80001521

let borderWidth = hdpx(3)
let avatarSize = hdpxi(90)
let contactLevelSize = avatarSize * 1.1
let rowHeight = avatarSize + 2 * borderWidth
let gap = hdpx(10)
let premIconSize = hdpxi(30)


function contactNameBlock(contact, info, addChildren = [], styles = {}) {
  let { realnick } = contact
  let { decorators = {}, hasPremium = false, hasPrem = false, hasVip = false } = info
  let { nickFrame = null, title = null } = decorators
  let { nameStyle = fontTiny, titleStyle = fontTiny } = styles
  return {
    size = FLEX_V
    flow = FLOW_VERTICAL
    children = [
      {
        size = FLEX_V
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          @() {
            watch = [myUserRealName, myUserName]
            size = FLEX_V
            valign = ALIGN_CENTER
            rendObj = ROBJ_TEXT
            color = nameColor
            text = frameNick(getPlayerName(realnick, myUserRealName.get(), myUserName.get()), nickFrame)
          }.__update(nameStyle)
          !hasPremium ? null
            : mkSubsIcon(
              hasVip ? "vip"
                : hasPrem ? "prem"
                : "prem_deprecated",
              premIconSize)
        ]
      }
      {
        size = FLEX_V
        valign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = titleColor
        text = title == null ? null
          : loc($"title/{title}")
      }.__update(titleStyle)
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
let starLevelOvr = { pos = [0, ph(45)] }
let levelMark = @(level, starLevel) {
  size = array(2, hdpx(60))
  margin = hdpx(10)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    levelBg
    {
      rendObj = ROBJ_TEXT
      pos = [0, -hdpx(2)]
      text = level - starLevel
    }.__update(fontSmall)
    starLevelSmall(starLevel, starLevelOvr)
  ]
}

function contactLevelBlock(info) {
  let { playerLevel = null, playerStarLevel = 0, playerStarHistoryLevel = 0 } = info
  let starAdd = max(0, playerStarHistoryLevel - playerStarLevel)
  return {
    size = [contactLevelSize, flex()]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = playerLevel == null ? null : levelMark(playerLevel + starAdd, playerStarLevel + starAdd)
  }
}

return {
  contactNameBlock
  contactAvatar
  contactLevelBlock

  contactLevelSize
  darkenBgColor
  borderWidth
  avatarSize
  rowHeight
  gap
}