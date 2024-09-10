from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { XrayDoll, TouchAreaOutButton } = require("wt.behaviors")
let { hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks, hasDebuffFire, speed,
  hasDebuffDriver, hasDebuffGunner, hasDebuffLoader
} = require("%rGui/hud/tankState.nut")
let { isStickActive, stickDelta } = require("stickState.nut")
let { mkDebuffIcon, mkDebuffIconEditView } = require("components/debuffIcon.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let { isInZoom } = require("%rGui/hudState.nut")
let damagePanelBacklight = require("components/damagePanelBacklight.nut")

let damagePanelSize = hdpxi(175)
let moveTypeImageSize = hdpxi(50)
let iconSize = hdpxi(53)


let moveType = Computed(function() {
  let sd = stickDelta.value
  if (!isStickActive.value || (sd.x == 0 && sd.y == 0))
    return null

  let isForward = sd.y >= 0
  let isRight = sd.x <= 0
  let steering = fabs(sd.x)
  let image = steering < 0.1 ? "ui/gameuiskin#hud_tank_arrow_forward.svg"
    : steering < 0.5 ? "ui/gameuiskin#hud_tank_arrow_right_01.svg"
    : steering < 0.7 ? "ui/gameuiskin#hud_tank_arrow_right_02.svg"
    : steering < 0.9 ? "ui/gameuiskin#hud_tank_arrow_right_03.svg"
    : "ui/gameuiskin#hud_tank_arrow_right_rotation.svg"
  return { image, isForward, isRight }
})

let moveTypeImage = @() moveType.value == null ? { watch = moveType }
  : {
      watch = moveType
      size = [moveTypeImageSize, moveTypeImageSize]
      hplace = ALIGN_CENTER
      pos = moveType.value.isForward ? [0, -moveTypeImageSize] : [0, ph(100)]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"{moveType.value.image}:{moveTypeImageSize}:{moveTypeImageSize}:P")
      flipX = !moveType.value.isRight
      flipY = !moveType.value.isForward
    }

let mkDebuffCfg = @(watch, imageId) {
  watch
  icon = mkDebuffIcon($"ui/gameuiskin#{imageId}:{iconSize}:{iconSize}", iconSize)
}

let mkDebuffsRow = @(debuffsCfg) function() {
  local count = 0
  let children = []
  foreach (cfg in debuffsCfg) {
    let { watch, icon } = cfg
    if (!watch.value)
      continue
    children.append(icon.__merge({
      key = watch
      transform = { translate = [(count++) * (-iconSize), 0] }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    }))
  }
  return {
    watch = debuffsCfg.map(@(c) c.watch)
    size = [debuffsCfg.len() * iconSize, iconSize]
    halign = ALIGN_RIGHT
    children
  }
}

let crewDebuffs = mkDebuffsRow([
  mkDebuffCfg(hasDebuffGunner, "crew_gunner_indicator.svg")
  mkDebuffCfg(hasDebuffDriver, "crew_driver_indicator.svg")
  mkDebuffCfg(hasDebuffLoader, "crew_loader_indicator.svg")
])

let techDebuffs = mkDebuffsRow([
  mkDebuffCfg(hasDebuffGuns, "gun_state_indicator.svg")
  mkDebuffCfg(hasDebuffTurretDrive, "turret_gear_state_indicator.svg")
  mkDebuffCfg(hasDebuffEngine, "engine_state_indicator.svg")
  mkDebuffCfg(hasDebuffTracks, "track_state_indicator.svg")
  mkDebuffCfg(hasDebuffFire, "fire_indicator.svg")
])

let crewDebuffsEditView = {
  size = [3 * iconSize, iconSize]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  children = [
    mkDebuffIconEditView($"ui/gameuiskin#crew_loader_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#crew_driver_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#crew_gunner_indicator.svg:{iconSize}:{iconSize}", iconSize)
  ]
}

let techDebuffsEditView = {
  size = [5 * iconSize, iconSize]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  children = [
    mkDebuffIconEditView($"ui/gameuiskin#fire_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#track_state_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#engine_state_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#turret_gear_state_indicator.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#gun_state_indicator.svg:{iconSize}:{iconSize}", iconSize)
  ]
}

let speedText = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = hdpx(2)
  children = [
    @() {
      watch = speed
      rendObj = ROBJ_TEXT
      text = speed.value
    }.__update(fontMonoTinyShaded)
    {
      rendObj = ROBJ_TEXT
      text = loc("measureUnits/kmh")
    }.__update(fontVeryTinyShaded)
  ]
}

let speedTextEditView = {
  rendObj = ROBJ_TEXT
  text = "".concat("XX ", loc("measureUnits/kmh"))
}.__update(fontVeryTinyShaded)

let xrayDoll = @(stateFlags) @() {
  size = [damagePanelSize, damagePanelSize]
  children = [
    damagePanelBacklight(stateFlags, damagePanelSize)
    {
      rendObj = ROBJ_XRAYDOLL
      size = flex()
      rotateWithCamera = true
      drawOutlines = false
      drawSilhouette = false
      drawTargetingSightLine = true
      modulateSilhouetteColor = true
      children = {
        size = flex()
        behavior = XrayDoll
        transform = {}
        children = moveTypeImage
      }
    }
  ]
}

let dollEditView = {
  size = [damagePanelSize, damagePanelSize]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("xray/model")
  }.__update(fontSmallShaded)
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
let doll =  @() {
  key = "tank_state_button"
  behavior = TouchAreaOutButton
  watch = isInZoom
  eventPassThrough = true
  function onElemState(sf) {
    let prevSf = stateFlags.value
    stateFlags(sf)
    let active = isActive(sf) && !isInZoom.value

    if (active != isActive(prevSf))
      if (active)
        useShortcutOn(shortcutId)
      else
        setShortcutOff(shortcutId)
  }
  function onDetach() {
    stateFlags(0)
    setShortcutOff(shortcutId)
  }
  hotkeys = mkGamepadHotkey(shortcutId)
  children = [
    xrayDoll(isInZoom.value ? null : stateFlags)
    mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
  ]
}

return {
  doll
  dollEditView
  speedText
  speedTextEditView
  crewDebuffs
  crewDebuffsEditView
  techDebuffs
  techDebuffsEditView
}
