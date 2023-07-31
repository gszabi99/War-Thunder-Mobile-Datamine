//-file:plus-string

from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let { g_script_reloader, PERSISTENT_DATA_PARAMS } = require("%sqStdLibs/scriptReloader/scriptReloader.nut")
let { is_user_mission } = require("%scripts/util.nut")
let { subscribe_handler, broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { debug_dump_stack } = require("dagor.debug")
let { get_mp_session_id_str, destroy_session } = require("multiplayer")
let base64 = require("base64")
let DataBlock = require("DataBlock")
let { subscribe }  = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { isEqual, isEmpty, isInteger, isDataBlock } = require("%sqStdLibs/helpers/u.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { missionAvailabilityFlag, isAvailableByMissionSettings } = require("%scripts/missions/missionsUtils.nut")
let { lobbyStates, sessionLobbyStatus } = require("%appGlobals/sessionLobbyState.nut")
let { errorMsgBox } = require("%scripts/utils/errorMsgBox.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
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

::LAST_SESSION_DEBUG_INFO <- ""

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

// rooms notifications
::notify_room_invite <- function notify_room_invite(params) {
  log("notify_room_invite")
  //debugTableData(params)

  if (!isInMenu.value && isLoggedIn.value) {
    log("Invite rejected: player is already in flight or in loading level or in unloading level");
    return false;
  }

  let senderId = ("senderId" in params) ? params.senderId : null
  let password = getTblValue("password", params, null)
  if (!senderId) //querry room
    SessionLobby.joinRoom(params.roomId, senderId, password)
  return true
}

::notify_room_destroyed <- function notify_room_destroyed(params) {
  log("notify_room_destroyed")
  //debugTableData(params)

  SessionLobby.afterLeaveRoom(params)
}

::notify_room_member_joined <- function notify_room_member_joined(params) {
  log("notify_room_member_joined")
  //debugTableData(params)
  SessionLobby.onMemberJoin(params)
}

::notify_room_member_leaved <- function notify_room_member_leaved(params) {
  log("notify_room_member_leaved")
  SessionLobby.onMemberLeave(params)
}

::notify_room_member_kicked <- function notify_room_member_kicked(params) {
  log("notify_room_member_kicked")
  SessionLobby.onMemberLeave(params, true)
}

::notify_room_member_attribs_changed <- function notify_room_member_attribs_changed(params) {
  log("notify_room_member_attribs_changed")
  SessionLobby.onMemberInfoUpdate(params)
}

::notify_room_attribs_changed <- function notify_room_attribs_changed(params) {
  log("notify_room_attribs_changed")
  //debugTableData(params)

  SessionLobby.onSettingsChanged(params)
}

::notify_session_start <- function notify_session_start() {
  let sessionId = get_mp_session_id_str()
  if (sessionId != "")
    ::LAST_SESSION_DEBUG_INFO = "sid:" + sessionId

  log("notify_session_start")
  SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
}

let function setRoomAttributes(params, cb) {
  log($"[PSMT] setting room attributes: {params?.public.psnMatchId}")
  ::matching.rpc_call("mrooms.set_attributes", params, cb)
}

local delayedJoinRoomFunc = null

let getMaxEconomicRank = @() 30 //it used only for create room. So better to remove this code at all, but not in this commit.


SessionLobby = {
  [PERSISTENT_DATA_PARAMS] = [
    "roomId", "settings", "uploadedMissionId", "status",
    "isRoomInSession", "isRoomOwner", "isRoomByQueue",
    "roomUpdated", "password", "members", "memberHostId",
    "isReady", "myState", "needJoinSessionAfterMyInfoApply",
  ]

  settings = {}
  uploadedMissionId = ""
  status = lobbyStates.NOT_IN_ROOM
  isRoomInSession = false
  isRoomOwner = false
  isRoomByQueue = false
  roomId = INVALID_ROOM_ID
  roomUpdated = false
  password = ""

  members = []
  memberDefaults = {
    country = "country_0"
    ready = false
    is_in_session = false
    clanTag = ""
    title = ""
    pilotId = 0
    state = PLAYER_IN_LOBBY_NOT_READY
  }
  memberHostId = -1

  //my room attributes
  isReady = false
  myState = PLAYER_IN_LOBBY_NOT_READY

  needJoinSessionAfterMyInfoApply = false

  roomTimers = [
    {
      publicKey = "timeToCloseByDisbalance"
      color = "@warningTextColor"
      function getLocText(public, locParams) {
        local res = loc("multiplayer/closeByDisbalance", locParams)
        if ("disbalanceType" in public)
          res += "\n" + loc("multiplayer/reason") + loc("ui/colon")
            + loc("roomCloseReason/" + public.disbalanceType)
        return res
      }
    }
    {
      publicKey = "matchStartTime"
      color = "@inQueueTextColor"
      function getLocText(_public, locParams) {
        return loc("multiplayer/battleStartsIn", locParams)
      }
    }
  ]

  function isInRoom() {
    return this.status != lobbyStates.NOT_IN_ROOM
      && this.status != lobbyStates.WAIT_FOR_QUEUE_ROOM
      && this.status != lobbyStates.CREATING_ROOM
      && this.status != lobbyStates.JOINING_ROOM
  }

  function isWaitForQueueRoom() {
    return this.status == lobbyStates.WAIT_FOR_QUEUE_ROOM
  }

  function setWaitForQueueRoom(set) {
    if (this.status == lobbyStates.NOT_IN_ROOM || this.status == lobbyStates.WAIT_FOR_QUEUE_ROOM)
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

      _settings.mission[key] <- isDataBlock(value) ? ::buildTableFromBlk(value) : value
    }

    _settings.creator <- myUserName.value
    _settings.mission.originalMissionName <- getTblValue("name", _settings.mission, "")
    if ("postfix" in _settings.mission && _settings.mission.postfix) {
      let ending = "_tm"
      local nameNoTm = _settings.mission.name
      if (nameNoTm.len() > ending.len() && nameNoTm.slice(nameNoTm.len() - ending.len()) == ending)
        nameNoTm = nameNoTm.slice(0, nameNoTm.len() - ending.len())
      _settings.mission.loc_name = nameNoTm + _settings.mission.postfix
      _settings.mission.name += _settings.mission.postfix
    }
    if (is_user_mission(mission))
      _settings.userMissionName <- loc("missions/" + mission.name)
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

    if (!isEmpty(this.settings?.externalSessionId))
      _settings.externalSessionId <- this.settings.externalSessionId
    if (!isEmpty(this.settings?.psnMatchId))
      _settings.psnMatchId <- this.settings.psnMatchId

    this.checkDynamicSettings(true, _settings)
    this.setSettings(_settings)
  }

  function setSettings(v_settings, notify = false, checkEqual = true) {
    if (type(v_settings) == "array") {
      log("v_settings param, public info, is array, instead of table")
      debug_dump_stack()
      return
    }

    if (checkEqual && isEqual(this.settings, v_settings))
      return

    //v_settings can be public date of room, and it does not need to be updated settings somewhere else
    this.settings = clone v_settings
    //not mission room settings
    this.settings.connect_on_join <- true

    this.roomUpdated = notify || !this.isRoomOwner || !this.isInRoom()
    if (!this.roomUpdated)
      setRoomAttributes({ roomId = this.roomId, public = this.settings }, function(p) { SessionLobby.afterRoomUpdate(p) })

    let newGm = this.getGameMode()
    if (newGm >= 0)
      set_game_mode(newGm)

    broadcastEvent("LobbySettingsChange")
  }

  function checkDynamicSettings(silent = false, v_settings = null) {
    if (!this.isRoomOwner && this.isInRoom())
      return

    if (!v_settings) {
      if (!this.settings || !this.settings.len())
        return //owner have joined back to the room, and not receive settings yet
      v_settings = this.settings
    }
    else
      silent = true //no need to update when custom settings checked

    local changed = false
    let wasHidden = getTblValue("hidden", v_settings, false)
    v_settings.hidden <- getTblValue("coop", v_settings, false)
                        || (this.isRoomInSession && !getTblValue("allowJIP", v_settings, true))
    changed = changed || (wasHidden != v_settings.hidden) // warning disable: -const-in-bool-expr

    let wasPassword = getTblValue("hasPassword", v_settings, false)
    v_settings.hasPassword <- this.password != ""
    changed = changed || (wasPassword != v_settings.hasPassword)

    if (changed && !silent)
      this.setSettings(this.settings, false, false)
  }

  function onSettingsChanged(p) {
    if (this.roomId != p.roomId)
      return
    let set = getTblValue("public", p)
    if (!set)
      return

    if ("last_round" in set) {
      last_round = set.last_round
      log($"last round {last_round}")
    }

    let newSet = clone this.settings
    foreach (k, v in set)
      if (v == null) {
        if (k in newSet)
          delete newSet[k]
      }
      else
        newSet[k] <- v

    this.setSettings(newSet, true)

    this.setRoomInSession(this.isSessionStartedInRoom())
  }

  function setRoomInSession(newIsInSession) {
    if (newIsInSession == this.isRoomInSession)
      return

    this.isRoomInSession = newIsInSession
    if (!this.isInRoom())
      return

    broadcastEvent("LobbyRoomInSession")
    if (this.isRoomOwner)
      this.checkDynamicSettings()
  }

  function getMissionName(isOriginalName = false, room = null) {
    let misData = this.getMissionData(room)
    return isOriginalName ? (misData?.originalMissionName ?? "") : (misData?.name ?? "")
  }

  function getPublicData(room = null) {
    return room ? (("public" in room) ? room.public : room) : this.settings
  }

  function getMissionData(room = null) {
    return getTblValue("mission", this.getPublicData(room))
  }

  function getGameMode(room = null) {
    return getTblValue("_gameMode", this.getMissionData(room), GM_DOMINATION)
  }

  function getGameType(room = null) {
    let res = getTblValue("_gameType", this.getMissionData(room), 0)
    return isInteger(res) ? res : 0
  }

  function getMGameModeId(room = null) {
    return getTblValue("game_mode_id", this.getPublicData(room))
  }

  function getPublicParam(name, defValue = "") {
    if (name in this.settings)
      return this.settings[name]
    return defValue
  }

  function switchStatus(v_status) {
    if (this.status == v_status)
      return

    let wasStatus = this.status
    this.status = v_status  //for easy notify other handlers about change status
    sessionLobbyStatus(v_status)

    if (this.status == lobbyStates.NOT_IN_ROOM || this.status == lobbyStates.IN_DEBRIEFING)
      this.setReady(false, true)
    if (this.status == lobbyStates.NOT_IN_ROOM) {
      this.resetParams()
      if (wasStatus == lobbyStates.JOINING_SESSION)
        destroy_session("on leave room while joining session")
    }

    this.updateMyState()

    broadcastEvent("LobbyStatusChange")
  }

  function resetParams() {
    this.settings.clear()
    this.changePassword("") //reset password after leave room
    this.updateMemberHostParams(null)
    this.isRoomByQueue = false
    this.myState = PLAYER_IN_LOBBY_NOT_READY
    this.roomUpdated = false
    this.needJoinSessionAfterMyInfoApply = false
  }

  function switchStatusChecked(oldStatusList, newStatus) {
    if (isInArray(this.status, oldStatusList))
      this.switchStatus(newStatus)
  }

  function changePassword(v_password) {
    if (type(v_password) != "string" || this.password == v_password)
      return

    if (this.isRoomOwner && this.status != lobbyStates.NOT_IN_ROOM && this.status != lobbyStates.CREATING_ROOM) {
      let prevPass = this.password
      ::matching.rpc_call("mrooms.set_password",
        { roomId = this.roomId, password = v_password },
        function(p) {
          if (showMatchingError(p)) {
            SessionLobby.password = prevPass
            SessionLobby.checkDynamicSettings()
          }
        })
    }
    this.password = v_password
  }

  function isUserMission(v_settings = null) {
    return getTblValue("userMissionName", v_settings || this.settings) != null
  }

  function isMissionReady() {
    return !this.isUserMission() ||
           (this.status != lobbyStates.UPLOAD_CONTENT && this.uploadedMissionId == this.getMissionName())
  }

  function uploadUserMission(afterDoneFunc = null) {
    if (!this.isInRoom() || !this.isUserMission() || this.status == lobbyStates.UPLOAD_CONTENT)
      return
    if (this.uploadedMissionId == this.getMissionName()) {
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
    //dlog("GP: data = " + blkData)
    //debugTableData(blkData)
    if (!blkData || !("result" in blkData) || !blkData.result.len()) {
      openFMsgBox({ text = loc("msg/cant_load_user_mission") })
      return
    }

    this.switchStatus(lobbyStates.UPLOAD_CONTENT)
    setRoomAttributes({ roomId = this.roomId, private = { userMission = blkData.result } },
                          function(p) {
                            if (showMatchingError(p)) {
                              SessionLobby.returnStatusToRoom()
                              return
                            }
                            SessionLobby.uploadedMissionId = missionId
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
        delete tblBase[key]
    return tblBase
  }

  function updateMemberHostParams(member = null) { //null = host leave
    this.memberHostId = member ? member.memberId : -1
  }


  function updateReady(ready) {
    this.isReady = ready
    broadcastEvent("LobbyReadyChanged")
  }

  function onMemberInfoUpdate(params) {
    if (params.roomId != this.roomId)
      return
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(params)

    local member = null
    foreach (m in this.members)
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

    if (::is_my_userid(member.userId)) {
      this.isRoomOwner = this.isMemberOperator(member)
      let ready = getTblValue("ready", getTblValue("public", member, {}), null)
      if (ready != null && ready != this.isReady)
        this.updateReady(ready)
      else if (this.needJoinSessionAfterMyInfoApply)
        this.tryJoinSession()
      this.needJoinSessionAfterMyInfoApply = false
    }
    broadcastEvent("LobbyMemberInfoChanged")
  }

  function updateMyState(_silent = false) {
    local newState = PLAYER_IN_LOBBY_NOT_READY
    if (this.status == lobbyStates.IN_LOBBY || this.status == lobbyStates.START_SESSION)
      newState = this.isReady ? PLAYER_IN_LOBBY_READY : PLAYER_IN_LOBBY_NOT_READY
    else if (this.status == lobbyStates.IN_LOBBY_HIDDEN)
      newState = PLAYER_IN_LOBBY_READY
    else if (this.status == lobbyStates.IN_SESSION)
      newState = PLAYER_IN_FLIGHT
    else if (this.status == lobbyStates.IN_DEBRIEFING)
      newState = PLAYER_IN_STATISTICS_BEFORE_LOBBY

    this.myState = newState
    return this.myState
  }

  function setReady(ready, _silent = false, forceRequest = false) { //return is my info changed
    if (!forceRequest && this.isReady == ready)
      return false

    if (!this.isInRoom()) {
      this.isReady = false
      return ready
    }

    ::matching.rpc_call("mrooms.set_ready_state",
      { state = ready, roomId = this.roomId },
      function(p) {
        if (!this.isInRoom()) {
          this.isReady = false
          return
        }

        let wasReady = this.isReady
        this.isReady = ready

        //if we receive error on set ready, result is ready == false always.
        if (showMatchingError(p))
          this.isReady = false

        if (this.isReady == wasReady)
          return

        broadcastEvent("LobbyReadyChanged")
      }.bindenv(this))
    return true
  }

  function afterRoomCreation(params) {
    if (showMatchingError(params))
      return this.switchStatus(lobbyStates.NOT_IN_ROOM)

    this.isRoomOwner = true
    this.isRoomByQueue = false
    this.afterRoomJoining(params)
  }

  function destroyRoom() {
    if (!this.isRoomOwner)
      return

    ::matching.rpc_call("mrooms.destroy_room", { roomId = this.roomId })
    SessionLobby.afterLeaveRoom({})
  }

  function leaveRoom() {
    if (this.status == lobbyStates.NOT_IN_ROOM || this.status == lobbyStates.WAIT_FOR_QUEUE_ROOM) {
      this.setWaitForQueueRoom(false)
      return
    }

    ::leave_room({}, function(_p) {
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

    this.roomId = INVALID_ROOM_ID
    this.switchStatus(lobbyStates.NOT_IN_ROOM)
  }

  function sendJoinRoomRequest(join_params, _cb = function(...) {}) {
    if (this.isInRoom())
      this.leaveRoom() //leave old room before join the new one

    leave_mp_session()

    if (!this.isRoomOwner) {
      this.setSettings({})
      this.members = []
    }

    ::LAST_SESSION_DEBUG_INFO =
      ("roomId" in join_params) ? ("room:" + join_params.roomId) :
      ("battleId" in join_params) ? ("battle:" + join_params.battleId) :
      ""

    this.switchStatus(lobbyStates.JOINING_ROOM)
    ::join_room(join_params, this.afterRoomJoining.bindenv(this))
  }

  function joinBattle(battleId) {
    destroyQueue()
    this.isRoomOwner = false
    this.isRoomByQueue = false
    this.sendJoinRoomRequest({ battleId = battleId })
  }

  function joinRoom(v_roomId, senderId = "", v_password = null,
                                  cb = function(...) {}) { //by default not a queue, but no id too
    if (this.roomId == v_roomId && this.isInRoom())
      return

    if (!isLoggedIn.value || this.isInRoom()) {
      delayedJoinRoomFunc = @() SessionLobby.joinRoom(v_roomId, senderId, v_password, cb)

      if (this.isInRoom())
        this.leaveRoom()
      return
    }

    this.isRoomOwner = ::is_my_userid(senderId)
    this.isRoomByQueue = senderId == null

    if (this.isRoomByQueue)
      destroyQueue()
    else
      leaveQueue()

    if (v_password && v_password.len())
      this.changePassword(v_password)

    let joinParams = { roomId = v_roomId }
    if (this.password != "")
      joinParams.password <- this.password

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

    this.roomId = params.roomId
    this.roomUpdated = true
    this.members = getTblValue("members", params, [])

    let public = getTblValue("public", params, this.settings)
    if (!this.isRoomOwner || isEmpty(this.settings)) {
      this.setSettings(public)

      if (this.isRoomByQueue && !this.isSessionStartedInRoom())
        this.isRoomByQueue = false
    }

    for (local i = this.members.len() - 1; i >= 0; i--)
      if (this.isMemberHost(this.members[i])) {
        this.updateMemberHostParams(this.members[i])
        this.members.remove(i)
      }
      else if (::is_my_userid(this.members[i].userId))
          this.isRoomOwner = this.isMemberOperator(this.members[i])

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

    this.roomUpdated = true
    this.checkAutoStart()
  }

  function isMemberHost(m) {
    return (m.memberId == this.memberHostId || (("public" in m) && ("host" in m.public) && m.public.host))
  }

  function isSessionStartedInRoom(room = null) {
    return getTblValue("hasSession", this.getPublicData(room), false)
  }

  function checkAutoStart() {
    if (this.isRoomOwner && !this.isRoomByQueue && this.roomUpdated)
      this.startSession()
  }

  function startSession() {
    if (this.status != lobbyStates.IN_ROOM && this.status != lobbyStates.IN_LOBBY && this.status != lobbyStates.IN_LOBBY_HIDDEN)
      return
    if (!this.isMissionReady()) {
      this.uploadUserMission(function() { SessionLobby.startSession() })
      return
    }
    log("start session")

    ::matching.rpc_call("mrooms.start_session",
      { roomId = this.roomId, cluster = this.getPublicParam("cluster", "EU") },
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

    foreach (m in this.members)
      if (m.memberId == params.memberId) {
        this.onMemberInfoUpdate(params)
        return
      }
    this.members.append(params)
    broadcastEvent("LobbyMembersChanged")
    this.checkAutoStart()
  }

  function onMemberLeave(params, kicked = false) {
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(null)

    foreach (idx, m in this.members)
      if (params.memberId == m.memberId) {
        this.members.remove(idx)
        if (::is_my_userid(m.userId)) {
          this.afterLeaveRoom({})
          if (kicked) {
            if (!isInMenu.value) {
              quit_to_debriefing()
              interrupt_multiplayer(true)
              ::in_flight_menu(false)
            }
            openFMsgBox({ text = loc("matching/msg_kicked"), isPersist = true })
          }
        }
        broadcastEvent("LobbyMembersChanged")
        break
      }
  }

  function rpcJoinBattle(params) {
    if (!::is_online_available())
      return "client not ready"
    let battleId = params.battleId
    if (type(battleId) != "string")
      return "bad battleId type"
    if (SessionLobby.isInRoom())
      return "already in room"
    if (::is_in_flight())
      return "already in session"

    log($"join to battle with id {battleId}")
    SessionLobby.joinBattle(battleId)
    return "ok"
  }

  getMGameMode = @(room = null, _isCustomGameModeAllowed = true)
    gameModesRaw.value?[this.getMGameModeId(room)]

  getRoomEvent = @(room = null) this.getMGameMode(room)

  function canJoinSession() {
    return this.isRoomInSession
  }

  function tryJoinSession() {
     if (!this.canJoinSession())
       return false

     if (this.isRoomInSession) {
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

  if (::is_in_flight())
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

::web_rpc.register_handler("join_battle", SessionLobby.rpcJoinBattle)

g_script_reloader.registerPersistentData("SessionLobby", SessionLobby, SessionLobby[PERSISTENT_DATA_PARAMS])
subscribe_handler(SessionLobby, ::g_listener_priority.DEFAULT_HANDLER)

isMatchingOnline.subscribe(@(_) SessionLobby.leaveRoom())

isInDebriefing.subscribe(@(v) v ? SessionLobby.checkLeaveRoomInDebriefing() : null)

let setHostCb = @() ::set_host_cb(null, @(p) SessionLobby.hostCb(p))
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
  ::matching.subscribe(notificationName, callback)

subscribe("cancelJoiningSession", function(_) {
  destroy_session("on cancel joining session")
  SessionLobby.leaveRoom()
})

::on_connection_failed <- function on_connection_failed(text) {
  if (!SessionLobby.isInRoom())
    return
  destroy_session("on connection failed while in the room")
  SessionLobby.leaveRoom()
  openFMsgBox({ text })
}

subscribe("setWaitForQueueRoom", @(v) SessionLobby.setWaitForQueueRoom(v))

return {
  joinRoom = @(roomId) SessionLobby.joinRoom(roomId)
}
