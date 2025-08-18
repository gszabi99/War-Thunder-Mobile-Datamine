from "%globalsDarg/darg_library.nut" import *
let { fabs, round } = require("math")
let { XrayDoll, TouchAreaOutButton } = require("wt.behaviors")
let { scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks, hasDebuffFire, speed,
  hasDebuffDriver, hasDebuffGunner, hasDebuffLoader, hasDebuffFireExternal
} = require("%rGui/hud/tankState.nut")
let { isStickActive, stickDelta } = require("%rGui/hud/stickState.nut")
let { mkDebuffIcon, mkDebuffIconEditView } = require("%rGui/hud/components/debuffIcon.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { isInZoom } = require("%rGui/hudState.nut")
let damagePanelBacklight = require("%rGui/hud/components/damagePanelBacklight.nut")

let damagePanelSize = hdpxi(175)
let moveTypeImageSize = hdpxi(50)
let iconSize = hdpxi(53)

let mkDebuffCfg = @(watch, imageId) { watch, icon = $"ui/gameuiskin#{imageId}" }

let crewDebuffsCfg = [
  mkDebuffCfg(hasDebuffGunner, "crew_gunner_indicator.svg")
  mkDebuffCfg(hasDebuffDriver, "crew_driver_indicator.svg")
  mkDebuffCfg(hasDebuffLoader, "crew_loader_indicator.svg")
]

let techDebuffsCfg = [
  mkDebuffCfg(hasDebuffGuns, "gun_state_indicator.svg")
  mkDebuffCfg(hasDebuffTurretDrive, "turret_gear_state_indicator.svg")
  mkDebuffCfg(hasDebuffEngine, "engine_state_indicator.svg")
  mkDebuffCfg(hasDebuffTracks, "track_state_indicator.svg")
  mkDebuffCfg(hasDebuffFire, "fire_indicator.svg")
  mkDebuffCfg(hasDebuffFireExternal, "fire_indicator.svg")
]

let moveType = Computed(function() {
  let sd = stickDelta.get()
  if (!isStickActive.get() || (sd.x == 0 && sd.y == 0))
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

let moveTypeImage = @(size) @() moveType.get() == null ? { watch = moveType }
  : {
      watch = moveType
      size = [size, size]
      hplace = ALIGN_CENTER
      pos = moveType.get().isForward ? [0, -size] : [0, ph(100)]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"{moveType.get().image}:{size}:{size}:P")
      flipX = !moveType.get().isRight
      flipY = !moveType.get().isForward
    }

let mkDebuffsRowCtor = @(debuffsCfg) function(scale) {
  let size = scaleEven(iconSize, scale)
  return function() {
    local count = 0
    let children = []
    foreach (cfg in debuffsCfg) {
      let { watch, icon } = cfg
      if (!watch.get())
        continue
      children.append(mkDebuffIcon(icon, size).__merge({
        key = watch
        transform = { translate = [(count++) * (-size), 0] }
        transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      }))
    }
    return {
      watch = debuffsCfg.map(@(c) c.watch)
      size = [debuffsCfg.len() * size, size]
      halign = ALIGN_RIGHT
      children
    }
  }
}

let mkCrewDebuffs = mkDebuffsRowCtor(crewDebuffsCfg)
let mkTechDebuffs = mkDebuffsRowCtor(techDebuffsCfg)

let mkDebuffsEditView = @(cfg) {
  size = [cfg.len() * iconSize, iconSize]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  children = cfg.map(@(c) mkDebuffIconEditView(c.icon, iconSize))
    .reverse()
}

let crewDebuffsEditView = mkDebuffsEditView(crewDebuffsCfg)
let techDebuffsEditView = mkDebuffsEditView(techDebuffsCfg)

function mkSpeedText(scale) {
  let monoFont = scaleFontWithTransform(fontMonoTinyShaded, scale, [1, 1])
  let font = scaleFontWithTransform(fontVeryTinyShaded, scale, [0, 1])
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = hdpx(2)
    children = [
      @() {
        watch = speed
        rendObj = ROBJ_TEXT
        text = speed.get()
      }.__update(monoFont)
      {
        rendObj = ROBJ_TEXT
        text = loc("measureUnits/kmh")
      }.__update(font)
    ]
  }
}

let speedTextEditView = {
  rendObj = ROBJ_TEXT
  text = "".concat("XX ", loc("measureUnits/kmh"))
}.__update(fontVeryTinyShaded)

let xrayDoll = @(stateFlags, moveChild, size) @() {
  size = [size, size]
  children = [
    damagePanelBacklight(stateFlags, [size, size])
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
        children = [
          moveChild
        ]
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
function mkDoll(scale) {
  let size = round(damagePanelSize * scale).tointeger()
  let shortcutImage = mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
  let moveChild = moveTypeImage(round(moveTypeImageSize * scale).tointeger())
  return @() {
    watch = isInZoom
    key = "tank_state_button"
    behavior = TouchAreaOutButton
    cameraControl = true
    touchMarginPriority = TOUCH_MINOR
    function onElemState(sf) {
      let prevSf = stateFlags.get()
      stateFlags.set(sf)
      let active = isActive(sf) && !isInZoom.get()

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
      xrayDoll(isInZoom.get() ? null : stateFlags, moveChild, size)
      shortcutImage
    ]
  }
}

return {
  mkDoll
  dollEditView
  mkSpeedText
  speedTextEditView
  mkCrewDebuffs
  crewDebuffsEditView
  mkTechDebuffs
  techDebuffsEditView
}
