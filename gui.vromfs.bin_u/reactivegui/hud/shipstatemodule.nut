from "%globalsDarg/darg_library.nut" import *
let { TouchAreaOutButton } = require("wt.behaviors")
let { hasDebuffFire, curRelativeHealth, maxHealth, hasDebuffFlooding, hasDebuffGuns, hasDebuffEngines, hasDebuffMoveControl,
hasDebuffTorpedoes, maxHpToRepair } = require("%rGui/hud/shipState.nut")
let { teamBlueLightColor } = require("%rGui/style/teamColors.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { playHapticPattern, HAPT_DAMAGE } = require("hudHaptic.nut")
let { mkDebuffIcon, mkDebuffIconEditView } = require("components/debuffIcon.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isInZoom } = require("%rGui/hudState.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let damagePanelBacklight = require("components/damagePanelBacklight.nut")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT } = require("%rGui/options/guiOptions.nut")

let iconSize = shHud(3.5)
let crewIconSize = shHud(4.0)
let gap = hdpx(10)
let healthImageWidth = shHud(40)
let healthImageHeight = (36.0 / 200.0 * healthImageWidth).tointeger()

let fontFx = {
  fontFxColor = 0xFF000000
  fontFxFactor = 50
  fontFx = FFT_GLOW
}

let remainingHpPercent = Computed(@() maxHealth.value == 0 ? 1 : curRelativeHealth.value)

local prevHpPercent = 1.0
let colorConfig = [
  { remainValue = 0.25, color = Color(253, 0, 1)     }
  { remainValue = 0.5,  color = Color(246, 178, 54)  }
  { remainValue = 1.0,  showTeamColor = true }
]

let healthColor = Computed(function() {
  let currConfig = colorConfig.findvalue(@(v) v.remainValue > remainingHpPercent.value)
  if (currConfig == null)
    return teamBlueLightColor
  if (currConfig?.showTeamColor ?? false)
    return teamBlueLightColor
  return currConfig.color
})

remainingHpPercent.subscribe(function(value) {
  if (value < 1.0 && value < prevHpPercent) {
    playHapticPattern(HAPT_DAMAGE, getOptValue(OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT))
  }
  prevHpPercent = value
})

let hpToRepairColor = 0xFFFF5D5D
let isVisibleHpToRepair = Computed(@() maxHpToRepair.value > curRelativeHealth.value)
let hpToRepairPercent = Computed(@() ((maxHpToRepair.value - curRelativeHealth.value + 0.005) * 100).tointeger())

function mkDebuff(watch, imageId) {
  let icon = mkDebuffIcon($"ui/gameuiskin#{imageId}:{iconSize}:{iconSize}", iconSize)
  return @() {
    watch
    size = [iconSize, iconSize]
    children = watch.value ? icon : null
  }
}

let debuffFire = mkDebuff(hasDebuffFire, "hud_debuff_fire.svg")
let debuffFlooding = mkDebuff(hasDebuffFlooding, "hud_debuff_water.svg")
let debuffEngines = mkDebuff(hasDebuffEngines, "hud_debuff_engine.svg")
let debuffGuns = mkDebuff(hasDebuffGuns, "hud_debuff_weapon.svg")
let debuffControl = mkDebuff(hasDebuffMoveControl, "hud_debuff_control.svg")
let debuffTorpedoes = mkDebuff(hasDebuffTorpedoes, "hud_debuff_torpedo_tubes.svg")

let xrayDoll = @(stateFlags) {
  size = [healthImageWidth, healthImageHeight]
  children = [
    damagePanelBacklight(stateFlags, healthImageHeight * 2.2)
    @() {
      watch = healthColor
      color = getHudConfigParameter("changeDmPanelColorDependingOnHp") ? healthColor.value : teamBlueLightColor
      size = flex()
      transform = {
        rotate = 90
      }
      rendObj = ROBJ_XRAYDOLL
      rotateWithCamera = false
      drawOutlines = false
      drawSilhouette = true
      drawTargetingSightLine = true
      modulateSilhouetteColor = true
    }
  ]
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
  key = "ship_state_button"
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

let dollEditView = {
  size = [healthImageWidth, healthImageHeight]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("xray/model")
  }.__update(fontSmall)
}

let mkCrewIcon = @(icon) {
  size = [crewIconSize, crewIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{crewIconSize}:{crewIconSize}:P")
  keepAspect = true
}

let crewIcon = mkCrewIcon("ship_crew.svg")
let hpToRepairIcon = mkCrewIcon("hud_crew_wounded.svg")

let shipDebuffs = {
  flow = FLOW_HORIZONTAL
  gap
  children = [
    debuffFire
    debuffEngines
    debuffFlooding
    debuffGuns
    debuffControl
    debuffTorpedoes
  ]
}

let shipDebuffsEditView = {
  flow = FLOW_HORIZONTAL
  gap
  children = [
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_fire.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_water.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_engine.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_weapon.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_control.svg:{iconSize}:{iconSize}", iconSize)
    mkDebuffIconEditView($"ui/gameuiskin#hud_debuff_torpedo_tubes.svg:{iconSize}:{iconSize}", iconSize)
  ]
}

let crewHealth = {
  size = [healthImageWidth * 0.7, SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = shHud(1.6)
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      key = "crew_active"
      children = [
        crewIcon
        @() {
          watch = [remainingHpPercent, healthColor]
          rendObj = ROBJ_TEXT
          color = healthColor.value
          text =  $"{((remainingHpPercent.value * 100)+ 0.5).tointeger()} %"
        }.__update(fontSmall, fontFx)
      ]
    }
    @() {
      watch = isVisibleHpToRepair
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = shHud(0.4)
      key = "crew_injured"
      children = !isVisibleHpToRepair.value ? null : [
        hpToRepairIcon
        @() {
          watch = hpToRepairPercent
          rendObj = ROBJ_TEXT
          color = hpToRepairColor
          text =  $"{hpToRepairPercent.value} %"
        }.__update(fontSmall, fontFx)
      ]
    }
  ]
}

let crewHealthEditView = {
  size = [healthImageWidth * 0.7, SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = shHud(1.6)
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        crewIcon
        {
          rendObj = ROBJ_TEXT
          text =  $"xx %"
        }.__update(fontSmall, fontFx)
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = shHud(0.4)
      children = [
        hpToRepairIcon
        {
          rendObj = ROBJ_TEXT
          text =  $"xx %"
        }.__update(fontSmall, fontFx)
      ]
    }
  ]
}

return {
  doll
  dollEditView
  shipDebuffs
  shipDebuffsEditView
  crewHealth
  crewHealthEditView
}
