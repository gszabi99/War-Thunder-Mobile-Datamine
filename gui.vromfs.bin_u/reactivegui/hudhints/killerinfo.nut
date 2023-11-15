from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { HUD_MSG_MULTIPLAYER_DMG } = require("hudMessages")
let { get_unittags_blk } = require("blkGetters")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { localMPlayerId } = require("%appGlobals/clientState/clientState.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { rqPlayerAndDo } = require("rqPlayersAndDo.nut")
let { isUnitAlive } = require("%rGui/hudState.nut")
let { playersCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { playerLevelInfo, allUnitsCfgFlat } = require("%appGlobals/pServer/profile.nut")
let { mkGradientBlock, failBgColor } = require("hintCtors.nut")
let { mkSingleUnitPlate, unitPlateWidth } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let hudMessagesUnitTypesMap = require("hudMessagesUnitTypesMap.nut")
let unitFake = require("%rGui/unit/unitFake.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")

let premIconSize = hdpxi(56)
let gradPadding = hdpx(100)

let killData = mkWatched(persist, "killData", null)
isUnitAlive.subscribe(@(v) v ? killData(null) : null)

let mkFakeUnitCfg = @(name, hudMsgUnitType, country) unitFake.__merge({
  name
  country
  unitType = hudMessagesUnitTypesMap?[hudMsgUnitType] ?? ""
})

let info = Computed(function() {
  if (killData.value == null)
    return null
  let { killer, unitName, unitType } = killData.value
  let finalOverride = { name = unitName }
  local unitCfg = allUnitsCfgFlat.value?[unitName]
  if (unitCfg == null && unitName in get_unittags_blk()) {
    unitCfg = mkFakeUnitCfg(unitName, unitType, killer.country)
    finalOverride.__update({ mRank = -1, rank = -1, level = -1 })
  }
  if (unitCfg == null) {
    logerr($"Player killed by unknown unit {unitName}, unitType = {unitType}") // AI unit?
    return null
  }
  let defLevel = playerLevelInfo.value.level
  let cStats = killer.isBot ? genBotCommonStats(killer.name, unitName, unitCfg, defLevel)
    : playersCommonStats.value?[killer.userId.tointeger()]
  return killData.value.__merge({
    killerHasPremium = cStats?.hasPremium ?? false
    killerLevel = cStats?.level ?? 1
    killerAvatar = cStats?.decorators.avatar
    killerUnit = (unitCfg).__merge(cStats?.unit ?? {}, finalOverride)
  })
})

subscribe("HudMessage", function(data) {
  if (data.type != HUD_MSG_MULTIPLAYER_DMG)
    return
  let { isKill = false, playerId = null, victimPlayerId = null } = data
  if (isKill && localMPlayerId.value == victimPlayerId)
    rqPlayerAndDo(playerId, @(killer) killer == null ? null
      : killData(data.__merge({ killer })))
})

let mkText = @(text, style = fontMedium, color = 0xFFFFFFFF) {
  rendObj = ROBJ_TEXT
  text
  color
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(style)

let fontByPlateWidth = @(text) calc_str_box(text, fontSmall)[0] > unitPlateWidth
  ? fontSmall : fontMedium

let levelMark = @(text) {
  size = array(2, hdpx(60))
  margin = hdpx(10)
  children = [
    mkLevelBg()
    {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      pos = [0, -hdpx(2)]
      text
    }.__update(fontSmall)
  ]
}

let premiumMark = {
  size = [premIconSize, premIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconSize}:{premIconSize}:K:P")
}

let function hintContent(infoV) {
  let { killerUnit, killerHasPremium, killerLevel, killer, killerAvatar } = infoV
  let name = getPlayerName(killer.name)
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(20)
        children = [
          levelMark(killerLevel)
          {
            flow = FLOW_VERTICAL
            gap = -hdpx(8)
            children = [
              mkText(loc("hud/killer"), fontTiny, 0xA0A0A0A0)
              mkText(name, fontByPlateWidth(name))
            ]
          }
          killerHasPremium ? premiumMark : null
          {
            size = [hdpxi(150), hdpxi(150)]
            rendObj = ROBJ_IMAGE
            image = Picture($"{getAvatarImage(killerAvatar)}:{hdpxi(150)}:{hdpxi(150)}:P")
          }
        ]
      }
      { size = [0, hdpx(20)] }
      mkSingleUnitPlate(killerUnit)
    ]
  }
}

let key = {}
let function killerInfo() {
  if (info.value == null)
    return { watch = info }

  let content = hintContent(info.value)
  return {
    watch = info
    key
    hplace = ALIGN_RIGHT
    pos = [gradPadding, 0]
    children = mkGradientBlock(failBgColor, content, calc_comp_size(content)[0] + 2 * gradPadding)
  }
}

return killerInfo