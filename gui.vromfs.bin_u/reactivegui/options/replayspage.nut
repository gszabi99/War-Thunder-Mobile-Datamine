from "%globalsDarg/darg_library.nut" import *
let { hud_request_hud_tank_debuffs_state, hud_request_hud_ship_debuffs_state, hud_request_hud_crew_state } = require("hudState")
let { on_view_replay, get_replays_list, get_replay_info } = require("replays")
let { dynamicLoadPreview, dynamicUnloadPreview } = require("dynamicMission")
let { get_meta_mission_info_by_name } = require("guiMission")
let { format, split_by_chars } = require("string")
let { is_dev_version } = require("app")
let regexp2 = require("regexp2")
let { deferOnce } = require("dagor.workcycle")
let { remove_file } = require("dagor.fs")
let DataBlock = require("DataBlock")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { genBotDecorators } = require("%appGlobals/botUtils.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { can_view_replays } = require("%appGlobals/permissions.nut")
let { textButtonPrimary, textButtonInactive, iconButtonCommon } = require("%rGui/components/textButton.nut")
let { mkFoldableList, headerGap, arrowFullSizeW } = require("%rGui/components/foldableSelector.nut")
let { mkOptionValue, OPT_AUTO_DELETE_REPLAYS } = require("%rGui/options/guiOptions.nut")
let { teamBlueLightColor, teamRedLightColor } = require("%rGui/style/teamColors.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { badTextColor, premiumTextColor } = require("%rGui/style/stdColors.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { mkBotInfo } = require("%rGui/mpStatistics/botsInfoState.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { mkTooltipText } = require("%rGui/tooltip.nut")
let logR = log_with_prefix("[REPLAYS] ")
let { startedReplayPath } = require("%rGui/replay/hudReplayControls.nut")


let isDevVersion = is_dev_version()
let devReplayNameRegexp = regexp2(@"^\d{4}$")

let validate = @(val, list) list.contains(val) ? val : list[0]
let allowAutoDeleteReplaysList = [false, true]
let isAllowAutoDeleteReplaysEnabled = mkOptionValue(OPT_AUTO_DELETE_REPLAYS, false,
  @(v) validate(v, allowAutoDeleteReplaysList))

let replaysListRaw = mkWatched(persist, "replaysListRaw", [])
let notAvailableReplaysList = Computed(@() replaysListRaw.get().filter(@(v) v.isNotAvailable).map(@(v) v.path))
let needRemoveReplays = keepref(Computed(@() notAvailableReplaysList.get().len() > 0 && isAllowAutoDeleteReplaysEnabled.get()))

let removedReplays = Watched({})
let replaysList = Computed(@() replaysListRaw.get().filter(@(r) r.path not in removedReplays.get()))

let openedReplayId = Watched(null)
let openedReplayMissionName = keepref(Computed(@() replaysList.get().findvalue(@(r) r.path == openedReplayId.get())?.missionName ?? ""))

let isReplayLoading = Watched(false)

let resultTextByStatus = {
  success = {
    text = "msgbox/btn_yes"
    color = premiumTextColor
  }
  fail = {
    text = "msgbox/btn_no"
    color = badTextColor
  }
}

let rowHeight = hdpx(76)
let mapSize = hdpx(370)
let playerRowHeight = hdpx(60)
let columnGap = hdpx(10)
let avatarHeight = playerRowHeight - hdpx(2)
let bgColor = 0xC0000000
let cellTextColor = 0xFFFFFFFF
let textColor = 0xFFFFFFFF
let checkBorderColor = 0xFF9FA7AF
let ctrlHeight = hdpx(60)
let checkIconSize = hdpxi(40)
let minFoldableContentHeight = mapSize + columnGap + defButtonHeight * 2

function askActivateAutoDeleteOpt(list, cb) {
  let notAvailableReplaysCount = list.filter(@(v) v.isNotAvailable).len()
  if (notAvailableReplaysCount == 0)
    return cb()

  openMsgBox({
    text = loc("mainmenu/replay/askForRemove", { count = notAvailableReplaysCount }),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "delete", cb, styleId = "PRIMARY", isDefault = true }
    ]
  })
}

function startReplay(path) {
  if (isReplayLoading.get())
    return
  isReplayLoading.set(true)

  startedReplayPath.set(path)
  hud_request_hud_tank_debuffs_state()
  hud_request_hud_ship_debuffs_state()
  hud_request_hud_crew_state()
  on_view_replay(path)
}

function updateMapPreview(misName = "") {
  if (misName == "")
    return

  let misData = get_meta_mission_info_by_name(misName)
  if (misData) {
    let mis = DataBlock()
    mis.load(misData.getStr("mis_file", ""))
    dynamicLoadPreview(mis)
  }
}

openedReplayId.subscribe(@(_) dynamicUnloadPreview())
openedReplayMissionName.subscribe(@(v) !v ? dynamicUnloadPreview() : deferOnce(@() updateMapPreview(v)))

let replaySort = @(a, b) a.isNotAvailable <=> b.isNotAvailable
  || b?.startTime <=> a?.startTime
  || b.name <=> a.name

let getReplayDate = @(r) " ".concat(loc("date_format", r.dateTime.__merge({ month = r.dateTime.month + 1 })),
  format("%02d:%02d", r.dateTime.hour, r.dateTime.min))

function refreshReplaysList() {
  let replays = get_replays_list()
  let res = []

  foreach (replay in replays.filter(@(rep) !isDevVersion || (!devReplayNameRegexp.match(rep.name) || rep.name == "0000"))) {
    let replayInfo = get_replay_info(replay.path)
    let commentsBlk = replayInfo?.comments
    if (!commentsBlk && !isDevVersion)
      continue

    let alliesTeam = []
    let enemiesTeam = []
    let playersBlkList = commentsBlk == null ? [] : commentsBlk % "player"
    let authorUserId = (commentsBlk?.authorUserId ?? "0").tointeger()
    let status = commentsBlk == null ? "" : commentsBlk % "status"
    let locName = getMissionLocName(replayInfo, "locName")
    let isNotAvailable = replay.isVersionMismatch || replay.corrupted

    let mplayers = []
    foreach (b in playersBlkList) {
      let userId = (b?.userId ?? "0").tointeger()
      if (userId == 0)
        continue
      if ((b?.name ?? "") == "" && (b?.nick ?? "") == "")
        continue

      let mplayer = {
        userId = userId
        name = b?.name ?? ""
        team = b?.team ?? 0
        isBot = userId < 0
      }

      if (mplayer.name == "") {
        let parts = split_by_chars(b?.nick ?? "", " ")
        mplayer.name = parts.len() == 2 ? parts[1] : parts[0]
      }

      if (mplayer?.isBot && mplayer?.name.indexof("/") != null)
        mplayer.name = loc(mplayer.name)

      mplayers.append(mplayer)
    }

    let localPlayer = mplayers.findvalue(@(p) p.userId == authorUserId)
    let localTeam = localPlayer?.team ?? 1
    foreach (mplayer in mplayers)
      if (mplayer.team == localTeam)
        alliesTeam.append(mplayer)
      else
        enemiesTeam.append(mplayer)

    res.append({
      path = replay.path
      name = replay.name
      date = isNotAvailable ? "" : getReplayDate(replay)
      missionName = replayInfo.missionName
      version = replayInfo.gameVersion
      isVersionMismatch = replay.isVersionMismatch
      corrupted = replay.corrupted
      isNotAvailable
      alliesTeam
      enemiesTeam
      locName
      status
    })
  }

  replaysListRaw.set(res.sort(replaySort))
}

function deleteReplayFile(path) {
  let status = remove_file(path)
  if (status)
    logR($"The replay file {path} has been deleted") 
  else
    logerr($"Error while trying to delete file: /*{path}*/")
}

local pathsToDelete = []
function deleteReplaysList() {
  if (pathsToDelete.len() == 0)
    return
  let lastPath = pathsToDelete.pop()
  if (!lastPath)
    return

  deleteReplayFile(lastPath)
  deferOnce(deleteReplaysList)
}

function deleteReplayManually(path) {
  let idx = replaysListRaw.get().findindex(@(r) r.path == path)
  if (idx == null)
    return

  replaysListRaw.mutate(@(v) v.remove(idx))
  deleteReplayFile(path)
}

function onDeleteReplay(replay) {
  openMsgBox({
    text = loc("mainmenu/replay/confirmUserReplayDeletion", {name = replay.name})
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "delete", cb = @() deleteReplayManually(replay.path), styleId = "PRIMARY" }
    ]
  })
}

function removeUnavailableReplays() {
  let pathsList = notAvailableReplaysList.get().filter(@(v) v not in removedReplays.get())
  if (pathsList.len() == 0)
    return
  removedReplays.set(removedReplays.get().__merge(pathsList.reduce(@(acc, v) acc.$rawset(v, true), {})))

  pathsToDelete.extend(pathsList)
  deleteReplaysList()
}

needRemoveReplays.subscribe(@(v) v ? removeUnavailableReplays() : null)

let showReplayError = @(isCorrupted)
  openMsgBox({
    text = isCorrupted
      ? loc("replays/corrupted")
      : loc("replays/versionMismatch")
  })

let progressSpinner = {
  size = [flex(), defButtonHeight]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = spinner
}

let cellTextProps = {
  rendObj = ROBJ_TEXT
  color = cellTextColor
}.__update(fontTinyAccentedShaded)

let mkContentText = @(text, ovr = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  text
  color = cellTextColor
}.__update(fontTiny, ovr)

let mkCheckIcon = @(isChecked, opacity) {
  size = ctrlHeight
  rendObj = ROBJ_BOX
  opacity = isChecked ? 1.0 : 0.5
  borderColor = checkBorderColor
  borderWidth = hdpx(3)
  children = !isChecked ? null
    : {
        size = checkIconSize
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#check.svg:{checkIconSize}:{checkIconSize}")
        keepAspect = KEEP_ASPECT_FIT
        color = textColor
        opacity
      }
}

let mkTrashButton = @(onClick) iconButtonCommon("ui/gameuiskin#btn_trash.svg", onClick,
  {
    iconSize = hdpx(50),
    ovr = {
      size = [defButtonHeight, defButtonHeight],
      minWidth = defButtonHeight
    }
  })

function mkCheckBtn(isChecked, onClick, text, description) {
  let stateFlags = Watched(0)
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      @() {
        watch = [stateFlags, isChecked]
        size = [hdpx(600), SIZE_TO_CONTENT]
        behavior = Behaviors.Button
        onClick
        onElemState = @(s) stateFlags.set(s)
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(10)
        children = [
          mkCheckIcon(isChecked.get(), stateFlags.get() & S_ACTIVE ? 0.5 : 1.0)
          mkContentText(text)
        ]
      }
      infoTooltipButton(
        @() mkTooltipText(description),
        { halign = ALIGN_RIGHT },
        {
          size = hdpx(52)
          fillColor = 0x80000000
          children = {
            rendObj = ROBJ_TEXT
            text = "i"
            halign = ALIGN_CENTER
          }.__update(fontTinyAccented)
        })
    ]
  }
}

let mkResultContent = @(status) status != "" && status in resultTextByStatus
  ? mkContentText(utf8ToUpper(loc(resultTextByStatus[status].text)), { color = resultTextByStatus[status].color })
  : null

let replayColumnsCfg = [
  { width = pw(15), contentCtor = @(r) mkContentText(r.date), headerText = "mainmenu/replay/date" }
  { width = pw(30), contentCtor = @(r) mkContentText(r.name), headerText = "mainmenu/replay/name" }
  { width = pw(40), contentCtor = @(r) mkContentText(r?.locName ?? ""), headerText = "mainmenu/replay/location" }
  { width = pw(15), contentCtor = @(r) mkResultContent(r?.status[0] ?? ""), headerText = "debriefing/victory" }
]

let mkHeaderRow = @(columnCfg) {
  size = [flex(), rowHeight]
  flow = FLOW_HORIZONTAL
  padding = [0, 0, 0, headerGap + arrowFullSizeW]
  rendObj = ROBJ_SOLID
  color = bgColor
  gap = columnGap
  children = columnCfg.map(@(c) {
    size = [c.width, flex()]
    halign = ALIGN_LEFT
    valign = ALIGN_CENTER
    children = cellTextProps.__merge({ text = loc(c.headerText) })
  })
}

let mkFoldableHeader = @(replay, columnCfg) {
  size = [flex(), rowHeight]
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = columnCfg.map(@(c) {
    size = [c.width, flex()]
    halign = ALIGN_LEFT
    valign = ALIGN_TOP
    children = c.contentCtor(replay)
  })
}

let mkPlayerName = @(player, teamColor, halign) {
  rendObj = ROBJ_TEXT
  maxWidth = pw(100)
  valign = ALIGN_TOP
  halign
  color = teamColor
  text = player.name
}.__update(fontVeryTinyAccented)

function mkAvatar(player) {
  let { userId, isBot, name } = player
  let userIdStr = userId.tostring()
  let info = isBot
    ? mkBotInfo(player.__merge({ decorators = genBotDecorators(name) }))
    : mkPublicInfo(userIdStr)

  return @() {
    watch = info
    onAttach = @() isBot ? null : refreshPublicInfo(userIdStr)
    size = [avatarHeight, avatarHeight]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(info.get()?.decorators.avatar)}:{avatarHeight}:{avatarHeight}:P")
  }
}

let mkPlayer = @(player, teamColor, halign) {
  size = [flex(), playerRowHeight]
  children = [
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      padding = halign == ALIGN_RIGHT ? [hdpx(2), 0, hdpx(2), hdpx(4)] : [hdpx(2), hdpx(4), hdpx(2), 0]
      gap = hdpx(4)
      halign
      children = halign == ALIGN_RIGHT
        ? [
            mkPlayerName(player, teamColor, halign)
            mkAvatar(player)
          ]
        : [
            mkAvatar(player)
            mkPlayerName(player, teamColor, halign)
          ]
    }
  ]
}

let mkTeamColumn = @(team, teamColor, align) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = team.map(@(player) mkPlayer(player, teamColor, align))
}

let mkReplayPlayersList = @(replay) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = [
    mkTeamColumn(replay.alliesTeam, teamBlueLightColor, ALIGN_LEFT)
    mkTeamColumn(replay.enemiesTeam, teamRedLightColor, ALIGN_RIGHT)
  ]
}

let mkFoldableContent = @(replay, isActive) @() {
  watch = isActive
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = columnGap
  children = !isActive.get()
    ? {
        size = FLEX_H
        minHeight = minFoldableContentHeight
        rendObj = ROBJ_SOLID
        color = 0x00000000
      }
    : [
        {
          size = FLEX_V
          minHeight = minFoldableContentHeight
          flow = FLOW_VERTICAL
          children = [
            {
              size = mapSize
              rendObj = ROBJ_TACTICAL_MAP
            }
            replay.isNotAvailable
              ? mkContentText(loc("mainmenu/replay/version/unavailable", { version = replay.version }),
                  { color = badTextColor })
              : mkContentText(loc("mainmenu/replay/version", { version = replay.version }))
            {
              size = FLEX_V
            }
            @() {
              watch = isReplayLoading
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = columnGap
              children = [
                replay.isNotAvailable
                    ? textButtonInactive(utf8ToUpper(loc("strategyMode/launch")),
                        @() showReplayError(replay.corrupted), { ovr = { minWidth = 0, size = [flex(), defButtonHeight] } })
                  : !isReplayLoading.get()
                    ? textButtonPrimary(utf8ToUpper(loc("strategyMode/launch")),
                        @() notAvailableForSquadMsg(@() startReplay(replay.path)),
                        { ovr = { minWidth = 0, size = [flex(), defButtonHeight] } })
                  : progressSpinner
                !isReplayLoading.get() ? mkTrashButton(@() onDeleteReplay(replay)) : null
              ]
            }
          ]
        }
        mkReplayPlayersList(replay)
      ]
}

function mkRow(replay, columnsCfg, idx) {
  let isActive = Computed(@() openedReplayId.get() == replay.path)

  return {
    size = FLEX_H
    rendObj = ROBJ_SOLID
    color = (idx % 2) ? 0x80808080 : 0x00000000
    children = mkFoldableList(
      mkFoldableContent(replay, isActive),
      mkFoldableHeader(replay, columnsCfg),
      openedReplayId,
      replay.path)
  }
}

let mkReplaysRows = @(replays, columnsCfg) @(){
  watch = can_view_replays
  size = FLEX_H
  halign = ALIGN_CENTER
  children = !can_view_replays.get() ? mkContentText(loc("mainmenu/replay/list/unavailable"), fontTinyAccented)
    : replays.len() == 0 ? mkContentText(loc("mainmenu/noReplays"), fontTinyAccented)
    : makeVertScroll({
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = replays.map(@(replay, idx) mkRow(replay, columnsCfg, idx))
      },
      {
        size = [flex(), saSize[1] - (gamercardHeight + rowHeight + columnGap * 2 + saBorders[1])]
        isBarOutside = true
        barStyleCtor = @(hasScroll) !hasScroll ? {}
          : {
              pos = [columnGap, 0]
              rendObj = ROBJ_SOLID
              color = bgColor
            }
      })
}

return @() {
  size = flex()
  watch = replaysList
  onAttach = @() refreshReplaysList()
  function onDetach() {
    dynamicUnloadPreview()
    openedReplayId.set(null)
    isReplayLoading.set(false)
  }
  halign = ALIGN_CENTER
  valign = ALIGN_TOP
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    {
      hplace = ALIGN_LEFT
      children = mkCheckBtn(isAllowAutoDeleteReplaysEnabled,
        @() askActivateAutoDeleteOpt(replaysList.get(),
          @() isAllowAutoDeleteReplaysEnabled.set(!isAllowAutoDeleteReplaysEnabled.get())),
        loc("options/allow_auto_delete_replays"),
        loc("options/allow_auto_delete_replays_description"))
    }
    mkHeaderRow(replayColumnsCfg)
    mkReplaysRows(replaysList.get(), replayColumnsCfg)
  ]
}
