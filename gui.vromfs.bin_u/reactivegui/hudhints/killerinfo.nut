from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_unittags_blk
from "hudMessages" import HUD_MSG_MULTIPLAYER_DMG
from "mission" import get_mplayer_by_id
from "%appGlobals/botUtils.nut" import genBotCommonStats
from "%appGlobals/clientState/clientState.nut" import localMPlayerId
from "%appGlobals/clientState/missionState.nut" import battleCampaign
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/unitCfgByTagName.nut" import getUnitCfgByTagName
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hudHints/hintCtors.nut" import mkGradientBlock, failBgColor
import "%rGui/hudHints/hudMessagesUnitTypesMap.nut" as hudMessagesUnitTypesMap
from "%rGui/hudState.nut" import isUnitAlive
from "%rGui/mpStatistics/playersCommonStats.nut" import playersCommonStats
from "%rGui/unit/components/unitPlateComp.nut" import mkSingleUnitPlate, unitPlateWidth
import "%rGui/unit/unitFake.nut" as unitFake


const premIconSize = hdpxi(56)
const gradPadding = hdpx(100)

let killData = mkWatched(persist, "killData", null)
isUnitAlive.subscribe(@(v) v ? killData.set(null) : null)

let mkFakeUnitCfg = @(name, hudMsgUnitType, country) unitFake.__merge({
  name
  country
  unitType = hudMessagesUnitTypesMap?[hudMsgUnitType] ?? ""
  mRank = -1
  rank = -1
  level = -1
})

let info = Computed(function() {
  if (killData.get() == null)
    return null
  let { killer, unitName, unitType } = killData.get()
  if (unitName == "")
    return 
  local unitCfg = getUnitCfgByTagName(unitName, serverConfigs.get(), battleCampaign.get())
  if (unitCfg == null && unitName in get_unittags_blk())
    unitCfg = mkFakeUnitCfg(unitName, unitType, killer.country)
  if (unitCfg == null)
    return null
  let cStats = killer.isBot ? genBotCommonStats(killer.name, unitName, unitCfg, 0)
    : playersCommonStats.get()?[killer.userId.tointeger()]
  let { hasPremium = false, decorators = null, units = null, hasVip = false, hasPrem = false } = cStats
  return killData.get().__merge({
    killerHasPremium = hasPremium || hasPrem || hasVip
    killerAvatar = decorators?.avatar
    killerUnit = unitCfg.__merge(units?[unitName] ?? {})
  })
})

subscribeHudEvent("HudMessage", function(data) {
  if (data.type != HUD_MSG_MULTIPLAYER_DMG)
    return
  let { isKill = false, playerId = null, victimPlayerId = null } = data
  if (isKill && localMPlayerId.get() == victimPlayerId) {
    let killer = get_mplayer_by_id(playerId)
    if (killer != null)
      killData.set(data.__merge({ killer }))
  }
})

let mkText = @(text, style = fontMediumShaded, color = 0xFFFFFFFF) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(style)

let fontByPlateWidth = @(text) calc_str_box(text, fontSmall)[0] > unitPlateWidth
  ? fontSmallShaded : fontMediumShaded

let premiumMark = {
  size = const [premIconSize, premIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconSize}:{premIconSize}:K:P")
}

function hintContent(infoV) {
  let { killerUnit, killerHasPremium, killer, killerAvatar } = infoV
  let name = killer.name
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(20)
        children = [
          {
            flow = FLOW_VERTICAL
            gap = -hdpx(8)
            children = [
              mkText(loc("hud/killer"), fontTinyShaded, 0xA0A0A0A0)
              mkText(name, fontByPlateWidth(name))
            ]
          }
          killerHasPremium ? premiumMark : null
          {
            size = hdpxi(150)
            rendObj = ROBJ_IMAGE
            image = Picture($"{getAvatarImage(killerAvatar)}:{hdpxi(150)}:{hdpxi(150)}:P")
          }
        ]
      }
      { size = const [0, hdpx(20)] }
      mkSingleUnitPlate(killerUnit)
    ]
  }
}

let key = {}
function killerInfo() {
  if (info.get() == null)
    return { watch = info }

  let content = hintContent(info.get())
  return {
    watch = info
    key
    hplace = ALIGN_RIGHT
    pos = const [gradPadding, 0]
    children = mkGradientBlock(failBgColor, content, calc_comp_size(content)[0] + 2 * gradPadding)
  }
}


let hudKillerInfo = @() {
  watch = isUnitAlive
  size = FLEX
  children = isUnitAlive.get() ? null : killerInfo
}

return { killerInfo, hudKillerInfo }
