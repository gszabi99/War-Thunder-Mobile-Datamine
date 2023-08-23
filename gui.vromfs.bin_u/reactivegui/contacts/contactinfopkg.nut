from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")

let nameColor = 0xFF00FCFF
let titleColor = 0xFFFFFFFF
let darkenBgColor = 0x80001521

let borderWidth = hdpx(3)
let avatarSize = hdpxi(90)
let rowHeight = avatarSize + 2 * borderWidth
let gap = hdpx(24)

let function contactNameBlock(contact, info, addChildren = []) {
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
    ].extend(addChildren)
  }
}

let function contactAvatar(info, size = avatarSize) {
  let { avatar = null } = info?.decorators
  return {
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(avatar)}:{size}:{size}:P")
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

let function contactLevelBlock(info) {
  let { playerLevel = null } = info
  return {
    size = [1.5 * avatarSize, flex()]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = playerLevel == null ? null
      : levelMark(playerLevel)
  }
}

return {
  contactNameBlock
  contactAvatar
  contactLevelBlock

  darkenBgColor
  borderWidth
  avatarSize
  rowHeight
  gap
}