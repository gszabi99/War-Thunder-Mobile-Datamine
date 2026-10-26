from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "math" import fabs, round, PI
from "wt.behaviors" import XrayDoll, TouchAreaOutButton
from "%globalScripts/controls/shortcutActions.nut" import setShortcutOn, setShortcutOff
from "%appGlobals/unitConst.nut" import WALKER
from "%globalsDarg/fontScale.nut" import scaleFontWithTransform
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadHotkey, mkGamepadShortcutImage
from "%rGui/hud/actionBar/actionBarState.nut" import updateActionBarDelayed
import "%rGui/hud/components/damagePanelBacklight.nut" as damagePanelBacklight
from "%rGui/hud/components/debuffIcon.nut" import mkDebuffIcon, mkDebuffIconEditView
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
from "%rGui/hud/stickState.nut" import isStickActive, stickDelta
from "%rGui/hud/tankHudDebuffsState.nut" import turretDriveData, engineData, gunData, tracksData,
  reInitTankDebuffsStates
from "%rGui/hud/tankState.nut" import hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks,
  hasDebuffFire, speed, hasDebuffFireExternal
from "%rGui/hud/crewState.nut" import crewDriverState, crewGunnerState, crewLoaderState
from "%rGui/hudState.nut" import isInZoom, unitType
from "%rGui/style/hudColors.nut" import hudRedColor, hudWhiteColor, hudGoldColor, hudOrangeDeepColor
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach, showTooltip, mkTooltipText


const damagePanelSize = hdpxi(175)
const moveTypeImageSize = hdpxi(50)
const iconSize = hdpxi(53)

let getHealthColor = @(health) health >= 1 ? hudWhiteColor
  : health > 0.7 ? hudGoldColor
  : health > 0.35 ? hudOrangeDeepColor
  : health > 0 ? hudRedColor
  : null
let getPenaltyColor = @(penalty) penalty < 0.2 ? hudGoldColor
  : penalty < 0.35 ? hudOrangeDeepColor
  : hudRedColor

let getCannonHealth = @(data) min(data?.barrelHealth ?? 1, data?.rocketlauncherHealth ?? 1,
  data?.guidanceHealth ?? 1)
let getTurretHealth = @(data) min(data?.horizontalDriveHealth ?? 1, data?.verticalDriveHealth ?? 1)

let isBreechDead = @(data) !!data?.breechBroken || !!data?.breechDead || (data?.breechHealth ?? 1) == 0

let isCannonDead = @(data) !!data?.barrelBroken || !!data?.barrelDead || !!data?.guidanceDead
  || getCannonHealth(data) == 0
let isGunDead = @(data) isCannonDead(data) || isBreechDead(data)
let isEngineDamaged = @(data) min(data?.engineHealth ?? 1, data?.transmissionHealth ?? 1) < 1

let crewMainCfg = [
  {
    has = Computed(@() crewGunnerState.get().state != "ok" || crewGunnerState.get().health < 1)
    extraData = crewGunnerState
    debuffs = [
      {
        function mkData(data) {
          let { health = 1, state = "ok" } = data
          let reduction = 0.5 * (1 - health)
          let isDisabled = health == 0 || state != "ok"
          return {
            text = isDisabled ? loc("hud_tank_crew_gunner_out_of_action")
              : loc("hint/debuff/gunner", { value = (reduction * 100).tointeger() })
            color = isDisabled ? null : getPenaltyColor(reduction)
            icon = isDisabled ? "crew_gunner_indicator.svg" : "crew_gunner_debuff.svg"
          }
        }
      }
    ]
  }
  {
    has = Computed(@() crewDriverState.get().state != "ok" || crewDriverState.get().health < 1)
    extraData = crewDriverState
    debuffs = [
      {
        function mkData(data) {
          let isDisabled = (data?.health ?? 1) == 0 || (data?.state ?? "ok") != "ok"
          return {
            text = isDisabled ? loc("hud_tank_crew_driver_out_of_action") : loc("my_dmg_msg/tank_driver")
            color = isDisabled ? null : getHealthColor(data?.health ?? 1)
            icon = isDisabled ? "crew_driver_indicator.svg" : "crew_driver_debuff.svg"
          }
        }
      }
    ]
  }
  {
    has = Computed(@() crewLoaderState.get().state != "ok" || crewLoaderState.get().health < 1)
    extraData = crewLoaderState
    debuffs = [
      {
        function mkData(data) {
          let isDisabled = (data?.health ?? 1) == 0 || (data?.state ?? "ok") != "ok"
          return {
            text = isDisabled ? loc("hud_tank_crew_loader_out_of_action") : loc("hint/debuff/loader", { value = 25 })
            color = isDisabled ? null : getHealthColor(data?.health ?? 1)
            icon = isDisabled ? "crew_loader_indicator.svg" : "crew_loader_debuff.svg"
          }
        }
      }
    ]
  }
]

let techMainCfg = [
  {
    has = hasDebuffGuns
    extraData = gunData
    debuffs = [
      {
        isActive = @(data) isGunDead(data) || getCannonHealth(data) < 0.7
        function mkData(data) {
          let isDead = isGunDead(data)
          let hp = getCannonHealth(data)
          let chance = 1 - (hp / 0.7) * 0.3
          return {
            text = isDead ? loc("hint/debuff/gunBroken")
              : loc("hint/debuff/gun", { value = (chance * 100).tointeger() })
            color = isDead ? null
              : chance < 0.8 ? hudGoldColor
              : chance < 0.9 ? hudOrangeDeepColor
              : hudRedColor
            icon = isDead ? "gun_state_indicator_broken.svg" : "dmg_shell_burst.svg"
          }
        }
      }
      {
        isActive = @(data) (data?.autoloaderHealth ?? 1) == 0 || !!data?.autoloaderDead
        mkData = @(_) {
          text = loc("my_dmg_msg/tank_autoloader")
          icon = "dmg_reloading_blocked.svg"
        }
      }
      {
        isActive = @(data) !isGunDead(data) && (data?.breechHealth ?? 1) < 0.7
        mkData = @(_) { text = loc("hint/debuff/breech"), icon = "dmg_misfire.svg" }
      }
    ]
  }
  {
    has = hasDebuffTurretDrive
    extraData = turretDriveData
    debuffs = [
      {
        isActive = @(data) getTurretHealth(data) < 1 || !!data?.horizontalDriveBroken || !!data?.horizontalDriveDead
          || !!data?.verticalDriveBroken
        function mkData(data) {
          let isHorizontalDriveDead = data?.horizontalDriveDead || data?.horizontalDriveBroken
          return {
            text = isHorizontalDriveDead && data?.verticalDriveBroken ? loc("hint/debuff/turretDriveBroken")
              : isHorizontalDriveDead ? loc("hint/debuff/horizontalTurretDriveBroken")
              : data?.verticalDriveBroken ? loc("hint/debuff/verticalTurretDriveBroken")
              : loc("hint/debuff/turretEngine")
            color = isHorizontalDriveDead || data?.verticalDriveBroken ? null : getHealthColor(getTurretHealth(data))
            icon = isHorizontalDriveDead && data?.verticalDriveBroken ? "turret_gear_state_indicator_both.svg"
              : isHorizontalDriveDead ? "turret_gear_horizontal_state_indicator.svg"
              : data?.verticalDriveBroken ? "turret_gear_vertical_state_indicator.svg"
              : "turret_gear_state_indicator.svg"
          }
        }
      }
    ]
  }
  {
    has = Computed(@() hasDebuffEngine.get() || isEngineDamaged(engineData.get()))
    extraData = engineData
    debuffs = [
      {
        isActive = @(data) !!data?.engineBroken || !!data?.transmissionBroken || isEngineDamaged(data)
        function mkData(data) {
          let { engineHealth = 1, transmissionHealth = 1 } = data
          let isBroken = data?.engineBroken || data?.transmissionBroken
          let reduction = 0.5 * (1 - engineHealth * transmissionHealth)
          return {
            text = isBroken ? loc("hint/debuff/engineTransmissionBroken")
              : loc("hint/debuff/engineReduction", { value = (reduction * 100).tointeger() })
            color = isBroken ? null : getPenaltyColor(reduction)
            icon = isBroken ? "engine_state_indicator_broken.svg" : "dmg_engine_power_loss.svg"
          }
        }
      }
    ]
  }
  {
    has = hasDebuffTracks
    extraData = tracksData
    debuffs = [
      {
        isActive = @(data) (data?.trackHealth ?? 1) < 1 || !!data?.trackBroken
        mkData = @(data) {
          text = data?.trackBroken ? loc("hint/debuff/tracksBroken") : loc("hint/debuff/tracks")
          color = data?.trackBroken ? null : getHealthColor(data?.trackHealth ?? 1)
          icon = data?.trackBroken ? "track_state_indicator_broken.svg" : "track_state_indicator.svg"
        }
      }
    ]
  }
  {
    has = hasDebuffFire
    debuffs = [
      {
        mkData = @(_) { text = loc("hint/debuff/tank_fire"), icon = "fire_indicator.svg" }
      }
    ]
  }
  {
    has = hasDebuffFireExternal
    debuffs = [
      {
        mkData = @(_) { text = loc("hint/debuff/tank_fire_external"), icon = "fire_external_indicator.svg" }
      }
    ]
  }
]

let mkDebuffsCfg = @(mainCfg) mainCfg.map(@(cfg) {
  watch = cfg.has
  extraWatch = cfg?.extraData
  viewIcon = cfg.debuffs[0].mkData(null).icon
  function mkDebuffIndicatorsData() {
    let res = []
    foreach (debuff in (cfg?.debuffs ?? [])) {
      let rawData = cfg?.extraData.get()
      if (debuff?.isActive(rawData) ?? true)
        res.append(debuff.mkData(rawData))
    }
    return res
  }
})

let crewDebuffsCfg = mkDebuffsCfg(crewMainCfg)
let techDebuffsCfg = mkDebuffsCfg(techMainCfg)

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
      size = size
      hplace = ALIGN_CENTER
      pos = moveType.get().isForward ? [0, -size] : const [0, ph(100)]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"{moveType.get().image}:{size}:{size}:P")
      flipX = !moveType.get().isRight
      flipY = !moveType.get().isForward
    }

const popupIconSize = hdpx(40)

let mkPopupRow = @(data) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    {
      size = popupIconSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{data.icon}:{popupIconSize}:{popupIconSize}:P")
      color = data?.color ?? hudRedColor
    }
    mkTooltipText(data.text)
  ]
}

let mkPopupContent = @(debuffsCfgs, baseWatch) function() {
  let rows = []
  let extraWatch = []
  foreach (debuffsCfg in debuffsCfgs)
    foreach (cfg in debuffsCfg)
      if (cfg.watch.get()) {
        foreach (data in cfg.mkDebuffIndicatorsData())
          rows.append(mkPopupRow(data))
        if (cfg.extraWatch != null)
          extraWatch.append(cfg.extraWatch)
      }
  return {
    watch = extraWatch.extend(baseWatch)
    flow = FLOW_VERTICAL
    gap = hdpx(6)
    children = rows
  }
}

let mkTooltipAllDebuffsCtor = @(key) function() {
  let debuffsCfgs = [crewDebuffsCfg, techDebuffsCfg]
  local hasAnyDebuff = false
  let baseWatch = []
  foreach (debuffsCfg in debuffsCfgs) {
    foreach (cfg in debuffsCfg) {
      baseWatch.append(cfg.watch)
      if (cfg.watch.get())
        hasAnyDebuff = true
    }
  }
  return !hasAnyDebuff ? null
    : {
        key
        content = mkPopupContent(debuffsCfgs, baseWatch)
        flow = FLOW_VERTICAL
        flowOffset = sh(20)
        halign = ALIGN_LEFT
      }
}

let mkDebuffsRowCtor = @(debuffsCfg, onAttach = null) function(scale) {
  let size = scaleEven(iconSize, scale)
  let key = {}
  let stateFlags = Watched(0)
  let tooltipCtor = mkTooltipAllDebuffsCtor(key)
  let baseWatch = debuffsCfg.map(@(c) c.watch)
  let iconTransitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
  let elemStateHandler = withTooltip(stateFlags, key, tooltipCtor)
  let detachHandler = tooltipDetach(stateFlags)
  return function() {
    local count = 0
    let children = []
    let watch = [].extend(baseWatch)
    foreach (cfg in debuffsCfg) {
      if (cfg.watch.get()) {
        foreach (data in cfg.mkDebuffIndicatorsData())
          children.append(mkDebuffIcon($"ui/gameuiskin#{data.icon}", size).__merge({
            key = $"tank_state_debuffs_row_{count}"
            transform = { translate = [(count++) * (-size), 0] }
            transitions = iconTransitions
            color = data?.color ?? hudRedColor
          }))
        if (cfg.extraWatch != null)
          watch.append(cfg.extraWatch)
      }
    }
    if (stateFlags.get() & S_ACTIVE)
      showTooltip(gui_scene.getCompAABBbyKey(key), tooltipCtor())
    return {
      watch
      key
      size = [debuffsCfg.len() * size, size]
      halign = ALIGN_RIGHT
      behavior = Behaviors.Button
      cameraControl = true
      touchMarginPriority = TOUCH_MINOR
      onElemState = elemStateHandler
      onAttach
      onDetach = detachHandler
      children
    }
  }
}

let mkCrewDebuffs = mkDebuffsRowCtor(crewDebuffsCfg)
let mkTechDebuffs = mkDebuffsRowCtor(techDebuffsCfg, @() reInitTankDebuffsStates())

let mkDebuffsEditView = @(cfg) {
  size = [cfg.len() * iconSize, iconSize]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  children = cfg.map(@(c) mkDebuffIconEditView($"ui/gameuiskin#{c.viewIcon}", iconSize))
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
  size = size
  children = [
    damagePanelBacklight(stateFlags, [size, size])
    {
      rendObj = ROBJ_XRAYDOLL
      size = FLEX
      rotateWithCamera = true
      drawOutlines = false
      drawSilhouette = false
      drawTargetingSightLine = true
      modulateSilhouetteColor = true
      dmIndViewYawOffset = unitType.get() == WALKER ? PI : 0
      children = {
        size = FLEX
        behavior = XrayDoll
        transform = {}
        children = moveChild
      }
    }
  ]
}

let dollEditView = {
  size = const [damagePanelSize, damagePanelSize]
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
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = const [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
function mkDoll(scale) {
  let size = round(damagePanelSize * scale).tointeger()
  let shortcutImage = mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
  let moveChild = moveTypeImage(round(moveTypeImageSize * scale).tointeger())
  let hotkeys = mkGamepadHotkey(shortcutId)
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
      stateFlags.set(0)
      setShortcutOff(shortcutId)
    }
    hotkeys
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
