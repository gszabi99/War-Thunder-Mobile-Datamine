from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *

let enums = require("%sqStdLibs/helpers/enums.nut")
let { get_meta_mission_info_by_name, get_meta_missions_info_by_chapters,
} = require("guiMission")
let { get_game_mode, get_cur_game_mode_name } = require("mission")
let { getCombineLocNameMission } = require("%scripts/missions/missionsUtils.nut")

enum mislistTabsOrder {
  BASE

  UNKNOWN
}


let g_mislist_type = {
  types = []

  function _getMissionConfig(id) {
    return {
      id
      campaign = ""
      chapter = ""
      misListType = this
      getNameText = function() { return this.misListType.getMissionNameText(this) }
    }
  }

  function _getMissionsByBlkArray(campaignName, missionBlkArray) {
    let res = []
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

      res.append(misDescr)
    }
    return res
  }

  function _getMissionsList(callback) {
    let gm = get_game_mode()
    let res = []
    //collect campaigns chapters list
    let campaigns = [{ chapters = get_meta_missions_info_by_chapters(gm) }]

    foreach (camp in campaigns) {
      let campMissions = []

      foreach (chapterMissions in camp.chapters) {
        if (chapterMissions.len() == 0)
          continue;
        let chapterName = chapterMissions[0].getStr("chapter", get_cur_game_mode_name())

        let missions = this.getMissionsByBlkArray(chapterName, chapterMissions)
        if (!missions.len())
          continue

        campMissions.extend(missions)
      }

      if (!campMissions.len())
        continue

      res.extend(campMissions)
    }
    callback(res)
  }

  function _getMissionsListByNames(namesList) {
    let blkList = []
    foreach (name in namesList) {
      let misBlk = get_meta_mission_info_by_name(name)
      if (misBlk)
        blkList.append(misBlk)
    }
    return this.getMissionsByBlkArray("", blkList)
  }

  function _getMissionNameText(mission) {
    if (mission?.isHeader)
      return loc("".concat("chapters/", mission?.id ?? ""))
    if ("blk" in mission)
      return getCombineLocNameMission(mission.blk)
    return loc("".concat("missions/", (mission?.id ?? "")))
  }

  function getTypeByName(typeName) {
    let res = getTblValue(typeName, this)
    return type(res) == "table" ? res : this.BASE
  }
}

g_mislist_type.template <- {
  id = "" //filled automatically by typeName
  tabsOrder = mislistTabsOrder.UNKNOWN

  getMissionConfig = g_mislist_type._getMissionConfig
  requestMissionsList = function(_isShowCampaigns, callback = null, _customChapterId = null, _customChapters = null) { if (callback) callback([]) }
  getMissionsListByNames = function(_namesList) { return [] }

  getTabName = function() { return "" }

  addToList = function() {}

  getMissionNameText = g_mislist_type._getMissionNameText
}


enums.addTypes(g_mislist_type, {
  BASE = {
    tabsOrder = mislistTabsOrder.BASE
    getTabName = function() { return loc("mainmenu/btnMissions") }

    requestMissionsList = g_mislist_type._getMissionsList
    getMissionsByBlkArray = g_mislist_type._getMissionsByBlkArray
    getMissionsListByNames = g_mislist_type._getMissionsListByNames
  }

}, null, "id", "g_mislist_type")

g_mislist_type.types.sort(function(a, b) {
  if (a.tabsOrder != b.tabsOrder)
    return a.tabsOrder < b.tabsOrder ? -1 : 1
  return 0
})

return g_mislist_type