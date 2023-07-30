from "%globalsDarg/darg_library.nut" import *
let { hasDebuffFire, curRelativeHealth, maxHealth, hasDebuffFlooding, hasDebuffGuns, hasDebuffEngines, hasDebuffMoveControl,
hasDebuffTorpedoes, buoyancy, maxHpToRepair } = require("%rGui/hud/shipState.nut")
let { teamBlueLightColor } = require("%rGui/style/teamColors.nut")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { registerHapticPattern, playHapticPattern } = require("hapticVibration")
let { mkDebuffIcon } = require("components/debuffIcon.nut")

let iconSize = shHud(3.5)
let crewIconSize = shHud(4.0)
let gap = hdpx(10)
let healthImageWidth = shHud(40)
let healthImageHeight = (36.0 / 200.0 * healthImageWidth).tointeger()

let HAPT_DAMAGE = registerHapticPattern("TakingDamage", { time = 0.0, intensity = 0.4, sharpness = 0.1, duration = 0.1, attack = 0.01, release = 0.14 })

let remainingHpPercent = Computed(function() {
  if (maxHealth.value == 0)
    return 1

  return curRelativeHealth.value
})

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

let buoyancyColor = Computed(function() {
  let currConfig = colorConfig.findvalue(@(v) v.remainValue > buoyancy.value)
  if (currConfig == null)
    return teamBlueLightColor
  if (currConfig?.showTeamColor ?? false)
    return teamBlueLightColor
  return currConfig.color
})

let isVisibleBuoyancy = Computed(@() buoyancy.value < 0.9995)

remainingHpPercent.subscribe(function(value) {
  if (value < 1.0 && value < prevHpPercent)
    playHapticPattern(HAPT_DAMAGE)
  prevHpPercent = value
})

let hpToRepairColor = 0xFFFF5D5D
let isVisibleHpToRepair = Computed(@() maxHpToRepair.value > curRelativeHealth.value)
let hpToRepairPercent = Computed(@() ((maxHpToRepair.value - curRelativeHealth.value + 0.005) * 100).tointeger())

let function mkDebuff(watch, imageId) {
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

let doll = @() {
  watch = [ healthColor ]
  color = getHudConfigParameter("changeDmPanelColorDependingOnHp") ? healthColor.value : teamBlueLightColor
  size = [healthImageWidth, healthImageHeight]
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

let mkCrewIcon = @(icon) {
  size = [crewIconSize, crewIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{crewIconSize}:{crewIconSize}:P")
  keepAspect = true
}

let crewIcon = mkCrewIcon("ship_crew.svg")
let hpToRepairIcon = mkCrewIcon("hud_crew_wounded.svg")
let buoyancyIcon = mkCrewIcon("buoyancy_icon.svg")

return {
  size = [healthImageWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      gap = shHud(1.6)
      children = [
        @() {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          watch = isVisibleBuoyancy
          children = isVisibleBuoyancy.value ? [
            buoyancyIcon
            @() {
              watch = [buoyancy, buoyancyColor]
              rendObj = ROBJ_TEXT
              color = buoyancyColor.value
              text =  $"{(buoyancy.value * 100).tointeger()} %"
              fontFxColor = Color(0, 0, 0, 255)
              fontFxFactor = 50
              fontFx = FFT_GLOW
            }.__update(fontSmall)
          ] : null
        }
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
              fontFxColor = Color(0, 0, 0, 255)
              fontFxFactor = 50
              fontFx = FFT_GLOW
            }.__update(fontSmall)
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
              fontFxColor = 0xFF000000
              fontFxFactor = 50
              fontFx = FFT_GLOW
            }.__update(fontSmall)
          ]
        }
      ]
    }
    doll
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
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
  ]
}
