from "%globalsDarg/darg_library.nut" import *

let { get_mission_time, get_current_mission_name } = require("mission")
let { eventbus_subscribe } = require("eventbus")
let { round } = require("math")
let { getBattleAreaSize } = require("guiTacticalMap")
let { getMapRelativePlayerPos, getArtilleryRange, getArtilleryDispersion,
  callArtillery, artilleryCancel, onArtilleryClose,
  isSuperArtilleryMode = @() get_current_mission_name().endswith("_BR"),
  getSuperArtilleryRadius = function() {
    let misName = get_current_mission_name()
    if (!misName.endswith("_BR"))
      return 0.0
    let radM = { abandoned_factory_BR = 100, africa_desert_BR = 150,
      cargo_port_BR = 150, stalingrad_factory_BR = 200 }?[misName] ?? 100
    let mapSizeM = getBattleAreaSize().x
    return mapSizeM == 0 ? 0.0 : (radM / mapSizeM)
  }
} = require("guiArtillery")
let { getActionBarItems } = require("hudActionBar")
local { EII_ARTILLERY_TARGET } = require("hudActionBarConst")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { unitType } = require("%rGui/hudState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textColor, goodTextColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { tacticalMapMarkersLayer } = require("%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut")
let mkTacticalMapPointingInputProcessor = require("%rGui/hud/tacticalMap/tacticalMapPointingProcessor.nut")

const DATA_UPDATE_TIMEOUT = 0.2

let mapSizePx = min(saSize[1], saSize[0] * 0.5625)
let crosshairSizePx = round(sh(25) / 2) * 2
let crosshairLineWidth = round(hdpx(8) / 2) * 2

eventbus_subscribe("artilleryMapClose", @(_) onArtilleryClose())
eventbus_subscribe("MissionResult", @(_) artilleryCancel())
eventbus_subscribe("LocalPlayerDead", @(_) artilleryCancel())
unitType.subscribe(@(_) artilleryCancel())

let mapCoords = mkWatched(persist, "mapCoords", [ 0.5, 0.5 ])

let isArtilleryEnabled = Watched(false)
let isArtilleryReady = Watched(false)
let avatarPos = Watched([ 0.5, 0.5 ])
let artilleryRange = Watched(0.0)
let isSuperArtillery = Watched(false)
let superArtilleryRadius = Watched(0.0)

function updateData() {
  let { available = false, cooldownEndTime = 0
  } = getActionBarItems().findvalue(@(i) i.type == EII_ARTILLERY_TARGET)
  isArtilleryEnabled.set(available)
  isArtilleryReady.set(available && cooldownEndTime <= get_mission_time())
  let ap = getMapRelativePlayerPos()
  if (ap.len() >= 2 && (avatarPos.get()[0] != ap[0] || avatarPos.get()[1] != ap[1]))
    avatarPos.set(ap)
  artilleryRange.set(getArtilleryRange())
  isSuperArtillery.set(isSuperArtilleryMode())
  superArtilleryRadius.set(getSuperArtilleryRadius())
}

let dispersionRadius = Watched(-1.0)
function updateDispRadius(_) {
  local radius = getArtilleryDispersion(mapCoords.get()[0], mapCoords.get()[1])
  if (radius > 0 && isSuperArtillery.get())
    radius = superArtilleryRadius.get()
  dispersionRadius.set(radius)
}
mapCoords.subscribe(updateDispRadius)
isArtilleryReady.subscribe(updateDispRadius)
avatarPos.subscribe(updateDispRadius)
artilleryRange.subscribe(updateDispRadius)

let canCallArtillery = Computed(@() isArtilleryReady.get() && dispersionRadius.get() >= 0)

let rangeCircleSize = Computed(@() round(mapSizePx * artilleryRange.get()).tointeger() * 2)
let rangeCirclePosX = Computed(@() round(mapSizePx * avatarPos.get()[0] - rangeCircleSize.get() / 2).tointeger())
let rangeCirclePosY = Computed(@() round(mapSizePx * avatarPos.get()[1] - rangeCircleSize.get() / 2).tointeger())

let crosshairPosX = Computed(@() round((1.0 * mapSizePx * mapCoords.get()[0]) - (crosshairSizePx / 2)))
let crosshairPosY = Computed(@() round((1.0 * mapSizePx * mapCoords.get()[1]) - (crosshairSizePx / 2)))
let crosshairCircleRadPx = Computed(@() dispersionRadius.get() >= 0
  ? (round(1.0 * mapSizePx * dispersionRadius.get()) + (crosshairLineWidth / 2))
  : 0)

let cornerBackBtn = backButton(artilleryCancel)

let txtAreaBase = {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = textColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(32)
  fontFxColor = 0xFF000000
}.__update(fontSmall)

let wndTitle = txtAreaBase.__merge(fontBig, {
  text = loc("actionBarItem/artillery_target")
  fontFxFactor = hdpx(64)
})

let fireBtnText = utf8ToUpper(loc("hints/duel_battle_fire"))

let usageInfoText = @() txtAreaBase.__merge({
  watch = isArtilleryReady
  text = isArtilleryReady.get()
    ? loc("artillery_strike/usage_info", { button = fireBtnText })
    : ""
})

let statusText = @() txtAreaBase.__merge({
  watch = [ canCallArtillery, isArtilleryEnabled, isArtilleryReady ]
  color = canCallArtillery.get() ? goodTextColor : badTextColor
  text = loc(canCallArtillery.get() ? "artillery_strike/allowed"
    : !isArtilleryEnabled.get() ? "artillery_strike/crew_lost"
    : !isArtilleryReady.get() ? "artillery_strike/not_ready"
    : "artillery_strike/not_allowed")
})

function atrilleryFire() {
  updateData()
  if (!canCallArtillery.get())
    return
  callArtillery(mapCoords.get()[0], mapCoords.get()[1])
  artilleryCancel()
}

let btnFire = @() {
  watch = canCallArtillery
  hplace = ALIGN_RIGHT
  children = canCallArtillery.get()
    ? textButtonBattle(fireBtnText, atrilleryFire, { hotkeys = ["^J:X"] })
    : null
}

function mapShading() {
  if (isSuperArtillery.get())
    return { watch = isSuperArtillery }
  let spaceT = rangeCirclePosY.get()
  let spaceR = mapSizePx - rangeCirclePosX.get() - rangeCircleSize.get()
  let spaceB = mapSizePx - rangeCirclePosY.get() - rangeCircleSize.get()
  let spaceL = rangeCirclePosX.get()
  return {
    watch = [ isSuperArtillery, rangeCirclePosX, rangeCirclePosY, rangeCircleSize ]
    size = flex()
    clipChildren = true
    children = [
      bgShaded.__merge({
        size = [ rangeCircleSize.get(), rangeCircleSize.get() ]
        pos = [ rangeCirclePosX.get(), rangeCirclePosY.get() ]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin/map_radius.svg:{rangeCircleSize.get()}:{rangeCircleSize.get()}")
      })
      spaceT <= 0 ? null : bgShaded.__merge({
        size = [ mapSizePx, spaceT ]
        pos = [ 0, 0 ]
      })
      spaceB <= 0 ? null : bgShaded.__merge({
        size = [ mapSizePx, spaceB ]
        pos = [ 0, rangeCirclePosY.get() + rangeCircleSize.get() ]
      })
      spaceL <= 0 ? null : bgShaded.__merge({
        size = [ spaceL, rangeCircleSize.get() ]
        pos = [ 0, rangeCirclePosY.get() ]
      })
      spaceR <= 0 ? null : bgShaded.__merge({
        size = [ spaceR, rangeCircleSize.get() ]
        pos = [ rangeCirclePosX.get() + rangeCircleSize.get(), rangeCirclePosY.get() ]
      })
    ]
  }
}

let mkValidTargetDrawCommands = @(color, width, cr) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_LINE, 50, 0, 50, 50 - cr],
  [VECTOR_LINE, 100, 50, 50 + cr, 50],
  [VECTOR_LINE, 50, 100, 50, 50 + cr],
  [VECTOR_LINE, 0, 50, 50 - cr, 50],
  [VECTOR_ELLIPSE, 50, 50, cr, cr],
]

let mkInvalidTargetDrawCommands = @(color, width, _) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_LINE, 0, 50, 100, 50],
  [VECTOR_LINE, 50, 0, 50, 100],
]

function crosshairDrawing() {
  let color = canCallArtillery.get() ? goodTextColor : badTextColor
  let mkCommandsFunc = canCallArtillery.get() ? mkValidTargetDrawCommands : mkInvalidTargetDrawCommands
  let circleRadPrc = 100.0 * crosshairCircleRadPx.get() / crosshairSizePx
  return {
    watch = [ canCallArtillery, crosshairCircleRadPx ]
    size = [ crosshairSizePx, crosshairSizePx ]
    rendObj = ROBJ_VECTOR_CANVAS
    fillColor = 0
    commands = [].extend(
      mkCommandsFunc(0x40000000, crosshairLineWidth + hdpx(6), circleRadPrc),
      mkCommandsFunc(0x40000000, crosshairLineWidth + hdpx(4), circleRadPrc),
      mkCommandsFunc(0xFF000000, crosshairLineWidth + hdpx(2), circleRadPrc),
      mkCommandsFunc(color, crosshairLineWidth, circleRadPrc))
  }
}

let pointingInputProcessor = mkTacticalMapPointingInputProcessor(mapCoords)

let crosshair = @() {
  watch = [ crosshairPosX, crosshairPosY ]
  size = [ crosshairSizePx, crosshairSizePx ]
  pos = [ crosshairPosX.get(), crosshairPosY.get() ]
  children = crosshairDrawing
}

let tacticalMap = {
  size = [ mapSizePx, mapSizePx ]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TACTICAL_MAP
  children = [
    tacticalMapMarkersLayer
    mapShading
    crosshair
    pointingInputProcessor
  ]
}

return bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  gap = hdpx(100)
  onAttach = @() gui_scene.setInterval(DATA_UPDATE_TIMEOUT, updateData)
  onDetach = @() gui_scene.clearTimer(updateData)
  children = [
    cornerBackBtn
    tacticalMap
    {
      size = [ flex(), mapSizePx ]
      vplace = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        {
          size = flex()
          flow = FLOW_VERTICAL
          gap = hdpx(50)
          children = [
            wndTitle
            usageInfoText
            statusText
          ]
        }
        btnFire
      ]
    }
  ]
  animations = wndSwitchAnim
})
