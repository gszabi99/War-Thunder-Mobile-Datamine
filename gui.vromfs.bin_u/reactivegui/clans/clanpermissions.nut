from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/clanServConfigs.nut" import clanServerConfigs


const CLAN_JOIN_LIST = "clan.join_list"
const CLAN_COMPLETE_REQUEST = "clan.complete_request"
const CLAN_REMOVE = "clan.remove"
const CLAN_GET_LOGS = "clan.get_logs"
const CLAN_EDIT = "clan.change_text_field"
const CLAN_CHANGE_PRIVACY = "clan.change_privacy"
const CLAN_CHANGE_GRADE = "clan.change_grade"
const CLAN_KICK_MEMBER = "clan.kick_user"

let clanGrades = keepref(Computed(@() clanServerConfigs.get()?.grades ?? {}))

function [pure, nodiscard] hasClanPermission(permission, gradesCfg, myGrade, targetGrade = null) {
  let myGradeCfg = gradesCfg?[myGrade]
  if (!(myGradeCfg?.permissions ?? []).contains(permission))
    return false
  if (targetGrade == null)
    return true
  return (myGradeCfg?.order ?? -1) > (gradesCfg?[targetGrade].order ?? -1)
}

return {
  CLAN_JOIN_LIST
  CLAN_COMPLETE_REQUEST
  CLAN_REMOVE
  CLAN_GET_LOGS
  CLAN_EDIT
  CLAN_CHANGE_PRIVACY
  CLAN_CHANGE_GRADE
  CLAN_KICK_MEMBER

  clanGrades
  hasClanPermission
}
