from "%scripts/dagui_natives.nut" import in_flight_menu, set_host_cb, is_online_available, send_error_log, script_net_assert, connect_to_host_list
from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let { g_listener_priority } = require("%scripts/g_listener_priority.nut")
let { set_last_session_debug_info } = require("%scripts/matchingRooms/sessionDebugInfo.nut")
let { OPERATION_COMPLETE, SERVER_ERROR_ROOM_PASSWORD_MISMATCH, INVALID_ROOM_ID } = require("matching.errors")
let { is_user_mission } = require("%scripts/util.nut")
let { subscribe_handler, broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { debug_dump_stack } = require("dagor.debug")
let { get_mp_session_id_str, destroy_session } = require("multiplayer")
let base64 = require("base64")
let DataBlock = require("DataBlock")
let { eventbus_subscribe }  = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { convertBlk } = require("%sqstd/datablock.nut")
let { isEqual, isDataBlock } = require("%sqstd/underscore.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { missionAvailabilityFlag, isAvailableByMissionSettings } = require("%scripts/missions/missionsUtils.nut")
let { lobbyStates, sessionLobbyStatus } = require("%appGlobals/sessionLobbyState.nut")
let { errorMsgBox } = require("%scripts/utils/errorMsgBox.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { myUserId, myUserName } = require("%appGlobals/profileStates.nut")
let showMatchingError = require("%scripts/matching/showMatchingError.nut")
let { gameModesRaw } = require("%appGlobals/gameModes/gameModes.nut")
let { isMatchingOnline } = require("%scripts/matching/matchingOnline.nut")
let { destroyQueue, leaveQueue } = require("%scripts/matching/queuesClient.nut")
let { isInDebriefing, isInLoadingScreen, isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { get_cd_preset } = require("guiOptions")
let { get_meta_mission_info_by_name, leave_mp_session, quit_to_debriefing,
  interrupt_multiplayer
} = require("guiMission")
let { set_game_mode, get_game_mode, get_game_type } = require("mission")
let { web_rpc } = require("%scripts/webRPC.nut")
let { isInFlight } = require("gameplayBinding")
let { format } = require("string")
let { tostring_r } = require("%sqstd/string.nut")
let matching = require("%appGlobals/matching_api.nut")

function is_my_userid(user_id) {
  if (type(user_id) == "string")
    return user_id == myUserId.value.tostring()
  return user_id == myUserId.value
}

/*
SessionLobby API

  all:
    isInRoom
    joinRoom
    leaveRoom
    setReady(bool)

  room owner:
    destroyRoom
    startSession

*/

const NET_SERVER_LOST = 0x82220002  //for hostCb
const NET_SERVER_QUIT_FROM_GAME = 0x82220003

local last_round = true
local SessionLobby
let isGameModeCoop = @(gm) gm == -1 || gm == GM_SINGLE_MISSION || gm == GM_BUILDER

let allowed_mission_settings = { //only this settings are allowed in room
                              //default params used only to check type atm
  name = null
  missionURL = null
  players = 12
  hidden = false  //can be found by search rooms

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

let SessionLobbyState = persist("SessionLobbyState", @(){
  roomId = INVALID_ROOM_ID
  settings = {}
  uploadedMissionId = ""
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
})

let lastRoom = mkWatched(persist, "lastRoom")
let lastRoomId = Computed(@() lastRoom.get()?.roomId ?? INVALID_ROOM_ID)
let MRoomsHandlersState  = persist("MRoomsHandlersState", @() {
  hostId = null  //user host id
  roomId = INVALID_ROOM_ID
  room   = null
  roomMembers = []
  isConnectAllowed = false
  roomOps = {}
  isHostReady = false
  isSelfReady = false
  isLeaving = false
})


// rooms notifications
function notify_room_invite(params) {
  log("notify_room_invite")
  //debugTableData(params)

  if (!isInMenu.value && isLoggedIn.value) {
    log("Invite rejected: player is already in flight or in loading level or in unloading level");
    return false
  }

  let senderId = ("senderId" in params) ? params.senderId : null
  let password = getTblValue("password", params, null)
  if (!senderId) //querry room
    SessionLobby.joinRoom(params.roomId, senderId, password)
  return true
}

function notify_room_destroyed(params) {
  log("notify_room_destroyed")
  //debugTableData(params)

  SessionLobby.afterLeaveRoom(params)
}

function notify_room_member_joined(params) {
  log("notify_room_member_joined")
  //debugTableData(params)
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
  //debugTableData(params)

  SessionLobby.onSettingsChanged(params)
}

local g_mrooms_handlers

function join_room(params, cb) {
  matching.rpc_call("mrooms.join_room",
    params,
    function(resp) {
      if (resp.error == OPERATION_COMPLETE)
        g_mrooms_handlers.onRoomJoinCb(resp)
      else {
        resp.roomId <- params?.roomId
        resp.password <- params?.password
      }
      cb(resp)
    })
}

function leave_room(params, cb) {
  let oldRoomId = g_mrooms_handlers.getRoomId()
  MRoomsHandlersState.isLeaving = true

  matching.rpc_call("mrooms.leave_room",
    params,
    function(resp) {
      if (g_mrooms_handlers.getRoomId() == oldRoomId)
        g_mrooms_handlers.onRoomLeaveCb()
      cb(resp)
    })
}

eventbus_subscribe("notify_session_start", function notify_session_start(...) {
  let sessionId = get_mp_session_id_str()
  if (sessionId != "")
    set_last_session_debug_info($"sid:{sessionId}")

  log("notify_session_start")
  SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
})

function setRoomAttributes(params, cb) {
  log($"[PSMT] setting room attributes: {params?.public.psnMatchId}")
  matching.rpc_call("mrooms.set_attributes", params, cb)
}

local delayedJoinRoomFunc = null

let getMaxEconomicRank = @() 30 //it used only for create room. So better to remove this code at all, but not in this commit.

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
      if (type(v) == "array" && type(value) != "array")
        value = [value]
      _settings[key] <- value //value == null will clear param on server
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

    _settings.creator <- myUserName.value
    _settings.mission.originalMissionName <- getTblValue("name", _settings.mission, "")
    if ("postfix" in _settings.mission && _settings.mission.postfix) {
      let ending = "_tm"
      local nameNoTm = _settings.mission.name
      if (nameNoTm.len() > ending.len() && nameNoTm.slice(nameNoTm.len() - ending.len()) == ending)
        nameNoTm = nameNoTm.slice(0, nameNoTm.len() - ending.len())
      _settings.mission.loc_name = "".concat(nameNoTm, _settings.mission.postfix)
      _settings.mission.name = "".concat(_settings.mission.name, _settings.mission.postfix)
    }
    if (is_user_mission(mission))
      _settings.userMissionName <- loc($"missions/{mission.name}")
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
    if (type(v_settings) == "array") {
      log("v_settings param, public info, is array, instead of table")
      debug_dump_stack()
      return
    }

    if (checkEqual && isEqual(SessionLobbyState.settings, v_settings))
      return

    //v_settings can be public date of room, and it does not need to be updated settings somewhere else
    SessionLobbyState.settings.clear()
    SessionLobbyState.__merge(v_settings)
    //not mission room settings
    SessionLobbyState.settings.connect_on_join <- true

    SessionLobbyState.roomUpdated = notify || !SessionLobbyState.isRoomOwner || !this.isInRoom()
    if (!SessionLobbyState.roomUpdated)
      setRoomAttributes({ roomId = SessionLobbyState.roomId, public = SessionLobbyState.settings }, function(p) { SessionLobby.afterRoomUpdate(p) })

    let newGm = this.getGameMode()
    if (newGm >= 0)
      set_game_mode(newGm)

    broadcastEvent("LobbySettingsChange")
  }

  function checkDynamicSettings(silent = false, v_settings = null) {
    if (!SessionLobbyState.isRoomOwner && this.isInRoom())
      return

    if (!v_settings) {
      if (!SessionLobbyState.settings || !SessionLobbyState.settings.len())
        return //owner have joined back to the room, and not receive settings yet
      v_settings = SessionLobbyState.settings
    }
    else
      silent = true //no need to update when custom settings checked

    local changed = false
    let wasHidden = getTblValue("hidden", v_settings, false)
    v_settings.hidden <- getTblValue("coop", v_settings, false)
                        || (SessionLobbyState.isRoomInSession && !getTblValue("allowJIP", v_settings, true))
    changed = changed || (wasHidden != v_settings.hidden) // warning disable: -const-in-bool-expr

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

    broadcastEvent("LobbyRoomInSession")
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
    return type(res) == "integer" ? res : 0
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
    SessionLobbyState.status = v_status  //for easy notify other handlers about change status
    sessionLobbyStatus(v_status)

    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM || SessionLobbyState.status == lobbyStates.IN_DEBRIEFING)
      this.setReady(false, true)
    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM) {
      this.resetParams()
      if (wasStatus == lobbyStates.JOINING_SESSION)
        destroy_session("on leave room while joining session")
    }

    this.updateMyState()

    broadcastEvent("LobbyStatusChange")
  }

  function resetParams() {
    SessionLobbyState.settings.clear()
    this.changePassword("") //reset password after leave room
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
    if (type(v_password) != "string" || SessionLobbyState.password == v_password)
      return

    if (SessionLobbyState.isRoomOwner && SessionLobbyState.status != lobbyStates.NOT_IN_ROOM && SessionLobbyState.status != lobbyStates.CREATING_ROOM) {
      let prevPass = SessionLobbyState.password
      matching.rpc_call("mrooms.set_password",
        { roomId = SessionLobbyState.roomId, password = v_password },
        function(p) {
          if (showMatchingError(p)) {
            SessionLobbyState.password = prevPass
            SessionLobby.checkDynamicSettings()
          }
        })
    }
    SessionLobbyState.password = v_password
  }

  function isUserMission(v_settings = null) {
    return getTblValue("userMissionName", v_settings || SessionLobbyState.settings) != null
  }

  function isMissionReady() {
    return !this.isUserMission() ||
           (SessionLobbyState.status != lobbyStates.UPLOAD_CONTENT && SessionLobbyState.uploadedMissionId == this.getMissionName())
  }

  function uploadUserMission(afterDoneFunc = null) {
    if (!this.isInRoom() || !this.isUserMission() || SessionLobbyState.status == lobbyStates.UPLOAD_CONTENT)
      return
    if (SessionLobbyState.uploadedMissionId == this.getMissionName()) {
      afterDoneFunc?()
      return
    }

    let missionId = this.getMissionName()
    let missionInfo = DataBlock()
    missionInfo.setFrom(get_meta_mission_info_by_name(missionId))
    let missionBlk = DataBlock()
    if (missionInfo)
      missionBlk.load(missionInfo.mis_file)
    //dlog("GP: upload mission!")
    //debugTableData(missionBlk)

    let blkData = base64.encodeBlk(missionBlk)
    //dlog("GP: data = ", blkData)
    //debugTableData(blkData)
    if (!blkData || !("result" in blkData) || !blkData.result.len()) {
      openFMsgBox({ text = loc("msg/cant_load_user_mission") })
      return
    }

    this.switchStatus(lobbyStates.UPLOAD_CONTENT)
    setRoomAttributes({ roomId = SessionLobbyState.roomId, private = { userMission = blkData.result } },
                          function(p) {
                            if (showMatchingError(p)) {
                              SessionLobby.returnStatusToRoom()
                              return
                            }
                            SessionLobbyState.uploadedMissionId = missionId
                            SessionLobby.returnStatusToRoom()
                            if (afterDoneFunc)
                              afterDoneFunc()
                          })
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

  function updateMemberHostParams(member = null) { //null = host leave
    SessionLobbyState.memberHostId = member ? member.memberId : -1
  }


  function updateReady(ready) {
    SessionLobbyState.isReady = ready
    broadcastEvent("LobbyReadyChanged")
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
    broadcastEvent("LobbyMemberInfoChanged")
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

  function setReady(ready, _silent = false, forceRequest = false) { //return is my info changed
    if (!forceRequest && SessionLobbyState.isReady == ready)
      return false

    if (!this.isInRoom()) {
      SessionLobbyState.isReady = false
      return ready
    }

    matching.rpc_call("mrooms.set_ready_state",
      { state = ready, roomId = SessionLobbyState.roomId },
      function(p) {
        if (!this.isInRoom()) {
          SessionLobbyState.isReady = false
          return
        }

        let wasReady = SessionLobbyState.isReady
        SessionLobbyState.isReady = ready

        //if we receive error on set ready, result is ready == false always.
        if (showMatchingError(p))
          SessionLobbyState.isReady = false

        if (SessionLobbyState.isReady == wasReady)
          return

        broadcastEvent("LobbyReadyChanged")
      }.bindenv(this))
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

    matching.rpc_call("mrooms.destroy_room", { roomId = SessionLobbyState.roomId })
    SessionLobby.afterLeaveRoom({})
  }

  function leaveRoom() {
    if (SessionLobbyState.status == lobbyStates.NOT_IN_ROOM || SessionLobbyState.status == lobbyStates.WAIT_FOR_QUEUE_ROOM) {
      this.setWaitForQueueRoom(false)
      return
    }

    leave_room({}, function(_p) {
        SessionLobby.afterLeaveRoom({})
     })
  }

  function checkLeaveRoomInDebriefing() {
    if (!last_round)
      return;

    if (this.isInRoom())
      this.leaveRoom()
  }

  onEventSignOut = @(_) this.leaveRoom()

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
      this.leaveRoom() //leave old room before join the new one

    leave_mp_session()

    if (!SessionLobbyState.isRoomOwner) {
      this.setSettings({})
      SessionLobbyState.members.clear()
    }

    set_last_session_debug_info(
      ("roomId" in join_params) ? ($"room: { join_params.roomId }") :
      ("battleId" in join_params) ? ($"battle: { join_params.battleId }") :
      ""
    )

    this.switchStatus(lobbyStates.JOINING_ROOM)
    join_room(join_params, this.afterRoomJoining.bindenv(this))
  }

  function joinBattle(battleId) {
    destroyQueue()
    SessionLobbyState.isRoomOwner = false
    SessionLobbyState.isRoomByQueue = false
    this.sendJoinRoomRequest({ battleId = battleId })
  }

  function joinRoom(v_roomId, senderId = "", v_password = null,
                                  cb = function(...) {}) { //by default not a queue, but no id too
    if (SessionLobbyState.roomId == v_roomId && this.isInRoom())
      return

    if (!isLoggedIn.value || this.isInRoom()) {
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
    if (params.error == SERVER_ERROR_ROOM_PASSWORD_MISMATCH) {
      let joinRoomId = params.roomId //not_in_room status will clear room Id
      let oldPass = params.password
      this.switchStatus(lobbyStates.NOT_IN_ROOM)
      this.joinRoomWithPassword(joinRoomId, oldPass, oldPass != "")
      return
    }

    if (showMatchingError(params))
      return this.switchStatus(lobbyStates.NOT_IN_ROOM)

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

    let event = SessionLobby.getRoomEvent()
    if (event)
      broadcastEvent("AfterJoinEventRoom", event)

    this.checkAutoStart()

    last_round = getTblValue("last_round", public, true)
    this.setRoomInSession(this.isSessionStartedInRoom())
    broadcastEvent("RoomJoined", params)
  }

  function returnStatusToRoom() {
    local newStatus = lobbyStates.IN_ROOM
    this.switchStatus(newStatus)
  }

  function isMemberOperator(member) {
    return ("public" in member) && ("operator" in member.public) && member.public.operator
  }

  function afterRoomUpdate(params) {
    if (showMatchingError(params))
      return this.destroyRoom()

    SessionLobbyState.roomUpdated = true
    this.checkAutoStart()
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
    if (!this.isMissionReady()) {
      this.uploadUserMission(function() { SessionLobby.startSession() })
      return
    }
    log("start session")

    matching.rpc_call("mrooms.start_session",
      { roomId = SessionLobbyState.roomId, cluster = this.getPublicParam("cluster", "EU") },
      function(p) {
        if (!SessionLobby.isInRoom())
          return
        if (showMatchingError(p)) {
          SessionLobby.destroyRoom()
          return
        }
        SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
      })
    this.switchStatus(lobbyStates.START_SESSION)
  }

  function hostCb(res) {
    if (type(res) != "table" || "errCode" not in res)
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
    broadcastEvent("LobbyMembersChanged")
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
            if (!isInMenu.value) {
              quit_to_debriefing()
              interrupt_multiplayer(true)
              in_flight_menu(false)
            }
            openFMsgBox({ text = loc("matching/msg_kicked"), isPersist = true })
          }
        }
        broadcastEvent("LobbyMembersChanged")
        break
      }
  }

  function rpcJoinBattle(params) {
    if (!is_online_available())
      return "client not ready"
    let battleId = params.battleId
    if (type(battleId) != "string")
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
    gameModesRaw.value?[this.getMGameModeId(room)]

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

web_rpc.register_handler("join_battle", SessionLobby.rpcJoinBattle)

subscribe_handler(SessionLobby, g_listener_priority.DEFAULT_HANDLER)

isMatchingOnline.subscribe(@(_) SessionLobby.leaveRoom())

isInDebriefing.subscribe(@(v) v ? SessionLobby.checkLeaveRoomInDebriefing() : null)

let setHostCb = @() set_host_cb(null, @(p) SessionLobby.hostCb(p))
if (isLoggedIn.value)
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
  matching.subscribe(notificationName, callback)

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
      matching.subscribe(notificationName, callback)
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
    if (MRoomsHandlersState.room == null)
      return

    MRoomsHandlersState.hostId = null
    MRoomsHandlersState.roomId = INVALID_ROOM_ID
    MRoomsHandlersState.room   = null
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

    if (type(priv) == "table") {
      if ("private" in attr_to)
        updateAttribs(priv, attr_to.private)
      else
        attr_to.private <- priv
    }
    if (type(pub) == "table") {
      if ("public" in attr_to)
        updateAttribs(pub, attr_to.public)
      else
        attr_to.public <- pub
    }
  }

  function __isNotifyForCurrentRoom(notify) {
    // ignore all room notifcations after leave has been called
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
    let roomPub = MRoomsHandlersState.room.public

    if (!("room_key" in roomPub)) {
      let mePub = tostring_r(me?.public, 3)          // warning disable: -declared-never-used
      let mePrivate = tostring_r(me?.private, 3)     // warning disable: -declared-never-used
      let meStr = tostring_r(me, 3)                  // warning disable: -declared-never-used
      let roomStr = tostring_r(roomPub, 3)           // warning disable: -declared-never-used
      let roomMission = tostring_r(roomPub?.mission) // warning disable: -declared-never-used
      script_net_assert("missing room_key in room")

      send_error_log("missing room_key in room", false, "log")
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

  // notifications
  function onRoomInvite(notify, send_resp) {
    local inviteData = notify.invite_data
    if (!(type(inviteData) == "table"))
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

    this.__mergeAttribs(notify, MRoomsHandlersState.room)
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
    MRoomsHandlersState.room = resp
    MRoomsHandlersState.roomId = MRoomsHandlersState.room.roomId
    foreach (member in MRoomsHandlersState.room.members)
      this.__addRoomMember(member)

    if (getTblValue("connect_on_join", MRoomsHandlersState.room.public)) {
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

return {
  joinRoom = @(roomId) SessionLobby.joinRoom(roomId)
  lastRoomId
  lastRoom
}
