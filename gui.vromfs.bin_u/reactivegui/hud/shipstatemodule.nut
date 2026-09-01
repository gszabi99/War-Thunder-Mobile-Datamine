from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "sound_wt" import tryPlaySound
from "wt.behaviors" import TouchAreaOutButton
from "%globalScripts/controls/shortcutActions.nut" import setShortcutOn, setShortcutOff
from "%globalsDarg/fontScale.nut" import prettyScaleForSmallNumberCharVariants
from "%globalsDarg/screenMath.nut" import scaleArr
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadHotkey, mkGamepadShortcutImage
from "%rGui/hud/actionBar/actionBarState.nut" import updateActionBarDelayed
import "%rGui/hud/components/damagePanelBacklight.nut" as damagePanelBacklight
from "%rGui/hud/components/debuffIcon.nut" import mkDebuffIcon, mkDebuffIconEditView
from "%rGui/hud/hudConfigParameters.nut" import getHudConfigParameter
from "%rGui/hud/hudHaptic.nut" import playHapticPattern, HAPT_DAMAGE
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
from "%rGui/hud/shipState.nut" import hasDebuffFire, curRelativeHealth, maxHealth, hasDebuffFlooding, hasDebuffGuns,
  hasDebuffEngines, hasDebuffMoveControl, hasDebuffTorpedoes, maxHpToRepair
from "%rGui/hudState.nut" import isInZoom
from "%rGui/options/guiOptions.nut" import getOptValue, OPT_HAPTIC_INTENSITY_ON_HERO_GET_SHOT
from "%rGui/style/hudColors.nut" import hudRedColor, hudOrangeColor, hudCoralRedColor
from "%rGui/style/teamColors.nut" import teamBlueLightColor


let iconSize = shHud(3.5)
let crewIconSize = shHud(4.0)
const gap = hdpx(10)

let defHealthImageWidth = shHud(40)
let defHealthImageHeight = (36.0 / 200.0 * defHealthImageWidth).tointeger()
let defHealthSize = [defHealthImageWidth, defHealthImageHeight]

let calcCrewHealthWidth = @(width) (width * 0.7).tointeger()
const crewHealthGap = hdpxi(17)

let remainingHpPercent = Computed(@() maxHealth.get() == 0 ? 1 : curRelativeHealth.get())

let debuffsCfg = [
  { has = hasDebuffFire,         icon = "ui/gameuiskin#hud_debuff_fire.svg" }
  { has = hasDebuffFlooding,     icon = "ui/gameuiskin#hud_debuff_water.svg" }
  { has = hasDebuffEngines,      icon = "ui/gameuiskin#hud_debuff_engine.svg" }
  { has = hasDebuffGuns,         icon = "ui/gameuiskin#hud_debuff_weapon.svg" }
  { has = hasDebuffMoveControl,  icon = "ui/gameuiskin#hud_debuff_control.svg" }
  { has = hasDebuffTorpedoes,    icon = "ui/gameuiskin#hud_debuff_torpedo_tubes.svg" }
]
let sailboatIconRemap = {
  [hasDebuffEngines] = "ui/gameuiskin#hud_debuff_sail_control.svg",
  [hasDebuffGuns] = "ui/gameuiskin#hud_debuff_sail_weapon.svg"
}
let debuffsCfgSailboat = debuffsCfg.map(@(c) c.has not in sailboatIconRemap ? c
  : c.__merge({ icon = sailboatIconRemap[c.has]}))

local prevHpPercent = 1.0
let colorConfig = [
  { remainValue = 0.25, color = hudRedColor     }
  { remainValue = 0.5,  color = hudOrangeColor  }
  { remainValue = 1.0,  showTeamColor = true }
]

let healthColor = Computed(function() {
  let currConfig = colorConfig.findvalue(@(v) v.remainValue > remainingHpPercent.get())
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

let hpToRepairColor = hudCoralRedColor
let isVisibleHpToRepair = Computed(@() maxHpToRepair.get() > curRelativeHealth.get())
let hpToRepairPercent = Computed(@() ((maxHpToRepair.get() - curRelativeHealth.get() + 0.005) * 100).tointeger())

let xrayDoll = @(size, stateFlags) {
  size
  children = [
    damagePanelBacklight(stateFlags, size)
    @() {
      watch = healthColor
      color = getHudConfigParameter("changeDmPanelColorDependingOnHp") ? healthColor.get() : teamBlueLightColor
      size = FLEX
      transform = {
        rotate = 90
      }
      rendObj = ROBJ_XRAYDOLL
      rotateWithCamera = false
      drawOutlines = false
      drawSilhouette = true
      drawTargetingSightLine = true
      limitSizeToRect = true
      modulateSilhouetteColor = true
    }
  ]
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = const [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
let mkDollCtor = @(rawSize) function(scale) {
  let size = scaleArr(rawSize, scale)
  let stateFlagsExt = Computed(@() isInZoom.get() ? 0 : stateFlags.get())
  return {
    key = "ship_state_button"
    behavior = TouchAreaOutButton
    cameraControl = true
    touchMarginPriority = TOUCH_MINOR
    function onElemState(sf) {
      let prevSf = stateFlags.get()
      stateFlags.set(sf)
      let active = isActive(stateFlagsExt.get())
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
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      xrayDoll(size, stateFlagsExt)
      mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
    ]
  }
}

let mkDollEditView = @(size) {
  size
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

hasDebuffEngines.subscribe(@(v) v ? tryPlaySound("message_debuff_loosing_speed") : null) 
hasDebuffGuns.subscribe(@(v) v ? tryPlaySound("message_debuff_cant_shoot") : null) 

function mkDebuff(watch, imageId, size) {
  let icon = mkDebuffIcon(imageId, size)
  return @() {
    watch
    size = [size, size]
    children = watch.get() ? icon : null
  }
}

let mkDebuffsCtor = @(cfg) @(scale) {
  flow = FLOW_HORIZONTAL
  gap = round(gap * scale)
  children = cfg.map(@(c) mkDebuff(c.has, c.icon, scaleEven(iconSize, scale)))
}

let mkShipDebuffs = mkDebuffsCtor(debuffsCfg)
let mkSailboatDebuffs = mkDebuffsCtor(debuffsCfgSailboat)

let mkDebuffsEditView = @(cfg) {
  flow = FLOW_HORIZONTAL
  gap
  children = cfg.map(@(c) mkDebuffIconEditView(c.icon, iconSize))
}

let shipDebuffsEditView = mkDebuffsEditView(debuffsCfg)
let sailboatDebuffsEditView = mkDebuffsEditView(debuffsCfgSailboat)

let mkCrewIcon = @(icon, size = crewIconSize) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{size}:{size}:P")
  keepAspect = true
}

let mkCrewHealthCtor = @(size, hasCrewWounded = true) function(scale) {
  let iSize = round(crewIconSize * scale).tointeger()
  let font = prettyScaleForSmallNumberCharVariants(fontSmallShaded, scale)
  return {
    size = [round(calcCrewHealthWidth(size[0]) * scale), iSize]
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = crewHealthGap
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        key = "crew_active"
        children = [
          mkCrewIcon("ship_crew.svg", iSize)
          @() {
            watch = [remainingHpPercent, healthColor]
            rendObj = ROBJ_TEXT
            color = healthColor.get()
            text =  $"{((remainingHpPercent.get() * 100)+ 0.5).tointeger()} %"
          }.__update(font)
        ]
      }
      !hasCrewWounded ? null
        : @() {
            watch = isVisibleHpToRepair
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = shHud(0.4)
            key = "crew_injured"
            children = !isVisibleHpToRepair.get() ? null
              : [
                  mkCrewIcon("hud_crew_wounded.svg", iSize)
                  @() {
                    watch = hpToRepairPercent
                    rendObj = ROBJ_TEXT
                    color = hpToRepairColor
                    text =  $"{hpToRepairPercent.get()} %"
                  }.__update(font)
                ]
          }
    ]
  }
}

let mkCrewHealthEditView = @(size, hasCrewWounded = true) {
  size = [calcCrewHealthWidth(size[0]), crewIconSize]
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = crewHealthGap
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        mkCrewIcon("ship_crew.svg")
        {
          rendObj = ROBJ_TEXT
          text =  $"xx %"
        }.__update(fontSmallShaded)
      ]
    }
    !hasCrewWounded ? null
      : {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = shHud(0.4)
          children = [
            mkCrewIcon("hud_crew_wounded.svg")
            {
              rendObj = ROBJ_TEXT
              text =  $"xx %"
            }.__update(fontSmallShaded)
          ]
        }
  ]
}

return {
  mkDollCtor
  mkDollEditView
  mkShipDebuffs
  mkSailboatDebuffs
  shipDebuffsEditView
  sailboatDebuffsEditView
  mkCrewHealthCtor
  mkCrewHealthEditView
  defHealthSize
}
