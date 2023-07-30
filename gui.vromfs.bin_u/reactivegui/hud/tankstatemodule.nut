from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks, hasDebuffFire, speed,
  hasDebuffDriver, hasDebuffGunner, hasDebuffLoader
} = require("%rGui/hud/tankState.nut")
let { isStickActive, stickDelta } = require("stickState.nut")
let { mkDebuffIcon } = require("components/debuffIcon.nut")


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
  let image = sd.x == 0 ? "ui/gameuiskin#hud_tank_arrow_forward.svg"
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
    size = [4 * iconSize, iconSize]
    halign = ALIGN_RIGHT
    children
  }
}

let crewDebuffsRow = mkDebuffsRow([
  mkDebuffCfg(hasDebuffGunner, "crew_gunner_indicator.svg")
  mkDebuffCfg(hasDebuffDriver, "crew_driver_indicator.svg")
  mkDebuffCfg(hasDebuffLoader, "crew_loader_indicator.svg")
])

let techDebuffsRow = mkDebuffsRow([
  mkDebuffCfg(hasDebuffGuns, "gun_state_indicator.svg")
  mkDebuffCfg(hasDebuffTurretDrive, "turret_gear_state_indicator.svg")
  mkDebuffCfg(hasDebuffEngine, "engine_state_indicator.svg")
  mkDebuffCfg(hasDebuffTracks, "track_state_indicator.svg")
  mkDebuffCfg(hasDebuffFire, "fire_indicator.svg")
])

local speedText = {
  padding = [0, hdpx(4)] //debuff icons has some empty horzontal spaces, so add a bit offset to align with them
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = hdpx(2)
  children = [
    @() {
      watch = speed
      rendObj = ROBJ_TEXT
      text = speed.value
    }.__update(fontTiny)
    {
      rendObj = ROBJ_TEXT
      text = loc("measureUnits/kmh")
    }.__update(fontVeryTiny)
  ]
}

let infoBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  pos = [pw(-100), pw(10)]
  padding = [0, hdpx(45)]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  children = [
    speedText
    crewDebuffsRow
    techDebuffsRow
  ]
}

return {
  size = [damagePanelSize, damagePanelSize]
  rendObj = ROBJ_XRAYDOLL
  rotateWithCamera = true
  drawOutlines = false
  drawSilhouette = true
  drawTargetingSightLine = true
  modulateSilhouetteColor = true

  children = [
    {
      size = [damagePanelSize, damagePanelSize]
      behavior = Behaviors.XrayDoll
      transform = {}
      children = moveTypeImage
    }
    infoBlock
  ]
}
