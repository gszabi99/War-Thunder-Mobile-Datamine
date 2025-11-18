from "%globalsDarg/darg_library.nut" import *
let { pow, fabs, round } = require("math")
let { get_mp_local_team } = require("mission")
let { eventbus_subscribe } = require("eventbus")
let { Point2 } = require("dagor.math")
let { mapPosToWorldPos } = require("guiTacticalMap")
let { getMapRelativePlayerPos } = require("guiArtillery")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { unitType } = require("%rGui/hudState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { tacticalMapMarkersLayer } = require("%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut")
let mkTacticalMapPointingInputProcessor = require("%rGui/hud/tacticalMap/tacticalMapPointingProcessor.nut")
let { capZones } = require("%rGui/hud/capZones/capZonesState.nut")
let { sendVoiceMsgById } = require("%rGui/hud/voiceMsg/voiceMsgState.nut")
let { markMinimapVoiceMsgFeatureKnown } = require("%rGui/hud/voiceMsg/hudVoiceMsgMapHint.nut")
let { hudWhiteColor, hudBlackColor, hudTransparentBlackColor, hudBlueColor } = require("%rGui/style/hudColors.nut")

enum MAP_OBJ_TYPE {
  NONE
  CAPTURE_ZONE
}

let headerGap = hdpx(40)
let mapSizePx = min(saSize[1] - backButtonHeight - headerGap, saSize[0] - hdpx(700))
let objectSnapRadiusSq = pow(hdpx(20) / mapSizePx, 2)
let pointerObjectPickerSizePx = evenPx(70)
let pointerCoordsPickerSizePx = evenPx(58)
let pointerLineWidth = round(hdpx(8) / 2) * 2

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)

let mapCoords = mkWatched(persist, "mapCoords", [ 0.5, 0.5 ])

isInBattle.subscribe(@(_) close())
eventbus_subscribe("MissionResult", @(_) close())
eventbus_subscribe("LocalPlayerDead", @(_) close())
unitType.subscribe(@(_) @(_) close())

let relPosToToUiPos = @(pos) pos == null ? null : pos.map(@(v) round(v * mapSizePx))
let relPosToWorldPos = @(coords) mapPosToWorldPos(Point2(coords[0], coords[1]))
let getDistanceSq = @(p1, p2) pow(fabs(p1[0] - p2[0]), 2) + pow(fabs(p1[1] - p2[1]), 2)

function sendMsgAndClose(msgId, worldCoords) {
  sendVoiceMsgById(msgId, worldCoords)
  close()
}

let actionBtnsCtors = {
  [MAP_OBJ_TYPE.NONE] = function(_obj, coordsW) {
    let msgId = "attention_to_point"
    return textButtonPrimary(utf8ToUpper(loc($"voice_message_{msgId}_0")),
      @() sendMsgAndClose(msgId, relPosToWorldPos(coordsW.get())))
  },
  [MAP_OBJ_TYPE.CAPTURE_ZONE] = function(mapObj, _coordsW) {
    let { team, iconIdx, mapPos } = mapObj
    let shouldAttack = team != get_mp_local_team()
    let attackBtnCtor = shouldAttack ? textButtonPrimary : textButtonCommon
    let defendBtnCtor = shouldAttack ? textButtonCommon : textButtonPrimary
    let zoneLetter = ('A'.tointeger() + iconIdx).tochar()
    let attackMsgId = $"attack_{zoneLetter}"
    let defendMsgId = $"defend_{zoneLetter}"
    let attackText = utf8ToUpper(loc($"voice_message_{attackMsgId}_0"))
    let defendText = utf8ToUpper(loc($"voice_message_{defendMsgId}_0"))
    let btnTxtWidths = [attackText, defendText].map(@(text) calc_comp_size({
        rendObj = ROBJ_TEXT
        text
      }.__update(fontSmallAccentedShaded))[0] + defButtonHeight)
    let btnWidth = max(defButtonMinWidth, btnTxtWidths[0], btnTxtWidths[1])
    let btnStyleOvr = { ovr = { size = [btnWidth, defButtonHeight] }, useFlexText = true }
    return [
      attackBtnCtor(attackText, @() sendMsgAndClose(attackMsgId, relPosToWorldPos(mapPos)), btnStyleOvr)
      defendBtnCtor(defendText, @() sendMsgAndClose(defendMsgId, relPosToWorldPos(mapPos)), btnStyleOvr)
    ]
  },
}

let selectedObject = Computed(function() {
  let objects = capZones.get()
  if (objects.len() == 0)
    return null
  let targetPos = mapCoords.get()
  let objDistances = objects
    .map(@(v, idx) { idx, distSq = getDistanceSq(targetPos, v.mapPos) })
    .sort(@(a, b) a.distSq <=> b.distSq)
  return objDistances[0].distSq < objectSnapRadiusSq
    ? objects[objDistances[0].idx].__merge({ mapObjType = MAP_OBJ_TYPE.CAPTURE_ZONE })
    : null
})

function reinit() {
  let zones = capZones.get()
  let myPos = getMapRelativePlayerPos()
  if (myPos.len() == 0)
    myPos.append(0.5, 0.5)
  if (zones.len() == 0) {
    mapCoords.set(myPos)
    return
  }
  let myTeam = get_mp_local_team()
  let enemyTeam = myTeam == 2 ? 1 : 2
  let zonesOnProgress = zones.filter(@(v) fabs(v.progress) < 100.0).sort(@(a, b) a.progress <=> b.progress)
  let zonesLosing = zonesOnProgress.filter(@(v) v.team == myTeam && v.conqTeam == enemyTeam)
  let bestZone = zonesLosing?[0] ?? zonesOnProgress?[0]
  if (bestZone != null) {
    mapCoords.set(bestZone.mapPos)
    return
  }
  let zoneDistances = zones
    .map(@(v, idx) { idx, distSq = getDistanceSq(myPos, v.mapPos) })
    .sort(@(a, b) a.distSq <=> b.distSq)
  mapCoords.set(zones[zoneDistances[0].idx].mapPos)
}

isOpened.subscribe(function(v) {
  if (!v)
    return
  reinit()
  markMinimapVoiceMsgFeatureKnown()
})

let txtAreaBase = {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = hudWhiteColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(32)
  fontFxColor = hudBlackColor
}.__update(fontSmall)

let wndTitle = txtAreaBase.__merge(fontBig, {
  text = loc("hotkeys/ID_SHOW_VOICE_MESSAGE_LIST")
  fontFxFactor = hdpx(64)
})

let usageInfoText = txtAreaBase.__merge({
  text = loc("radio_message/tactical_map/usage_info")
})

let mkObjectPickerDrawCommands = @(color, width) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_LINE, 50, 0, 100, 50],
  [VECTOR_LINE, 100, 50, 50, 100],
  [VECTOR_LINE, 50, 100, 0, 50],
  [VECTOR_LINE, 0, 50, 50, 0],
]

let mkCoordsPickerDrawCommands = @(color, width) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_ELLIPSE, 50, 50, 50, 50],
]

function crosshairDrawing() {
  let mkCommandsFunc = selectedObject.get() != null ? mkObjectPickerDrawCommands : mkCoordsPickerDrawCommands
  let pointerSize = selectedObject.get() != null ? pointerObjectPickerSizePx : pointerCoordsPickerSizePx
  return {
    watch = selectedObject
    size = [ pointerSize, pointerSize ]
    rendObj = ROBJ_VECTOR_CANVAS
    fillColor = 0
    commands = [].extend(
      mkCommandsFunc(hudTransparentBlackColor, pointerLineWidth + hdpx(6)),
      mkCommandsFunc(hudTransparentBlackColor, pointerLineWidth + hdpx(4)),
      mkCommandsFunc(hudBlackColor, pointerLineWidth + hdpx(2)),
      mkCommandsFunc(hudBlueColor, pointerLineWidth))
  }
}

let crosshairPos = Computed(@() relPosToToUiPos(selectedObject.get()?.mapPos)
  ?? mapCoords.get().map(@(v) round(1.0 * mapSizePx * v)))

let crosshair = @() {
  watch = crosshairPos
  size = 0
  pos = crosshairPos.get()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = crosshairDrawing
}

let pointingInputProcessor = mkTacticalMapPointingInputProcessor(mapCoords)

let tacticalMap = {
  size = [ mapSizePx, mapSizePx ]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TACTICAL_MAP
  children = [
    tacticalMapMarkersLayer
    crosshair
    pointingInputProcessor
  ]
}

let content = {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = hdpx(100)
  children = [
    tacticalMap
    {
      size = flex()
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(56)
      children = [
        wndTitle
        usageInfoText
        @() {
          watch = selectedObject
          flow = FLOW_VERTICAL
          gap = hdpx(56)
          children = actionBtnsCtors?[selectedObject.get()?.mapObjType ?? MAP_OBJ_TYPE.NONE](selectedObject.get(), mapCoords)
        }
      ]
    }
  ]
}

let voiceMsgMapScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = headerGap
  children = [
    backButton(close)
    content
  ]
  animations = wndSwitchAnim
})

return {
  isVoiceMsgMapSceneOpened = isOpened
  voiceMsgMapScene
}
