from "%globalsDarg/darg_library.nut" import *

let { get_mission_time } = require("mission")
let { eventbus_subscribe } = require("eventbus")
let { round } = require("math")
let { getMapRelativePlayerPos, getArtilleryRange, getArtilleryDispersion,
  callArtillery, artilleryCancel, onArtilleryClose
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

function updateData() {
  let { available = false, cooldownEndTime = 0
  } = getActionBarItems().findvalue(@(i) i.type == EII_ARTILLERY_TARGET)
  isArtilleryEnabled(available)
  isArtilleryReady(available && cooldownEndTime <= get_mission_time())
  let ap = getMapRelativePlayerPos()
  if (ap.len() >= 2 && (avatarPos.value[0] != ap[0] || avatarPos.value[1] != ap[1]))
    avatarPos(ap)
  artilleryRange(getArtilleryRange())
}

let dispersionRadius = Watched(-1.0)
let updateDispRadius = @(_) dispersionRadius(getArtilleryDispersion(mapCoords.value[0], mapCoords.value[1]))
mapCoords.subscribe(updateDispRadius)
isArtilleryReady.subscribe(updateDispRadius)
avatarPos.subscribe(updateDispRadius)
artilleryRange.subscribe(updateDispRadius)

let canCallArtillery = Computed(@() isArtilleryReady.value && dispersionRadius.value >= 0)

let rangeCircleSize = Computed(@() round(mapSizePx * artilleryRange.value).tointeger() * 2)
let rangeCirclePosX = Computed(@() round(mapSizePx * avatarPos.value[0] - rangeCircleSize.value / 2).tointeger())
let rangeCirclePosY = Computed(@() round(mapSizePx * avatarPos.value[1] - rangeCircleSize.value / 2).tointeger())

let crosshairPosX = Computed(@() round((1.0 * mapSizePx * mapCoords.value[0]) - (crosshairSizePx / 2)))
let crosshairPosY = Computed(@() round((1.0 * mapSizePx * mapCoords.value[1]) - (crosshairSizePx / 2)))
let crosshairCircleRadPx = Computed(@() dispersionRadius.value >= 0
  ? (round(1.0 * mapSizePx * dispersionRadius.value) + (crosshairLineWidth / 2))
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
  text = isArtilleryReady.value
    ? loc("artillery_strike/usage_info", { button = fireBtnText })
    : ""
})

let statusText = @() txtAreaBase.__merge({
  watch = [ canCallArtillery, isArtilleryEnabled, isArtilleryReady ]
  color = canCallArtillery.value ? goodTextColor : badTextColor
  text = loc(canCallArtillery.value ? "artillery_strike/allowed"
    : !isArtilleryEnabled.value ? "artillery_strike/crew_lost"
    : !isArtilleryReady.value ? "artillery_strike/not_ready"
    : "artillery_strike/not_allowed")
})

function atrilleryFire() {
  updateData()
  if (!canCallArtillery.value)
    return
  callArtillery(mapCoords.value[0], mapCoords.value[1])
  artilleryCancel()
}

let btnFire = @() {
  watch = canCallArtillery
  hplace = ALIGN_RIGHT
  children = canCallArtillery.value
    ? textButtonBattle(fireBtnText, atrilleryFire, { hotkeys = ["^J:X"] })
    : null
}

function mapShading() {
  let spaceT = rangeCirclePosY.value
  let spaceR = mapSizePx - rangeCirclePosX.value - rangeCircleSize.value
  let spaceB = mapSizePx - rangeCirclePosY.value - rangeCircleSize.value
  let spaceL = rangeCirclePosX.value
  return {
    watch = [ rangeCirclePosX, rangeCirclePosY, rangeCircleSize ]
    size = flex()
    clipChildren = true
    children = [
      bgShaded.__merge({
        size = [ rangeCircleSize.value, rangeCircleSize.value ]
        pos = [ rangeCirclePosX.value, rangeCirclePosY.value ]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin/map_radius.svg:{rangeCircleSize.value}:{rangeCircleSize.value}")
      })
      spaceT <= 0 ? null : bgShaded.__merge({
        size = [ mapSizePx, spaceT ]
        pos = [ 0, 0 ]
      })
      spaceB <= 0 ? null : bgShaded.__merge({
        size = [ mapSizePx, spaceB ]
        pos = [ 0, rangeCirclePosY.value + rangeCircleSize.value ]
      })
      spaceL <= 0 ? null : bgShaded.__merge({
        size = [ spaceL, rangeCircleSize.value ]
        pos = [ 0, rangeCirclePosY.value ]
      })
      spaceR <= 0 ? null : bgShaded.__merge({
        size = [ spaceR, rangeCircleSize.value ]
        pos = [ rangeCirclePosX.value + rangeCircleSize.value, rangeCirclePosY.value ]
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
  let color = canCallArtillery.value ? goodTextColor : badTextColor
  let mkCommandsFunc = canCallArtillery.value ? mkValidTargetDrawCommands : mkInvalidTargetDrawCommands
  let circleRadPrc = 100.0 * crosshairCircleRadPx.value / crosshairSizePx
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
  pos = [ crosshairPosX.value, crosshairPosY.value ]
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
