from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { round } = require("math")
let { get_time_msec } = require("dagor.time")
let { getMapRelativePlayerPos, getArtilleryRange, getArtilleryDispersion,
  callArtillery, artilleryCancel, onArtilleryClose
} = require("guiArtillery")
let { getActionBarItems } = require("hudActionBar")
local { EII_ARTILLERY_TARGET } = require("hudActionBarConst")
let { get_local_custom_settings_blk } = require("blkGetters")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { unitType } = require("%rGui/hudState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let backButton = require("%rGui/components/backButton.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textColor, goodTextColor, badTextColor } = require("%rGui/style/stdColors.nut")

// TODO: Remove this hack when artillery targeting on 3D-scene will be disabled in WTM:
isInBattle.subscribe(@(_) get_local_custom_settings_blk().artilleryTargettingUseMapFirst = null)

const DATA_UPDATE_TIMEOUT = 0.2
const SHORT_TAP_MSEC = 300
const DEV_GAMEPAD = 3

let mapSizePx = min(saSize[1], saSize[0] * 0.5625)
let crosshairSizePx = round(sh(25) / 2) * 2
let crosshairLineWidth = round(hdpx(8) / 2) * 2

subscribe("artilleryMapClose", @(_) onArtilleryClose())
subscribe("MissionResult", @(_) artilleryCancel())
subscribe("LocalPlayerDead", @(_) artilleryCancel())
unitType.subscribe(@(_) artilleryCancel())

let mapCoords = mkWatched(persist, "mapCoords", [ 0.5, 0.5 ])

let isArtilleryEnabled = Watched(false)
let isArtilleryReady = Watched(false)
let avatarPos = Watched([ 0.5, 0.5 ])
let artilleryRange = Watched(0.0)

let function updateData() {
  let { available = false, cooldownEndTime = 0
  } = getActionBarItems().findvalue(@(i) i.type == EII_ARTILLERY_TARGET)
  isArtilleryEnabled(available)
  isArtilleryReady(available && cooldownEndTime <= ::get_mission_time())
  let ap = getMapRelativePlayerPos()
  if (avatarPos.value[0] != ap[0] || avatarPos.value[1] != ap[1])
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
  size = [flex(), SIZE_TO_CONTENT]
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

let function atrilleryFire() {
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
    ? textButtonPrimary(fireBtnText, atrilleryFire, { hotkeys = ["^J:X"] })
    : null
}

let function mapShading() {
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

let function crosshairDrawing() {
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

let crosshair = @() {
  watch = [ crosshairPosX, crosshairPosY ]
  size = [ crosshairSizePx, crosshairSizePx ]
  pos = [ crosshairPosX.value, crosshairPosY.value ]
  children = crosshairDrawing
}

let defProcessorState = {
  pressTime = -1
  devId = null
  pointerId = null
  btnId = null
  targetW = null
  targetH = null
  mc = null
  x0 = 0
  y0 = 0
  x = 0
  y = 0
}
let processorState = Watched(clone defProcessorState)

let function onPointerPress(evt) {
  if (evt.accumRes & R_PROCESSED)
    return 0
  if (!evt.hit)
    return 0
  if (processorState.value.devId != null)
    return 0
  let x = evt.x - evt.target.getScreenPosX()
  let y = evt.y - evt.target.getScreenPosY()
  processorState(defProcessorState.__merge({
    pressTime = get_time_msec()
    devId = evt.devId
    pointerId = evt.pointerId
    btnId = evt.btnId
    targetW = evt.target.getWidth()
    targetH = evt.target.getHeight()
    mc = mapCoords.value
    x0 = x
    y0 = y
    x
    y
  }))
  return R_PROCESSED
}

let function onPointerRelease(evt) {
  let { devId, pointerId, btnId, pressTime, x, y, targetW, targetH } = processorState.value
  if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
    return 0
  if (get_time_msec() - pressTime <= SHORT_TAP_MSEC)
    mapCoords([
      clamp(x.tofloat() / targetW, 0.0, 1.0),
      clamp(y.tofloat() / targetH, 0.0, 1.0),
    ])
  processorState(clone defProcessorState)
  return R_PROCESSED
}

let function onPointerMove(evt) {
  let { devId, pointerId, btnId } = processorState.value
  let { target, x, y } = evt
  if (evt.devId == DEV_GAMEPAD) {
    let xs = x - target.getScreenPosX()
    let ys = y - target.getScreenPosY()
    mapCoords([
      clamp(xs.tofloat() / target.getWidth(), 0.0, 1.0),
      clamp(ys.tofloat() / target.getHeight(), 0.0, 1.0),
    ])
    return
  }

  if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
    return
  processorState.mutate(function(v) {
    v.x = x - target.getScreenPosX()
    v.y = y - target.getScreenPosY()
  })
}

processorState.subscribe(function(v) {
  if (v.devId != null)
    mapCoords([
      clamp(v.mc[0] + 1.0 * (v.x - v.x0) / v.targetW, 0.0, 1.0),
      clamp(v.mc[1] + 1.0 * (v.y - v.y0) / v.targetH, 0.0, 1.0),
    ])
})

let pointingInputProcessor = {
  key = {}
  size = flex()
  behavior = Behaviors.ProcessPointingInput
  onPointerPress
  onPointerRelease
  onPointerMove
  onDetach = @() processorState(clone defProcessorState)
}

let tacticalMap = {
  size = [ mapSizePx, mapSizePx ]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TACTICAL_MAP
  children = [
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
