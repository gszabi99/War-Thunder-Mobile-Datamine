from "%globalsDarg/darg_library.nut" import *
import "%sqstd/ecs.nut" as ecs
let interopGet = require("%rGui/interopGen.nut")
let { register_command } = require("console")
let { rnd_int } = require("dagor.random")

let buoyancy = Watched(1.0)
let fire = Watched(false)
let damagedEnginesCount = Watched(0)
let damagedArtilleryCount = Watched(0)
let brokenTorpedosCount = Watched(0)
let debugDebuff = mkWatched(persist, "debugDebuff", 0)
let blockMoveControl = Watched(false)
let currentMaxThrottle = Watched(1.0)

let isFullBuoyancy = Computed(@() buoyancy.value == 1.0)
let hasDebuffFire = Computed(@() fire.value != ((debugDebuff.value & 1) != 0))
let hasDebuffEngines = Computed(@() (damagedEnginesCount.value > 0) != ((debugDebuff.value & 2) != 0))
let hasDebuffFlooding = Computed(@() (buoyancy.value < 1.0) != ((debugDebuff.value & 4) != 0))
let hasDebuffGuns = Computed(@() (damagedArtilleryCount.value > 0) != ((debugDebuff.value & 8) != 0))
let hasDebuffMoveControl = Computed(@() blockMoveControl.value != ((debugDebuff.value & 16) != 0))
let hasDebuffTorpedoes = Computed(@() (brokenTorpedosCount.value > 0) != ((debugDebuff.value & 32) != 0))

let maxDebugDebuff = 63
register_command(@() debugDebuff(debugDebuff.value == maxDebugDebuff ? 0 : maxDebugDebuff), "hud.debug.shipDebuffsAll")
register_command(@() debugDebuff(rnd_int(0, maxDebugDebuff)), "hud.debug.shipDebuffsRandom")
register_command(function(idx) {
  let bit = 1 << idx
  log(debugDebuff.value)
  debugDebuff((debugDebuff.value & bit) ? (debugDebuff.value & ~bit) : (debugDebuff.value | bit))
  log(debugDebuff.value)
}, "hud.debug.shipDebuffsToggle")

let maxHpToRepair = Watched(0.)
let nominalHpToRepair = Watched(0.)
ecs.register_es("maxHpToRepairTracker", {
  [["onInit", "onChange"]] = function trackMaxHpToRepair(_eid, comp) {
    maxHpToRepair(comp.meta_parts_hp_repair__maxHp)
    nominalHpToRepair(comp.meta_parts_hp_repair__speed * comp.meta_parts_hp_repair__duration)
  },
  function onDestroy() {
    maxHpToRepair(1.)
  }
},
{
  comps_track = [["meta_parts_hp_repair__maxHp", ecs.TYPE_FLOAT]],
  comps_ro = [["meta_parts_hp_repair__speed", ecs.TYPE_FLOAT], ["meta_parts_hp_repair__duration", ecs.TYPE_FLOAT]],
  comps_rq = ["controlledHero"]
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

  //DM:
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

  leftTurretRotationTime = Watched(0)
  isHrosshairVisibile = Watched(false)
}


interopGet({
  stateTable = shipState
  prefix = "ship"
  postfix = "Update"
})


return shipState
