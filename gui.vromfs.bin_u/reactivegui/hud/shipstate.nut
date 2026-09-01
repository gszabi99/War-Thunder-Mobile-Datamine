from "%globalScripts/weaponConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.math" import Point2
from "dagor.random" import rnd_int
import "%sqstd/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
import "%rGui/interopGen.nut" as interopGet


let buoyancy = Watched(1.0)
let fire = Watched(false)
let damagedEnginesCount = Watched(0)
let damagedArtilleryCount = Watched(0)
let brokenTorpedosCount = Watched(0)
let debugDebuff = mkWatched(persist, "debugDebuff", 0)
let blockMoveControl = Watched(false)
let currentMaxThrottle = Watched(1.0)

let isFullBuoyancy = Computed(@() buoyancy.get() == 1.0)
let hasDebuffFire = Computed(@() fire.get() != ((debugDebuff.get() & 1) != 0))
let hasDebuffEngines = Computed(@() (damagedEnginesCount.get() > 0) != ((debugDebuff.get() & 2) != 0))
let hasDebuffFlooding = Computed(@() (buoyancy.get() < 1.0) != ((debugDebuff.get() & 4) != 0))
let hasDebuffGuns = Computed(@() (damagedArtilleryCount.get() > 0) != ((debugDebuff.get() & 8) != 0))
let hasDebuffMoveControl = Computed(@() blockMoveControl.get() != ((debugDebuff.get() & 16) != 0))
let hasDebuffTorpedoes = Computed(@() (brokenTorpedosCount.get() > 0) != ((debugDebuff.get() & 32) != 0))

const maxDebugDebuff = 63
register_command(@() debugDebuff.set(debugDebuff.get() == maxDebugDebuff ? 0 : maxDebugDebuff), "hud.debug.shipDebuffsAll")
register_command(@() debugDebuff.set(rnd_int(0, maxDebugDebuff)), "hud.debug.shipDebuffsRandom")
register_command(function(idx) {
  let bit = 1 << idx
  log(debugDebuff.get())
  debugDebuff.set((debugDebuff.get() & bit) ? (debugDebuff.get() & ~bit) : (debugDebuff.get() | bit))
  log(debugDebuff.get())
}, "hud.debug.shipDebuffsToggle")

let heroHpRepair = mkEcsComputed({
  comps = [
    ["meta_parts_hp_repair__maxHp", ecs.TYPE_FLOAT],
    ["meta_parts_hp_repair__speed", ecs.TYPE_FLOAT],
    ["meta_parts_hp_repair__duration", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["controlledHero"]
})


let maxHpToRepair = Computed(@() heroHpRepair.get()?.meta_parts_hp_repair__maxHp ?? 1.)
let nominalHpToRepair = Computed(function() {
  let state = heroHpRepair.get()
  return state == null ? 0.
    : state.meta_parts_hp_repair__speed * state.meta_parts_hp_repair__duration
})

let shipState = {
  speed = Watched(0)
  steering = Watched(0.0)
  buoyancy
  isFullBuoyancy
  hasDebuffFlooding
  curRelativeHealth = Watched(1.0)
  maxHealth = Watched(1.0)
  fire
  hasDebuffFire
  portSideMachine = Watched(-1)
  sideboardSideMachine = Watched(-1)
  stopping = Watched(false)

  fwdAngle = Watched(0)
  sightAngle = Watched(0)
  fov = Watched(0)

  obstacleIsNear = Watched(false)
  distanceToObstacle = Watched(-1)
  timeToDeath = Watched(-1)
  maxHpToRepair
  nominalHpToRepair

  
  enginesCount = Watched(0)
  brokenEnginesCount = Watched(0)
  damagedEnginesCount
  hasDebuffEngines
  enginesInCooldown = Watched(false)
  blockMoveControl
  currentMaxThrottle

  steeringGearsCount = Watched(0)
  brokenSteeringGearsCount = Watched(0)

  torpedosCount = Watched(0)
  brokenTorpedosCount

  artilleryType = Watched(TRIGGER_GROUP_PRIMARY)
  artilleryCount = Watched(0)
  brokenArtilleryCount = Watched(0)
  damagedArtilleryCount
  hasDebuffGuns
  hasDebuffMoveControl
  hasDebuffTorpedoes

  transmissionCount = Watched(0)
  brokenTransmissionCount = Watched(0)
  transmissionsInCooldown = Watched(false)

  aiGunnersState = Watched(0)
  hasAiGunners = Watched(false)

  waterDist = Watched(0)
  buoyancyEx = Watched(0)
  depthLevel = Watched(0)
  wishDist = Watched(0)
  maxControlDepth = Watched(0.0)
  periscopeDepthCtrl = Watched(0.0)
  deadZoneDepth = Watched(0.0)
  oxygen = Watched(100)
  isTargetRepair = Watched(false)
  targetHp = Watched(0)
  isAsmCaptureAllowed = Watched(true)
  isHrosshairVisibile = Watched(false)
  aimModulePos = Watched(Point2(-1., -1.))
  crosshairDistance = Watched(-1)
}


interopGet({
  stateTable = shipState
  prefix = "ship"
  postfix = "Update"
})


return shipState
