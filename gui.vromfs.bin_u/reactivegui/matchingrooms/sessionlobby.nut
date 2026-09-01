from "%globalScripts/gameModeNativeConsts.nut" import *
from "%globalScripts/playerStateConsts.nut" import *
from "%globalScripts/difficultyConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "dagor.debug" import debug_dump_stack
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "gameplayBinding" import inFlightMenu, isInFlight
from "guiMission" import leave_mp_session, quit_to_debriefing, interrupt_multiplayer
from "guiOptions" import get_cd_preset
from "matching.errors" import SERVER_ERROR_ROOM_PASSWORD_MISMATCH, INVALID_ROOM_ID
from "mission" import set_game_mode, get_game_mode, get_game_type
from "multiplayer" import get_mp_session_id_str, destroy_session
from "string" import format
from "%sqstd/datablock.nut" import convertBlk
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/string.nut" import tostring_r
from "%sqstd/underscore.nut" import isEqual, isDataBlock
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInLoadingScreen, isInMenu
from "%appGlobals/gameModes/gameModes.nut" import gameModesRaw
from "%appGlobals/loginState.nut" import isLoggedIn, isMatchingOnline
from "%rGui/matching/matchingApi.nut" import matchingRpcCall, matchingRpcRegisterHandler, matching_subscribe
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/profileStates.nut" import myUserId, myUserName
from "%appGlobals/sessionLobbyState.nut" import lobbyStates, sessionLobbyStatus
from "guiScriptUtils" import set_host_cb
from "online" import is_online_available, connect_to_host_list
from "scriptErrorHandler" import script_net_assert

from "%rGui/matching/queuesClient.nut" import destroyQueue, leaveQueue
import "%rGui/matching/showMatchingError.nut" as showMatchingError
from "%rGui/missions/missionsUtils.nut" import missionAvailabilityFlag, isAvailableByMissionSettings
from "%appGlobals/errorMsgBox.nut" import errorMsgBox, lastSessionDebugInfo
from "%rGui/webRPC.nut" import webRpcRegister
from "types" import String, Array, Integer, Table


let getTblValue = @(key, tbl, defValue = null) key in tbl ? tbl[key] : defValue
let isInArray = @(v, arr) arr.contains(v)


function is_my_userid(user_id) {
  if (user_id instanceof String)
    return user_id == myUserId.get().tostring()
  return user_id == myUserId.get()
}
















const NET_SERVER_LOST = 0x82220002  
const NET_SERVER_QUIT_FROM_GAME = 0x82220003

local last_round = true
local SessionLobby
let isGameModeCoop = @(gm) gm == -1 || gm == GM_SINGLE_MISSION || gm == GM_BUILDER

let allowed_mission_settings = { 
                              
  name = null
  missionURL = null
  players = 12
  hidden = false  

  creator = ""
  hasPassword = false
  cluster = ""
  allowJIP = true
  coop = true
  friendOnly = false
  country_allies = ["country_ussr"]
  country_axis = ["country_germany"]

  mission = {
     name = "stalingrad_GSn"
     loc_name = ""
     postfix = ""
     _gameMode = 12
     _gameType = 0
     difficulty = "arcade"
     custDifficulty = "0"
     environment = "Day"
     weather = "clear"

     maxRespawns = -1
     timeLimit = 0
     killLimit = 0

     raceLaps = 1
     raceWinners = 1
     raceForceCannotShoot = false

     isBotsAllowed = true
     useTankBots = false
     ranks = {}
     useShipBots = false
     keepDead = true
     isLimitedAmmo = false
     isLimitedFuel = false
     optionalTakeOff = false
     dedicatedReplay = false
     allowWebUi = -1
     useKillStreaks = false
     disableAirfields = false
     spawnAiTankOnTankMaps = true

     isHelicoptersAllowed = false
     isAirplanesAllowed = false
     isTanksAllowed = false
     isShipsAllowed = false

     takeoffMode = 0
     currentMissionIdx = -1
     allowedTagsPreset = ""

     locName = ""
     locDesc = ""
  }
}

let matchingUnitTypes = [SHIP, AIR, HELICOPTER, TANK]




let SessionLobbyState = hardPersistWatched("SessionLobbyState", {
  roomId = INVALID_ROOM_ID
  settings = {}
  status = lobbyStates.NOT_IN_ROOM
  isRoomInSession = false
  isRoomOwner = false
  isRoomByQueue = false
  roomUpdated = false
  password = ""

  members = []
  memberHostId = -1

  isReady = false
  myState = PLAYER_IN_LOBBY_NOT_READY

  needJoinSessionAfterMyInfoApply = false
}).get()

let lastRoom = mkWatched(persist, "lastRoom")
let lastRoomId = Computed(@() lastRoom.get()?.roomId ?? INVALID_ROOM_ID)
let roomInfo = mkWatched(persist, "roomInfo")
let MRoomsHandlersState  = hardPersistWatched("MRoomsHandlersState", {
  hostId = null  
  roomId = INVALID_ROOM_ID
  roomMembers = []
  isConnectAllowed = false
  roomOps = {}
  isHostReady = false
  isSelfReady = false
  isLeaving = false
}).get()



function notify_room_invite(params) {
  log("notify_room_invite")
  

  if (!isInMenu.get() && isLoggedIn.get()) {
    log("Invite rejected: player is already in flight or in loading level or in unloading level");
    return false
  }

  let senderId = ("senderId" in params) ? params.senderId : null
  let password = getTblValue("password", params, null)
  if (!senderId) 
    SessionLobby.joinRoom(params.roomId, senderId, password)
  return true
}

function notify_room_destroyed(params) {
  log("notify_room_destroyed")
  

  SessionLobby.afterLeaveRoom(params)
}

function notify_room_member_joined(params) {
  log("notify_room_member_joined")
  
  SessionLobby.onMemberJoin(params)
}

function notify_room_member_leaved(params) {
  log("notify_room_member_leaved")
  SessionLobby.onMemberLeave(params)
}

function notify_room_member_kicked(params) {
  log("notify_room_member_kicked")
  SessionLobby.onMemberLeave(params, true)
}

function notify_room_member_attribs_changed(params) {
  log("notify_room_member_attribs_changed")
  SessionLobby.onMemberInfoUpdate(params)
}

function notify_room_attribs_changed(params) {
  log("notify_room_attribs_changed")
  

  SessionLobby.onSettingsChanged(params)
}

local g_mrooms_handlers

eventbus_subscribe("on_cannot_create_session", @(...) openFMsgBox({ text = loc("NET_CANNOT_CREATE_SESSION") }))

eventbus_subscribe("notify_session_start", function notify_session_start(...) {
  let sessionId = get_mp_session_id_str()
  if (sessionId != "")
    lastSessionDebugInfo.set($"sid:{sessionId}")

  log("notify_session_start")
  SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
})

local delayedJoinRoomFunc = null

let getMaxEconomicRank = @() 30 

SessionLobby = {

  function isInRoom() {
    return SessionLobbyState.status != lobbyStates.NOT_IN_ROOM
      && SessionLobbyState.status != lobbyStates.WAIT_FOR_QUEUE_ROOM
      && SessionLobbyState.status != lobbyStates.CREATING_ROOM
      && SessionLobbyState.status != lobbyStates.JOINING_ROOM
  }

  function isWaitForQueueRoom() {
    return SessionLobbyState.status == lobbyStates.WAIT_FOR_QUEUE_ROOM
  }

  function setWaitForQueueRoom(set) {
    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM || SessionLobbyState.status == lobbyStates.WAIT_FOR_QUEUE_ROOM)
      this.switchStatus(set ? lobbyStates.WAIT_FOR_QUEUE_ROOM : lobbyStates.NOT_IN_ROOM)
  }

  function leaveWaitForQueueRoom() {
    if (!this.isWaitForQueueRoom())
      return

    this.setWaitForQueueRoom(false)
    openFMsgBox({ text = loc("NET_CANNOT_ENTER_SESSION") })
  }

  function findParam(key, tbl1, tbl2) {
    if (key in tbl1)
      return tbl1[key]
    if (key in tbl2)
      return tbl2[key]
    return null
  }

  function prepareSettings(missionSettings) {
    let _settings = {}
    let mission = missionSettings.mission

    foreach (key, v in allowed_mission_settings) {
      if (key == "mission")
        continue
      local value = this.findParam(key, missionSettings, mission)
      if (v instanceof Array && !(value instanceof Array))
        value = [value]
      _settings[key] <- value 
    }

    _settings.mission <- {}
    foreach (key, _v in allowed_mission_settings.mission) {
      local value = this.findParam(key, mission, missionSettings)
      if (key == "postfix")
        value = getTblValue(key, missionSettings)
      if (value == null)
        continue

      _settings.mission[key] <- isDataBlock(value) ? convertBlk(value) : value
    }

    _settings.creator <- myUserName.get()
    _settings.mission.originalMissionName <- getTblValue("name", _settings.mission, "")
    if ("postfix" in _settings.mission && _settings.mission.postfix) {
      const ending = "_tm"
      local nameNoTm = _settings.mission.name
      if (nameNoTm.len() > ending.len() && nameNoTm.slice(nameNoTm.len() - ending.len()) == ending)
        nameNoTm = nameNoTm.slice(0, nameNoTm.len() - ending.len())
      _settings.mission.loc_name = "".concat(nameNoTm, _settings.mission.postfix)
      _settings.mission.name = "".concat(_settings.mission.name, _settings.mission.postfix)
    }
    if (!("_gameMode" in _settings.mission))
      _settings.mission._gameMode <- get_game_mode()
    if (!("_gameType" in _settings.mission))
      _settings.mission._gameType <- get_game_type()
    if (getTblValue("coop", _settings) == null)
      _settings.coop <- isGameModeCoop(_settings.mission._gameMode)
    if (("difficulty" in _settings.mission) && _settings.mission.difficulty == "custom")
      _settings.mission.custDifficulty <- get_cd_preset(DIFFICULTY_CUSTOM)

    let userAllowedUnitTypesMask = missionSettings?.userAllowedUnitTypesMask ?? 0
    if (userAllowedUnitTypesMask)
      foreach (unitType in matchingUnitTypes)
        if (unitType in missionAvailabilityFlag
            && isAvailableByMissionSettings(_settings.mission, unitType)
            && !(userAllowedUnitTypesMask & unitTypeToBit(unitType)))
          _settings.mission[missionAvailabilityFlag[unitType]] = false

    local mrankMin = missionSettings?.mrankMin ?? 0
    local mrankMax = missionSettings?.mrankMax ?? getMaxEconomicRank()
    if (mrankMin > mrankMax) {
      let temp = mrankMin
      mrankMin = mrankMax
      mrankMax = temp
    }
    if (mrankMin > 0 || mrankMax < getMaxEconomicRank())
      _settings.mranks <- { min = mrankMin, max = mrankMax }

    if ((SessionLobbyState.settings?.externalSessionId ?? "") != "")
      _settings.externalSessionId <- SessionLobbyState.settings.externalSessionId
    if ((SessionLobbyState.settings?.psnMatchId ?? "") != "")
      _settings.psnMatchId <- SessionLobbyState.settings.psnMatchId

    this.checkDynamicSettings(true, _settings)
    this.setSettings(_settings)
  }

  function setSettings(v_settings, notify = false, checkEqual = true) {
    if (v_settings instanceof Array) {
      log("v_settings param, public info, is array, instead of table")
      debug_dump_stack()
      return
    }

    if (checkEqual && isEqual(SessionLobbyState.settings, v_settings))
      return

    
    SessionLobbyState.settings.replace_with(v_settings)
    
    SessionLobbyState.settings.connect_on_join <- true

    SessionLobbyState.roomUpdated = notify || !SessionLobbyState.isRoomOwner || !this.isInRoom()
    if (!SessionLobbyState.roomUpdated)
      matchingRpcCall("mrooms.set_attributes",
        { roomId = SessionLobbyState.roomId, public = SessionLobbyState.settings },
        "onSetAttributes")

    let newGm = this.getGameMode()
    if (newGm >= 0)
      set_game_mode(newGm)
  }

  function checkDynamicSettings(silent = false, v_settings = null) {
    if (!SessionLobbyState.isRoomOwner && this.isInRoom())
      return

    if (!v_settings) {
      if (!SessionLobbyState.settings || !SessionLobbyState.settings.len())
        return 
      v_settings = SessionLobbyState.settings
    }
    else
      silent = true 

    local changed = false
    let wasHidden = getTblValue("hidden", v_settings, false)
    v_settings.hidden <- getTblValue("coop", v_settings, false)
                        || (SessionLobbyState.isRoomInSession && !getTblValue("allowJIP", v_settings, true))
    changed = changed || (wasHidden != v_settings.hidden) 

    let wasPassword = getTblValue("hasPassword", v_settings, false)
    v_settings.hasPassword <- SessionLobbyState.password != ""
    changed = changed || (wasPassword != v_settings.hasPassword)

    if (changed && !silent)
      this.setSettings(SessionLobbyState.settings, false, false)
  }

  function onSettingsChanged(p) {
    if (SessionLobbyState.roomId != p.roomId)
      return
    let set = getTblValue("public", p)
    if (!set)
      return

    if ("last_round" in set) {
      last_round = set.last_round
      log($"last round {last_round}")
    }

    let newSet = clone SessionLobbyState.settings
    foreach (k, v in set)
      if (v == null) {
        newSet?.$rawdelete(k)
      }
      else
        newSet[k] <- v

    this.setSettings(newSet, true)

    this.setRoomInSession(this.isSessionStartedInRoom())
  }

  function setRoomInSession(newIsInSession) {
    if (newIsInSession == SessionLobbyState.isRoomInSession)
      return

    SessionLobbyState.isRoomInSession = newIsInSession
    if (!this.isInRoom())
      return

    if (SessionLobbyState.isRoomOwner)
      this.checkDynamicSettings()
  }

  function getMissionName(isOriginalName = false, room = null) {
    let misData = this.getMissionData(room)
    return isOriginalName ? (misData?.originalMissionName ?? "") : (misData?.name ?? "")
  }

  function getPublicData(room = null) {
    return room ? (("public" in room) ? room.public : room) : SessionLobbyState.settings
  }

  function getMissionData(room = null) {
    return getTblValue("mission", this.getPublicData(room))
  }

  function getGameMode(room = null) {
    return getTblValue("_gameMode", this.getMissionData(room), GM_DOMINATION)
  }

  function getGameType(room = null) {
    let res = getTblValue("_gameType", this.getMissionData(room), 0)
    return res instanceof Integer ? res : 0
  }

  function getMGameModeId(room = null) {
    return getTblValue("game_mode_id", this.getPublicData(room))
  }

  function getPublicParam(name, defValue = "") {
    if (name in SessionLobbyState.settings)
      return SessionLobbyState.settings[name]
    return defValue
  }

  function switchStatus(v_status) {
    if (SessionLobbyState.status == v_status)
      return

    let wasStatus = SessionLobbyState.status
    SessionLobbyState.status = v_status  
    sessionLobbyStatus.set(v_status)

    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM || SessionLobbyState.status == lobbyStates.IN_DEBRIEFING)
      this.setReady(false, true)
    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM) {
      this.resetParams()
      if (wasStatus == lobbyStates.JOINING_SESSION)
        destroy_session("on leave room while joining session")
    }

    this.updateMyState()
  }

  function resetParams() {
    SessionLobbyState.settings.clear()
    this.changePassword("") 
    this.updateMemberHostParams(null)
    SessionLobbyState.isRoomByQueue = false
    SessionLobbyState.myState = PLAYER_IN_LOBBY_NOT_READY
    SessionLobbyState.roomUpdated = false
    SessionLobbyState.needJoinSessionAfterMyInfoApply = false
  }

  function switchStatusChecked(oldStatusList, newStatus) {
    if (isInArray(SessionLobbyState.status, oldStatusList))
      this.switchStatus(newStatus)
  }

  function changePassword(v_password) {
    if (!(v_password instanceof String) || SessionLobbyState.password == v_password)
      return

    if (SessionLobbyState.isRoomOwner && SessionLobbyState.status != lobbyStates.NOT_IN_ROOM
        && SessionLobbyState.status != lobbyStates.CREATING_ROOM)
      matchingRpcCall("mrooms.set_password",
        { roomId = SessionLobbyState.roomId, password = v_password },
        { id = "onSetPasswrod", prevPass = SessionLobbyState.password })
    SessionLobbyState.password = v_password
  }

  function mergeTblChanges(tblBase, tblNew) {
    if (tblNew == null)
      return tblBase

    foreach (key, value in tblNew)
      if (value != null)
        tblBase[key] <- value
      else if (key in tblBase)
        tblBase.$rawdelete(key)
    return tblBase
  }

  function updateMemberHostParams(member = null) { 
    SessionLobbyState.memberHostId = member ? member.memberId : -1
  }


  function updateReady(ready) {
    SessionLobbyState.isReady = ready
  }

  function onMemberInfoUpdate(params) {
    if (params.roomId != SessionLobbyState.roomId)
      return
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(params)

    local member = null
    foreach (m in SessionLobbyState.members)
      if (m.memberId == params.memberId) {
        member = m
        break
      }
    if (!member)
      return

    foreach (tblName in ["public", "private"])
      if (tblName in params)
        if (tblName in member)
          this.mergeTblChanges(member[tblName], params[tblName])
        else
          member[tblName] <- params[tblName]

    if (is_my_userid(member.userId)) {
      SessionLobbyState.isRoomOwner = this.isMemberOperator(member)
      let ready = getTblValue("ready", getTblValue("public", member, {}), null)
      if (ready != null && ready != SessionLobbyState.isReady)
        this.updateReady(ready)
      else if (SessionLobbyState.needJoinSessionAfterMyInfoApply)
        this.tryJoinSession()
      SessionLobbyState.needJoinSessionAfterMyInfoApply = false
    }
  }

  function updateMyState(_silent = false) {
    local newState = PLAYER_IN_LOBBY_NOT_READY
    if (SessionLobbyState.status == lobbyStates.IN_LOBBY || SessionLobbyState.status == lobbyStates.START_SESSION)
      newState = SessionLobbyState.isReady ? PLAYER_IN_LOBBY_READY : PLAYER_IN_LOBBY_NOT_READY
    else if (SessionLobbyState.status == lobbyStates.IN_LOBBY_HIDDEN)
      newState = PLAYER_IN_LOBBY_READY
    else if (SessionLobbyState.status == lobbyStates.IN_SESSION)
      newState = PLAYER_IN_FLIGHT
    else if (SessionLobbyState.status == lobbyStates.IN_DEBRIEFING)
      newState = PLAYER_IN_STATISTICS_BEFORE_LOBBY

    SessionLobbyState.myState = newState
    return SessionLobbyState.myState
  }

  function setReady(ready, _silent = false, forceRequest = false) { 
    if (!forceRequest && SessionLobbyState.isReady == ready)
      return false

    if (!this.isInRoom()) {
      SessionLobbyState.isReady = false
      return ready
    }

    matchingRpcCall("mrooms.set_ready_state",
      { state = ready, roomId = SessionLobbyState.roomId },
      { id = "onSetReady", ready, roomId = SessionLobbyState.roomId })
    return true
  }

  function afterRoomCreation(params) {
    if (showMatchingError(params))
      return this.switchStatus(lobbyStates.NOT_IN_ROOM)

    SessionLobbyState.isRoomOwner = true
    SessionLobbyState.isRoomByQueue = false
    this.afterRoomJoining(params)
  }

  function destroyRoom() {
    if (!SessionLobbyState.isRoomOwner)
      return

    matchingRpcCall("mrooms.destroy_room", { roomId = SessionLobbyState.roomId })
    SessionLobby.afterLeaveRoom({})
  }

  function leaveRoom() {
    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM || SessionLobbyState.status == lobbyStates.WAIT_FOR_QUEUE_ROOM) {
      this.setWaitForQueueRoom(false)
      return
    }

    MRoomsHandlersState.isLeaving = true
    matchingRpcCall("mrooms.leave_room", {}, { id = "onRoomLeave", roomId = g_mrooms_handlers.getRoomId() })
  }

  function checkLeaveRoomInDebriefing() {
    if (!last_round)
      return;

    if (this.isInRoom())
      this.leaveRoom()
  }

  function afterLeaveRoom(_p) {
    if (delayedJoinRoomFunc != null) {
      deferOnce(delayedJoinRoomFunc)
      delayedJoinRoomFunc = null
    }

    SessionLobbyState.roomId = INVALID_ROOM_ID
    this.switchStatus(lobbyStates.NOT_IN_ROOM)
  }

  function sendJoinRoomRequest(join_params, _cb = function(...) {}) {
    if (this.isInRoom())
      this.leaveRoom() 

    leave_mp_session()

    if (!SessionLobbyState.isRoomOwner) {
      this.setSettings({})
      SessionLobbyState.members.clear()
    }

    lastSessionDebugInfo.set(
      ("roomId" in join_params) ? ($"room: { join_params.roomId }") :
      ("battleId" in join_params) ? ($"battle: { join_params.battleId }") :
      ""
    )

    this.switchStatus(lobbyStates.JOINING_ROOM)
    matchingRpcCall("mrooms.join_room", join_params,
      { id = "onRoomJoin", roomId = join_params?.roomId, password = join_params?.password })
  }

  function joinBattle(battleId) {
    destroyQueue()
    SessionLobbyState.isRoomOwner = false
    SessionLobbyState.isRoomByQueue = false
    this.sendJoinRoomRequest({ battleId = battleId })
  }

  function joinRoom(v_roomId, senderId = "", v_password = null,
                                  cb = function(...) {}) { 
    if (SessionLobbyState.roomId == v_roomId && this.isInRoom())
      return

    if (!isLoggedIn.get() || this.isInRoom()) {
      delayedJoinRoomFunc = @() SessionLobby.joinRoom(v_roomId, senderId, v_password, cb)

      if (this.isInRoom())
        this.leaveRoom()
      return
    }

    SessionLobbyState.isRoomOwner = is_my_userid(senderId)
    SessionLobbyState.isRoomByQueue = senderId == null

    if (SessionLobbyState.isRoomByQueue)
      destroyQueue()
    else
      leaveQueue()

    if (v_password && v_password.len())
      this.changePassword(v_password)

    let joinParams = { roomId = v_roomId }
    if (SessionLobbyState.password != "")
      joinParams.password <- SessionLobbyState.password

    this.sendJoinRoomRequest(joinParams, cb)
  }

  function joinRoomWithPassword(joinRoomId, _prevPass = "", _wasEntered = false) {
    if (joinRoomId == "") {
      assert(false, "SessionLobby Error: try to join room with password with empty room id")
      return
    }
    logerr("Rooms with password not supported yet")
  }

  function afterRoomJoining(params) {
    SessionLobbyState.roomId = params.roomId
    SessionLobbyState.roomUpdated = true
    SessionLobbyState.members.replace(getTblValue("members", params, []))

    let public = getTblValue("public", params, SessionLobbyState.settings)
    if (!SessionLobbyState.isRoomOwner || SessionLobbyState.settings.len() == 0) {
      this.setSettings(public)

      if (SessionLobbyState.isRoomByQueue && !this.isSessionStartedInRoom())
        SessionLobbyState.isRoomByQueue = false
    }

    for (local i = SessionLobbyState.members.len() - 1; i >= 0; i--)
      if (this.isMemberHost(SessionLobbyState.members[i])) {
        this.updateMemberHostParams(SessionLobbyState.members[i])
        SessionLobbyState.members.remove(i)
      }
      else if (is_my_userid(SessionLobbyState.members[i].userId))
          SessionLobbyState.isRoomOwner = this.isMemberOperator(SessionLobbyState.members[i])

    this.returnStatusToRoom()
    this.checkAutoStart()

    last_round = getTblValue("last_round", public, true)
    this.setRoomInSession(this.isSessionStartedInRoom())
  }

  function returnStatusToRoom() {
    local newStatus = lobbyStates.IN_ROOM
    this.switchStatus(newStatus)
  }

  function isMemberOperator(member) {
    return ("public" in member) && ("operator" in member.public) && member.public.operator
  }

  function isMemberHost(m) {
    return (m.memberId == SessionLobbyState.memberHostId || (("public" in m) && ("host" in m.public) && m.public.host))
  }

  function isSessionStartedInRoom(room = null) {
    return getTblValue("hasSession", this.getPublicData(room), false)
  }

  function checkAutoStart() {
    if (SessionLobbyState.isRoomOwner && !SessionLobbyState.isRoomByQueue && SessionLobbyState.roomUpdated)
      this.startSession()
  }

  function startSession() {
    if (SessionLobbyState.status != lobbyStates.IN_ROOM && SessionLobbyState.status != lobbyStates.IN_LOBBY && SessionLobbyState.status != lobbyStates.IN_LOBBY_HIDDEN)
      return
    log("start session")

    matchingRpcCall("mrooms.start_session",
      { roomId = SessionLobbyState.roomId, cluster = this.getPublicParam("cluster", "EU") },
      "onStartSession")
    this.switchStatus(lobbyStates.START_SESSION)
  }

  function hostCb(res) {
    if (!(res instanceof Table) || "errCode" not in res)
      return

    let errorCode = res.errCode != 0 ? res.errCode
      : get_game_mode() == GM_DOMINATION ? NET_SERVER_LOST
      : NET_SERVER_QUIT_FROM_GAME

    if (this.isInRoom())
      this.leaveRoom()

    errorMsgBox(errorCode,
      [{ id = "ok", eventId = "destroySession", styleId = "PRIMARY", isDefault = true }],
      { isPersist = true })
  }

  function onMemberJoin(params) {
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(params)

    foreach (m in SessionLobbyState.members)
      if (m.memberId == params.memberId) {
        this.onMemberInfoUpdate(params)
        return
      }
    SessionLobbyState.members.append(params)
    this.checkAutoStart()
  }

  function onMemberLeave(params, kicked = false) {
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(null)

    foreach (idx, m in SessionLobbyState.members)
      if (params.memberId == m.memberId) {
        SessionLobbyState.members.remove(idx)
        if (is_my_userid(m.userId)) {
          this.afterLeaveRoom({})
          if (kicked) {
            if (!isInMenu.get()) {
              quit_to_debriefing()
              interrupt_multiplayer(true)
              inFlightMenu(false)
            }
            openFMsgBox({ text = loc("matching/msg_kicked"), isPersist = true })
          }
        }
        break
      }
  }

  function rpcJoinBattle(params) {
    if (!is_online_available())
      return "client not ready"
    let battleId = params.battleId
    if (!(battleId instanceof String))
      return "bad battleId type"
    if (SessionLobby.isInRoom())
      return "already in room"
    if (isInFlight())
      return "already in session"

    log($"join to battle with id {battleId}")
    SessionLobby.joinBattle(battleId)
    return "ok"
  }

  getMGameMode = @(room = null, _isCustomGameModeAllowed = true)
    gameModesRaw.get()?[this.getMGameModeId(room)]

  getRoomEvent = @(room = null) this.getMGameMode(room)

  function canJoinSession() {
    return SessionLobbyState.isRoomInSession
  }

  function tryJoinSession() {
     if (!this.canJoinSession())
       return false

     if (SessionLobbyState.isRoomInSession) {
       this.setReady(true)
       return true
     }
     return false
  }

}

isLoggedIn.subscribe(@(v) v ? null : SessionLobby.leaveRoom())

subscribeFMsgBtns({
  destroySession = @(_) destroy_session("after error message from host")
})

isInLoadingScreen.subscribe(function(v) {
  if (v)
    return

  if (isInFlight())
    SessionLobby.switchStatusChecked(
      [lobbyStates.IN_ROOM, lobbyStates.IN_LOBBY, lobbyStates.IN_LOBBY_HIDDEN,
       lobbyStates.JOINING_SESSION],
      lobbyStates.IN_SESSION
    )
  else
    SessionLobby.switchStatusChecked(
      [lobbyStates.IN_SESSION, lobbyStates.JOINING_SESSION],
      lobbyStates.IN_DEBRIEFING
    )
})

webRpcRegister("join_battle", SessionLobby.rpcJoinBattle)

isMatchingOnline.subscribe(@(_) SessionLobby.leaveRoom())

isInDebriefing.subscribe(@(v) v ? SessionLobby.checkLeaveRoomInDebriefing() : null)

let setHostCb = @() set_host_cb(null, @(p) SessionLobby.hostCb(p))
if (isLoggedIn.get())
  setHostCb()
isLoggedIn.subscribe(function(v) {
  if (!v)
    return
  setHostCb()
})

foreach (notificationName, callback in
  {
    ["match.notify_wait_for_session_join"] = @(_params) SessionLobby.setWaitForQueueRoom(true),

    ["match.notify_join_session_aborted"] = @(_params) SessionLobby.leaveWaitForQueueRoom()
  }
)
  matching_subscribe(notificationName, callback)

eventbus_subscribe("cancelJoiningSession", function(_) {
  destroy_session("on cancel joining session")
  SessionLobby.leaveRoom()
})

eventbus_subscribe("on_connection_failed", function on_connection_failed(evt) {
  let text = evt.reason
  if (!SessionLobby.isInRoom())
    return
  destroy_session("on connection failed while in the room")
  SessionLobby.leaveRoom()
  openFMsgBox({ text })
})

eventbus_subscribe("setWaitForQueueRoom", @(v) SessionLobby.setWaitForQueueRoom(v))

let MRoomsHandlers = class {

  constructor() {
    MRoomsHandlersState.roomMembers.clear()
    MRoomsHandlersState.roomOps.clear()

    foreach (notificationName, callback in
              {
                ["*.on_room_invite"] = this.onRoomInvite.bindenv(this),
                ["mrooms.on_host_notify"] = this.onHostNotify.bindenv(this),
                ["mrooms.on_room_member_joined"] = this.onRoomMemberJoined.bindenv(this),
                ["mrooms.on_room_member_leaved"] = this.onRoomMemberLeft.bindenv(this),
                ["mrooms.on_room_attributes_changed"] = this.onRoomAttrChanged.bindenv(this),
                ["mrooms.on_room_member_attributes_changed"] = this.onRoomMemberAttrChanged.bindenv(this),
                ["mrooms.on_room_destroyed"] = this.onRoomDestroyed.bindenv(this),
                ["mrooms.on_room_member_kicked"] = this.onRoomMemberKicked.bindenv(this)
              }
            )
      matching_subscribe(notificationName, callback)
  }

  function getRoomId() {
    return MRoomsHandlersState.roomId
  }

  function hasSession() {
    return MRoomsHandlersState.hostId != null
  }

  function isPlayerRoomOperator(user_id) {
    return (user_id in MRoomsHandlersState.roomOps)
  }

  function __cleanupRoomState() {
    if (roomInfo.get() == null)
      return

    MRoomsHandlersState.hostId = null
    MRoomsHandlersState.roomId = INVALID_ROOM_ID
    roomInfo.set(null)
    MRoomsHandlersState.roomMembers.clear()
    MRoomsHandlersState.roomOps.clear()
    MRoomsHandlersState.isConnectAllowed = false
    MRoomsHandlersState.isHostReady = false
    MRoomsHandlersState.isSelfReady = false
    MRoomsHandlersState.isLeaving = false

    notify_room_destroyed({})
  }

  function __onHostConnectReady() {
    MRoomsHandlersState.isHostReady = true
    if (MRoomsHandlersState.isSelfReady)
      this.__connectToHost()
  }

  function __onSelfReady() {
    MRoomsHandlersState.isSelfReady = true
    if (MRoomsHandlersState.isHostReady)
      this.__connectToHost()
  }

  function __addRoomMember(member) {
    if (getTblValue("operator", member.public))
      MRoomsHandlersState.roomOps[member.userId] <- true

    if (getTblValue("host", member.public)) {
      log(format("found host %s (%s)", member.name, member.userId.tostring()))
      MRoomsHandlersState.hostId = member.userId
    }

    let curMember = this.__getRoomMember(member.userId)
    if (curMember == null)
      MRoomsHandlersState.roomMembers.append(member)
    this.__updateMemberAttributes(member, curMember)
  }

  function __getRoomMember(user_id) {
    foreach (_idx, member in MRoomsHandlersState.roomMembers)
      if (member.userId == user_id)
        return member
    return null
  }

  function __getMyRoomMember() {
    foreach (_idx, member in MRoomsHandlersState.roomMembers)
      if (is_my_userid(member.userId))
        return member
    return null
  }

  function __removeRoomMember(user_id) {
    foreach (idx, member in MRoomsHandlersState.roomMembers) {
      if (member.userId == user_id) {
        MRoomsHandlersState.roomMembers.remove(idx)
        break
      }
    }

    if (user_id == MRoomsHandlersState.hostId) {
      MRoomsHandlersState.hostId = null
      MRoomsHandlersState.isConnectAllowed = false
      MRoomsHandlersState.isHostReady = false
    }

    if (user_id in MRoomsHandlersState.roomOps)
      MRoomsHandlersState.roomOps.$rawdelete(user_id)

    if (is_my_userid(user_id))
      this.__cleanupRoomState()
  }

  function __updateMemberAttributes(member, cur_member = null) {
    if (cur_member == null)
      cur_member = this.__getRoomMember(member.userId)
    if (cur_member == null) {
      log(format("failed to update member attributes. member not found in room %s",
                          member.userId.tostring()))
      return
    }
    this.__mergeAttribs(member, cur_member)

    if (member.userId == MRoomsHandlersState.hostId) {
      if (member?.public.connect_ready ?? false)
        this.__onHostConnectReady()
    }
    else if (is_my_userid(member.userId)) {
      let readyStatus = member?.public.ready
      if (readyStatus == true)
        this.__onSelfReady()
      else if (readyStatus == false)
        MRoomsHandlersState.isSelfReady = false
    }
  }

  function __mergeAttribs(attr_from, attr_to) {
    if (!attr_to)
      return attr_to
    let updateAttribs = function(upd_data, attribs) {
      foreach (key, value in upd_data) {
        if (value == null && (key in attribs))
          attribs.$rawdelete(key)
        else
          attribs[key] <- value
      }
    }

    let pub = getTblValue("public", attr_from)
    let priv = getTblValue("private", attr_from)

    if (priv instanceof Table) {
      if ("private" in attr_to)
        updateAttribs(priv, attr_to.private)
      else
        attr_to.private <- priv
    }
    if (pub instanceof Table) {
      if ("public" in attr_to)
        updateAttribs(pub, attr_to.public)
      else
        attr_to.public <- pub
    }
    return attr_to
  }

  function __isNotifyForCurrentRoom(notify) {
    
    return !MRoomsHandlersState.isLeaving && MRoomsHandlersState.roomId != INVALID_ROOM_ID && MRoomsHandlersState.roomId == notify.roomId
  }

  function __connectToHost() {
    log("__connectToHost")
    if (!this.hasSession())
      return

    let host = this.__getRoomMember(MRoomsHandlersState.hostId)
    if (!host) {
      log("__connectToHost failed: host is not in the room")
      return
    }

    let me = this.__getMyRoomMember()
    if (!me) {
      log("__connectToHost failed: player is not in the room")
      return
    }

    let hostPub = host.public
    let roomPub = roomInfo.get().public

    if (!("room_key" in roomPub)) {
      let mePub = tostring_r(me?.public, 3)          
      let mePrivate = tostring_r(me?.private, 3)     
      let meStr = tostring_r(me, 3)                  
      let roomStr = tostring_r(roomPub, 3)           
      let roomMission = tostring_r(roomPub?.mission) 
      script_net_assert("missing room_key in room")

      logerr("[log] missing room_key in room")
      return
    }

    local serverUrls = [];
    if ("serverURLs" in hostPub)
      serverUrls = hostPub.serverURLs
    else if ("ip" in hostPub && "port" in hostPub) {
      let ip = hostPub.ip
      let ipStr = format("%u.%u.%u.%u:%d", ip & 255, (ip >> 8) & 255, (ip >> 16) & 255, ip >> 24, hostPub.port)
      serverUrls.append(ipStr)
    }

    connect_to_host_list(serverUrls,
                      roomPub.room_key, me.private.auth_key,
                      getTblValue("sessionId", roomPub, MRoomsHandlersState.roomId))
  }

  
  function onRoomInvite(notify, send_resp) {
    local inviteData = notify.invite_data
    if (!(inviteData instanceof Table))
      inviteData = {}
    inviteData.roomId <- notify.roomId

    if (notify_room_invite(inviteData))
      send_resp({ accept = true })
    else
      send_resp({ accept = false })
  }

  function onRoomMemberJoined(member) {
    if (!this.__isNotifyForCurrentRoom(member))
      return

    log(format("%s (%s) joined to room", member.name, member.userId.tostring()))
    this.__addRoomMember(member)

    notify_room_member_joined(member)
  }

  function onRoomMemberLeft(member) {
    if (!this.__isNotifyForCurrentRoom(member))
      return

    log(format("%s (%s) left from room", member.name, member.userId.tostring()))
    this.__removeRoomMember(member.userId)
    notify_room_member_leaved(member)
  }

  function onRoomMemberKicked(member) {
    if (!this.__isNotifyForCurrentRoom(member))
      return

    log(format("%s (%s) kicked from room", member.name, member.userId.tostring()))
    this.__removeRoomMember(member.userId)
    notify_room_member_kicked(member)
  }

  function onRoomAttrChanged(notify) {
    if (!this.__isNotifyForCurrentRoom(notify))
      return

    roomInfo.set(clone (this.__mergeAttribs(notify, roomInfo.get())))
    notify_room_attribs_changed(notify)
  }

  function onRoomMemberAttrChanged(notify) {
    if (!this.__isNotifyForCurrentRoom(notify))
      return

    this.__updateMemberAttributes(notify)
    notify_room_member_attribs_changed(notify)
  }

  function onRoomDestroyed(notify) {
    if (!this.__isNotifyForCurrentRoom(notify))
      return
    this.__cleanupRoomState()
  }

  function onHostNotify(notify) {
    debugTableData(notify)
    if (!this.__isNotifyForCurrentRoom(notify))
      return

    if (notify.hostId != MRoomsHandlersState.hostId) {
      log("warning: got host notify from host that is not in current room")
      return
    }

    if (notify.roomId != this.getRoomId()) {
      log("warning: got host notify for wrong room")
      return
    }

    if (notify.message == "connect-allowed") {
      MRoomsHandlersState.isConnectAllowed = true
      this.__connectToHost()
    }
  }

  function onRoomJoinCb(resp) {
    this.__cleanupRoomState()

    lastRoom.set(resp)
    roomInfo.set(resp)
    MRoomsHandlersState.roomId = resp.roomId
    foreach (member in roomInfo.get().members)
      this.__addRoomMember(member)

    if (getTblValue("connect_on_join", roomInfo.get().public)) {
      log("room with auto-connect feature")
      MRoomsHandlersState.isSelfReady = true
      this.__onSelfReady()
    }
  }

  function onRoomLeaveCb() {
    this.__cleanupRoomState()
  }
}

g_mrooms_handlers = MRoomsHandlers()

matchingRpcRegisterHandler("onRoomJoin", function(resp, context) {
  if ("error" not in resp) {
    g_mrooms_handlers.onRoomJoinCb(resp)
    SessionLobby.afterRoomJoining(resp)
    return
  }

  SessionLobby.switchStatus(lobbyStates.NOT_IN_ROOM)

  if (resp.error == SERVER_ERROR_ROOM_PASSWORD_MISMATCH) {
    let { roomId = null, password = "" } = context
    if (roomId != null)
      SessionLobby.joinRoomWithPassword(roomId, password, password != "")
    return
  }

  showMatchingError(resp)
})

matchingRpcRegisterHandler("onSetPasswrod", function(resp, context) {
  if (showMatchingError(resp)) {
    SessionLobbyState.password = context.prevPass
    SessionLobby.checkDynamicSettings()
  }
})

matchingRpcRegisterHandler("onRoomLeave", function(_, context) {
  if (g_mrooms_handlers.getRoomId() == context.roomId)
    g_mrooms_handlers.onRoomLeaveCb()
  SessionLobby.afterLeaveRoom({})
})

matchingRpcRegisterHandler("onSetAttributes", function afterRoomUpdate(resp) {
  if (showMatchingError(resp))
    return SessionLobby.destroyRoom()

  SessionLobbyState.roomUpdated = true
  SessionLobby.checkAutoStart()
})

matchingRpcRegisterHandler("onSetReady", function(resp, context) {
  let { ready, roomId } = context
  SessionLobbyState.isReady = ready
    && SessionLobby.isInRoom()
    && SessionLobbyState.roomId == roomId
    && !showMatchingError(resp)
})

matchingRpcRegisterHandler("onStartSession", function(resp) {
  if (!SessionLobby.isInRoom())
    return
  if (showMatchingError(resp)) {
    SessionLobby.destroyRoom()
    return
  }
  SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
})

return {
  joinRoom = @(roomId) SessionLobby.joinRoom(roomId)
  lastRoomId
  lastRoom
  roomInfo
}
