module wtm_events shared
require ecs


[cpp_event(unicast)]
struct CmdRequestSwitchOnSupportPlane
  turnOn : bool
  idx : int
  startAngles : float2
  switchOn : bool

[cpp_event(unicast)]
struct CmdRequestSupportPlaneChange
  idx : int

[cpp_event(unicast)]
struct CmdRequestSupportPlaneGroupAttack
  idx : int
  targetId : int
  attack : bool

[cpp_event(unicast)]
struct CmdReturnAircraftToShip
  idx : int
  rtb : bool


[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdApplyMyBattleResultOnExit {}


[cpp_event(broadcast)]
struct EventOnPlayerDamage
  offenderPlayerId : uint8
  offenderUnitId : int
  victimPlayerId : uint8
  victimUnitId : int
  dmg : float
  fullHp : float

[cpp_event(broadcast)]
struct EventOnZoneDamage
  offenderPlayerId : uint8
  offenderUnitId : int
  zoneId : int
  dmg : float
  allDmg : float
  fullHp : float
  isAirfield : bool

[cpp_event(broadcast)]
struct EventOnPlayerCriticalHit
  offenderPlayerId : uint8
  offenderUnitId : int
  victimPlayerId : uint8
  victimUnitId : int


[cpp_event(broadcast)]
struct EventOnPlayerKill
  offenderPlayerId : uint8
  offenderUnitId : int
  victimPlayerId : uint8
  victimUnitId : int
  dmg : float
  allDmg : float
  fullHp : float
  killerPos : float3
  victimPos : float3
  weaponId : int

[cpp_event(broadcast)]
struct EventOnZoneKill
  offenderPlayerId : uint8
  offenderUnitId : int
  zoneId : int
  dmg : float
  allDmg : float
  fullHp : float
  isAirfield : bool

[cpp_event(broadcast)]
struct EventOnPlayerDeath
  playerId : uint8
  unitId : int
  pos : float3
  weaponId : int


[cpp_event(broadcast)]
struct EventOnPlayerAssist
  offenderPlayerId : uint8
  offenderUnitId : int
  victimPlayerId : uint8
  victimUnitId : int
  dmg : float
  allDmg : float


[cpp_event(broadcast)]
struct EventOnZoneCapture
  playerId : uint8
  unitId : int
  capturePart : float

[cpp_event(broadcast)]
struct EventAddScore
  playerId : uint8
  unitId : int
  value : float
  reason : string

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdGetPlayersStats {}

[cpp_event(broadcast)]
struct EventOnPlayerChangeUnit
  userId : uint64
  unitId : int
  unitVersion : uint8
  unitType : int
  unitName : string


[cpp_event(broadcast)]
struct EventOnPlayerWeaponUse
  userId : uint64
  unitId : int
  unitVersion : uint8
  unitType : int
  weaponId : int

[cpp_event(broadcast)]
struct EventOnPlayerGenericWeaponUse
  userId : uint64
  unitId : int
  unitVersion : uint8
  unitType : int
  triggerGroupMask : int

[cpp_event(broadcast)]
struct EventOnPlayerWeaponDamage
  offenderUserId : uint64
  offenderUnitId : int
  offenderUnitVersion : uint8
  offenderUnitType : int
  offenderTriggerGroup : int
  offenderBulletsBorn : int
  victimUserId : uint64
  victimUnitId : int
  victimUnitVersion : uint8
  victimUnitType : int
  fire : bool
  weaponId : int
  dmg : float

[cpp_event(broadcast)]
struct EventOnPlayerCritHit
  offenderUserId : uint64
  offenderUnitId : int
  offenderUnitVersion : uint8
  offenderUnitType : int
  critType : int
  weaponId : int


[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventSpendItems
  itemId : string
  count : int

[event(broadcast)]
struct EventOnPlayerRepair
  userId : uint8
  hpRepaired : int

[cpp_event(broadcast)]
struct EventOnPlayerRicochetStat
  victimUserId : uint64
  victimUnitId : int
  victimUnitVersion : uint8
  victimUnitType : int


[cpp_event(broadcast)]
struct EventOnPlayerBailout
  userId : uint64
  unitId : int
  isReadyToDie : bool

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventZoneDamageMessage
  score : float
  isAirfield : bool

[cpp_event(unicast)]
struct CmdSetScoreKillMult
  mult : float

[cpp_event(unicast)]
struct CmdBattleRoyalSetNewArea
  x : int
  y : int
  shrinkTime : float
  startDelay : float


[cpp_event(broadcast)]
struct EventRacePlayerCheckpoint
  playerId : int
  checkpoint : int
  lap : int
  cpPerLap : int
  totalLaps : int
  time : float


[cpp_event(broadcast)]
struct EventRacePlayerFinish
  playerId : int
  place : int
  isWinner : bool
  totalTime : float
