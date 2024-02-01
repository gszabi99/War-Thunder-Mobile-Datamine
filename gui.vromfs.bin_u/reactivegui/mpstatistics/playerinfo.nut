from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { can_view_player_uids } = require("%appGlobals/permissions.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { calcPosition } = require("%rGui/tooltip.nut")
let { bgMessage, bgHeader } = require("%rGui/style/backgrounds.nut")

let selectedPlayerForInfo = Watched(null)

let textProps = {
    rendObj = ROBJ_TEXT
    fontFx = FFT_GLOW
    fontFxFactor = 48
    fontFxColor = 0xFF000000
    color = 0xFF69DADC
  }.__update(fontMediumShaded)

let mkTitle = @(title, ovr = {}) {
    rendObj = ROBJ_TEXT
    text = (title != null && title != "") ? loc($"title/{title}") : ""
  }.__update(ovr)

let starLevelOvr = { hplace = ALIGN_CENTER vplace = ALIGN_CENTER pos = [0, ph(30)] }
let levelMark = @(level, starLevel) {
  size = array(2, levelHolderSize)
  children = [
    mkLevelBg()
    {
      rendObj = ROBJ_TEXT
      text = level
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
    }.__update(fontSmall)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

function mkNameContent(player) {
  let title = player?.decorators.title
  let { level, starLevel = 0 } = player
  let res = {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = [
      {
        size = [avatarSize, avatarSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getAvatarImage(player?.decorators.avatar)}:{avatarSize}:{avatarSize}:P")
      }
      {
        valign = ALIGN_CENTER
        gap = hdpx(10)
        flow = FLOW_VERTICAL
        children = [
          textProps.__merge({
            text = player.name
          })
          mkTitle(title, fontTinyAccented)
        ]
      }
      levelMark(level - starLevel, starLevel)
    ]
  }
  return res
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTinyAccented)

let mkPlayerUidInfo = @(player) function() {
  let res = { watch = can_view_player_uids }
  if (!can_view_player_uids.get())
    return res
  let text = player?.isBot ? loc("multiplayer/state/bot_ready") : $"UID: {player?.userId} | {player?.realName}"
  return mkText(text).__update(res, { color = 0x80808080 })
}

function mkPlayerInfo(player) {
  let { userId = 0 } = player
  refreshPublicInfo(userId)
  let info = mkPublicInfo(userId)
  let medals = Computed(function() {
    let curr = info.get()?.campaigns?[curCampaign.get()] ?? {}
    return curr?.starLevelHistory ?? []
  })
  return bgMessage.__merge({
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    children = [
      bgHeader.__merge({
        size = [flex(), SIZE_TO_CONTENT]
        padding = hdpx(15)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {rendObj = ROBJ_TEXT text = loc("mainmenu/titlePlayerProfile")}.__update(fontSmallAccented)
      })
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = [hdpx(40), hdpx(80), hdpx(40), hdpx(80)]
        gap = hdpx(30)
        children = [
          mkNameContent(player)
          @() {
            watch = [medals]
            valign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children = medals.get().len() > 0
              ? [
                  mkText(loc("mainmenu/btnMedal"))
                  {
                    valign = ALIGN_CENTER
                    flow = FLOW_HORIZONTAL
                    gap = hdpx(30)
                    children = medals.get().map(@(v) levelMark(v.level, v.starLevel + 1))
                  }
                ]
              : mkText(loc("mainmenu/noMedal"))
          }
          mkPlayerUidInfo(player)
        ]
      }
    ]
  })
}

let key = "playerInfo"
selectedPlayerForInfo.subscribe(function(v) {
  removeModalWindow(key)
  if (v == null)
    return
  let position = calcPosition(gui_scene.getCompAABBbyKey(selectedPlayerForInfo.get().userId), FLOW_VERTICAL, hdpx(20), ALIGN_CENTER, ALIGN_CENTER)
  addModalWindow({
    key
    animations = appearAnim(0, 0.2)
    onClick = @() selectedPlayerForInfo(null)
    sound = { click  = "click" }
    size = [sw(100), sh(100)]
    children = position.__merge({
      size = [0, 0]
      children = {
        size = SIZE_TO_CONTENT
        transform = {}
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkPlayerInfo(selectedPlayerForInfo.get())
      }
    })
  })
})

return {
  selectedPlayerForInfo
  mkPlayerInfo
}
