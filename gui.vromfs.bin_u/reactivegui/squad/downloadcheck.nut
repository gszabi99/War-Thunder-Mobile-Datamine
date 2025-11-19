from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader, squadLeaderDownloadCheckTime,
  squadLeaderWantedModeId, squadLeaderCampaign, isReady
from "%appGlobals/updater/addonsState.nut" import hasAddons, addonsExistInGameFolder,
  addonsVersions, unitSizes
from "%appGlobals/updater/gameModeAddons.nut" import missingUnitResourcesByRank, allUnitsRanks,
  getModeAddonsInfo, allBattleUnits, maxReleasedUnitRanks
from "%appGlobals/updater/addons.nut" import localizeAddons
from "%appGlobals/updater/campaignAddons.nut" import localizeUnitsResources
from "%appGlobals/clientState/clientState.nut" import isInDebriefing, isInBattle, isInLoadingScreen
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
import "%rGui/squad/setReady.nut" as setReady
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd
from "%rGui/debriefing/debriefingState.nut" import isDebriefingAnimFinished
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
import "%rGui/gameModes/getGameModeLocName.nut" as getGameModeLocName
from "%rGui/style/stdColors.nut" import markTextColor


let MSG_UID = "mRankCheck"
let CAN_REPEAT_SEC = 15
let wantedModeId = hardPersistWatched("wantedModeId", -1)
let downloadCheckTime = hardPersistWatched("downloadCheckTime", 0)
let isDownloadCheckSuspended = Watched(false)
let leaderWantedMode = Computed(@() allGameModes.get()?[squadLeaderWantedModeId.get()])
isInSquad.subscribe(@(_) downloadCheckTime.set(isSquadLeader.get() ? 0 : serverTime.get()))
isSquadLeader.subscribe(@(v) !isInSquad.get() ? null
  : downloadCheckTime.set(v ? 0 : serverTime.get()))

let needDownloadCheckMsg = Computed(@() isInSquad.get()
  && !isSquadLeader.get()
  && squadLeaderDownloadCheckTime.get() > downloadCheckTime.get()
  && leaderWantedMode.get() != null)
let canShowDownloadCheck = Computed(@() !isInBattle.get()
  && !isInLoadingScreen.get()
  && (!isInDebriefing.get() || isDebriefingAnimFinished.get()))

let shouldShowMsg = keepref(Computed(@() needDownloadCheckMsg.get() && canShowDownloadCheck.get()))

function initiateDownloadCheck(modeId) {
  if (!isSquadLeader.get())
    return
  if (isDownloadCheckSuspended.get()) {
    openMsgBox({ text = loc("msg/squadAddons/checkInCooldown") })
    return
  }
  downloadCheckTime.set(serverTime.get())
  wantedModeId.set(modeId)
  isDownloadCheckSuspended.set(true)
  resetTimeout(CAN_REPEAT_SEC, @() isDownloadCheckSuspended.set(false))
}

function showDownloadCheck() {
  if (!shouldShowMsg.get() || leaderWantedMode.get() == null)
    return

  let { addonsToDownload, unitsToDownload } = getModeAddonsInfo({
    mode = leaderWantedMode.get(),
    unitNames = allBattleUnits.get(),
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
  if (addonsToDownload.len() + unitsToDownload.len() == 0) {
    downloadCheckTime.set(serverTime.get())
    return
  }

  let wasReady = isReady.get()
  setReady(false)

  let { name = null, campaign = squadLeaderCampaign.get() } = leaderWantedMode.get()
  let locs = localizeAddons(addonsToDownload)
  log($"[ADDONS] Ask update addons by squad leader for mode {name}:", addonsToDownload)
  if (unitsToDownload.len() > 0) {
    let unitLocs = localizeUnitsResources(unitsToDownload, allUnitsRanks.get(), campaign)
    locs.extend(unitLocs)
    log($"[ADDONS] Ask download units by squad leader for mode {name} ({unitsToDownload.len()}):", unitLocs)
  }

  openFMsgBox({
    viewType = "downloadMsg"
    addons = addonsToDownload
    units = unitsToDownload
    bqAction = "msg_download_addons_by_squad_leader"
    bqData = { source = name, unit = ";".join(allBattleUnits.get()) }

    text = loc("msg/squadAddons/askDownload",
      { count = locs.len(),
        addon = ", ".join(locs.map(@(t) colorize("@mark", t)))
        modeName = colorize(markTextColor, getGameModeLocName(leaderWantedMode.get()))
      })
    buttons = [
      { id = "cancel", isCancel = true, eventId = "cancelDownloadAddonsForSquad" }
      { text = loc("msgbox/btn_download")
        eventId = wasReady ? "downloadAddonsForSquadWithReady" : "downloadAddonsForSquad"
        context = { addons = addonsToDownload, units = unitsToDownload }
        styleId = "PRIMARY"
        isDefault = true
      }
    ]
  })
}

showDownloadCheck()
shouldShowMsg.subscribe(@(v) v ? resetTimeout(0.1, showDownloadCheck) : closeMsgBox(MSG_UID))

subscribeFMsgBtns({
  initiateSquadAddonsDownload = @(evt) initiateDownloadCheck(evt.modeId)

  cancelDownloadAddonsForSquad = @(_) downloadCheckTime.set(serverTime.get())

  function downloadAddonsForSquad(p) {
    downloadCheckTime.set(serverTime.get())
    openDownloadAddonsWnd(p.addons, p.units, "squadAcceptDownloadByLeader")
  }

  function downloadAddonsForSquadWithReady(p) {
    downloadCheckTime.set(serverTime.get())
    openDownloadAddonsWnd(p.addons, p.units, "squadAcceptDownloadByLeader", {}, "squadSetReady")
  }
})

return {
  wantedModeId
  downloadCheckTime
}