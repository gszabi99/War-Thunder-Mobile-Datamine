from "%scripts/dagui_library.nut" import *
//-file:plus-string

//checked for explicitness
#no-root-fallback
#explicit-this

from "%appGlobals/unitConst.nut" import *
let { get_blk_value_by_path, blkOptFromPath } = require("%sqStdLibs/helpers/datablockUtils.nut")
let enums = require("%sqStdLibs/helpers/enums.nut")
let { isPlatformSony, isPlatformXboxOne } = require("%appGlobals/clientState/platform.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { get_meta_mission_info_by_name, get_meta_missions_info_by_chapters,
  get_mission_local_online_progress } = require("guiMission")
let { get_game_mode, get_cur_game_mode_name } = require("mission")

enum mislistTabsOrder {
  BASE
  UGM

  UNKNOWN
}

::g_mislist_type <- {
  types = []
}

::g_mislist_type._getMissionConfig <- function _getMissionConfig(id, isHeader = false, isCampaign = false, isUnlocked = true) {
  return {
    id = id
    isHeader = isHeader
    isCampaign = isCampaign
    isUnlocked = isUnlocked
    campaign = ""
    chapter = ""
    misListType = this

    getNameText = function() { return this.misListType.getMissionNameText(this) }
  }
}

::g_mislist_type._getMissionsByBlkArray <- function _getMissionsByBlkArray(campaignName, missionBlkArray) {
  let res = []
  let gm = get_game_mode()
  let checkFunc = getTblValue("misBlkCheckFunc", this, function(_misBlk) { return true })

  foreach (misBlk in missionBlkArray) {
    let missionId = misBlk?.name ?? ""
    if (!checkFunc(misBlk))
      continue

    let misDescr = this.getMissionConfig(missionId)
    misDescr.blk <- misBlk
    misDescr.chapter <- campaignName
    misDescr.campaign <- misBlk.getStr("campaign", "")
    misDescr.presetName <- misBlk.getStr("presetName", "")

    if (::is_user_mission(misBlk)) {
      // Temporary fix for 1.53.7.X (workaround for not detectable player_class).
      // Can be removed after http://cvs1.gaijin.lan:8080/#/c/57465/ reach all PC platforms.
      if (!misBlk?.player_class) {
        let missionBlk = blkOptFromPath(misBlk?.mis_file)
        let wing = get_blk_value_by_path(missionBlk, "mission_settings/player/wing")
        let unitsBlk = missionBlk?.units
        if (unitsBlk && wing)
          for (local i = 0; i < unitsBlk.blockCount(); i++) {
            let block = unitsBlk.getBlock(i)
            if (block?.name == wing && block?.unit_class) {
              misBlk.player_class   = block.unit_class
              misBlk.player_weapons = block?.weapons
              break
            }
          }
      }

      let reqUnit = misBlk.getStr("player_class", "")
      if (reqUnit in myUnits.value) {
        misDescr.isUnlocked = false
        misDescr.mustHaveUnit <- reqUnit
      }
    }

    if (gm == GM_CAMPAIGN || gm == GM_SINGLE_MISSION || gm == GM_TRAINING) {
      let missionFullName = campaignName + "/" + (misDescr?.id ?? "")
      misDescr.progress <- ::get_mission_progress(missionFullName)
      if (!::is_user_mission(misBlk))
        misDescr.isUnlocked = misDescr?.progress != 4
      let misLOProgress = get_mission_local_online_progress(missionFullName)
      misDescr.singleProgress <- misLOProgress?.singleDiff
      misDescr.onlineProgress <- misLOProgress?.onlineDiff

      // progress: 0 - completed (arcade), 1 - completed (realistic), 2 - completed (hardcore)
      // 3 - unlocked but not completed, 4 - locked
      if (::is_user_mission(misBlk) && !misDescr?.isUnlocked)
        misDescr.progress = 4
    }

    res.append(misDescr)
  }
  return res
}

::g_mislist_type._getMissionsList <- function _getMissionsList(callback) {
  let gm = get_game_mode()
  let res = []
  //collect campaigns chapters list
  let campaigns = [{ chapters = get_meta_missions_info_by_chapters(gm) }]

  foreach (camp in campaigns) {
    let campName = getTblValue("name", camp)
    let campMissions = []
    local lastMission = null

    foreach (chapterMissions in camp.chapters) {
      if (chapterMissions.len() == 0)
        continue;
      let chapterName = chapterMissions[0].getStr("chapter", get_cur_game_mode_name())

      let isChapterSpecial = isInArray(chapterName, [ "hidden", "test" ])

      let missions = this.getMissionsByBlkArray(chapterName, chapterMissions)
      if (!missions.len())
        continue

      if (this.showChapterHeaders) {
        local isChapterUnlocked = true
        if (lastMission && gm == GM_CAMPAIGN)
          isChapterUnlocked = isChapterSpecial || ::is_debug_mode_enabled || ::is_mission_complete(lastMission?.chapter, lastMission?.id)
        let chapterHeader = this.getMissionConfig(chapterName, true, false, isChapterUnlocked)
        campMissions.append(chapterHeader)
      }
      campMissions.extend(missions)

      lastMission = missions.top()
    }

    if (!campMissions.len())
      continue

    if (campName && this.showCampaignHeaders) {
      let campHeader = this.getMissionConfig(campName, true, true)
      res.append(campHeader)
    }
    res.extend(campMissions)

    //add victory video for campaigns
    if (lastMission && gm == GM_CAMPAIGN
        && (campName == "usa_pacific_41_43" || campName == "jpn_pacific_41_43")) {
      let isVideoUnlocked = ::is_debug_mode_enabled || ::is_mission_complete(lastMission?.chapter, lastMission?.id)
      res.append(this.getMissionConfig("victory", true, false, isVideoUnlocked))
    }
  }
  callback(res)
}

::g_mislist_type._getMissionsListByNames <- function _getMissionsListByNames(namesList) {
  let blkList = []
  foreach (name in namesList) {
    let misBlk = get_meta_mission_info_by_name(name)
    if (misBlk)
      blkList.append(misBlk)
  }
  return this.getMissionsByBlkArray("", blkList)
}

::g_mislist_type._getMissionNameText <- function _getMissionNameText(mission) {
  if (mission?.isHeader)
    return loc((mission?.isCampaign ? "campaigns/" : "chapters/") + (mission?.id ?? ""))
  if ("blk" in mission)
    return ::get_combine_loc_name_mission(mission.blk)
  return loc("missions/" + (mission?.id ?? ""))
}

::g_mislist_type.template <- {
  id = "" //filled automatically by typeName
  tabsOrder = mislistTabsOrder.UNKNOWN

  canBeEmpty = true
  canRefreshList = false
  canAddToList = false

  showCampaignHeaders = true
  showChapterHeaders  = true

  getMissionConfig = ::g_mislist_type._getMissionConfig
  requestMissionsList = function(_isShowCampaigns, callback = null, _customChapterId = null, _customChapters = null) { if (callback) callback([]) }
  getMissionsListByNames = function(_namesList) { return [] }
  canJoin = function(_gm) { return true }
  canCreate = function(gm) { return this.canJoin(gm) }

  getTabName = function() { return "" }

  addToList = function() {}
  canModify = function(_mission) { return false }
  modifyMission = function(_mission) {}
  canDelete = function(_mission) { return false }
  deleteMission = function(_mission) {}

  canMarkFavorites = function() {
    let gm = get_game_mode()
    return gm == GM_DOMINATION || gm == GM_SKIRMISH
  }

  isMissionFavorite = function(mission) { return ::is_mission_favorite(mission.id) }
  toggleFavorite = function(mission) { ::toggle_fav_mission(mission.id) }

  getMissionNameText = ::g_mislist_type._getMissionNameText

  infoLinkLocId = ""
  infoLinkTextLocId = ""
  infoLinkTooltipLocId = ""
  getInfoLinkData = function() {
    if (isPlatformSony || isPlatformXboxOne || !this.infoLinkLocId.len())
      return null

    return {
      link = loc(this.infoLinkLocId)
      text = loc(this.infoLinkTextLocId)
      tooltip = loc(this.infoLinkTooltipLocId, "")
    }
  }

  sortMissionsByName = function(missions) {
    let sortData = ::u.map(missions, (@(m) { locName = this.getMissionNameText(m), mission = m }).bindenv(this))
    sortData.sort(@(a, b) a.locName <=> b.locName)
    return ::u.map(sortData, @(d) d.mission)
  }
}

enums.addTypesByGlobalName("g_mislist_type", {
  BASE = {
    tabsOrder = mislistTabsOrder.BASE
    canBeEmpty = false
    getTabName = function() { return loc("mainmenu/btnMissions") }

    requestMissionsList = ::g_mislist_type._getMissionsList
    getMissionsByBlkArray = ::g_mislist_type._getMissionsByBlkArray
    getMissionsListByNames = ::g_mislist_type._getMissionsListByNames
    misBlkCheckFunc = function(misBlk) {
      return !::is_user_mission(misBlk)
    }
  }

  UGM = {
    tabsOrder = mislistTabsOrder.UGM
    canRefreshList = true
    getTabName = function() { return loc("mainmenu/btnUserMission") }
    infoLinkLocId = "url/live/user_missions"
    infoLinkTextLocId = "missions/user_missions/getOnline"
    infoLinkTooltipLocId = "missions/user_missions/about"

    canJoin = @(_gm) false

    requestMissionsList = function(callback) {
      let fn = function() { this.getMissionsListImpl(callback); }
      ::scan_user_missions(this, fn.bindenv(this))
    }
    getMissionsListImpl = ::g_mislist_type._getMissionsList
    getMissionsByBlkArray = ::g_mislist_type._getMissionsByBlkArray
    misBlkCheckFunc = ::is_user_mission
  }
}, null, "id")

::g_mislist_type.types.sort(function(a, b) {
  if (a.tabsOrder != b.tabsOrder)
    return a.tabsOrder < b.tabsOrder ? -1 : 1
  return 0
})

::g_mislist_type.getTypeByName <- function getTypeByName(typeName) {
  let res = getTblValue(typeName, ::g_mislist_type)
  return ::u.isTable(res) ? res : this.BASE
}
