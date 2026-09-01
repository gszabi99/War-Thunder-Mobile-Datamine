from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "guiMission" import get_meta_missions_info_by_chapters
from "mission" import get_game_mode, get_cur_game_mode_name
from "%rGui/missions/missionsUtils.nut" import getCombineLocNameMission


function getMissionNameText(mission) {
  if (mission?.isHeader)
    return loc("".concat("chapters/", mission?.id ?? ""))
  if ("blk" in mission)
    return getCombineLocNameMission(mission.blk)
  return loc("".concat("missions/", (mission?.id ?? "")))
}

function getMissionsList() {
  let gm = get_game_mode()
  let res = []
  foreach (chapterMissions in get_meta_missions_info_by_chapters(gm)) {
    if (chapterMissions.len() == 0)
      continue
    let mainChapter = chapterMissions[0]?.chapter ?? get_cur_game_mode_name()
    res.extend(chapterMissions
      .map(@(misBlk) {
        id = misBlk?.name ?? ""
        blk = misBlk
        chapter = misBlk?.chapter ?? mainChapter
        campaign = misBlk?.campaign ?? ""
        presetName = misBlk?.presetName ?? ""
      }))
  }

  return res
}

return {
  getMissionsList
  getMissionNameText
}