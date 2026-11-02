from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "nestdb" import ndbRead, ndbExists
from "%appGlobals/pServer/clanServConfigs.nut" import clanServerConfigs
from "%appGlobals/config/clanPresentation.nut" import getGradeLocId


const NDB_LANG_ID = "language.localizationInfo"

const TYPE = "type"
const LOCATION = "location"
const LANGUAGE = "language"
const MEMBERS = "members"
const AVAILABILITY = "availability"

let gradesSettingscfg = {
  locTitle = "clans/manage/changeGrade"
  valToString = getGradeLocId
  btnMinWidth = hdpx(400)
  col = 3
}

let languagesCfg = {}
let languageValues = Watched([null])

let clanLocations = Computed(@() clanServerConfigs.get()?.textFields.location.values ?? [])

function fillLanguagesCfg() {
  let values = [null]
  foreach (langCfg in (ndbExists(NDB_LANG_ID) ? ndbRead(NDB_LANG_ID) : [])) {
    languagesCfg[langCfg.id] <- langCfg
    values.append(langCfg.id)
  }
  languageValues.set(values)
}

eventbus_subscribe("localizationInfoUpdate", @(_) fillLanguagesCfg())
fillLanguagesCfg()

return {
  TYPE
  LOCATION
  LANGUAGE
  MEMBERS
  AVAILABILITY
  gradesSettingscfg
  languagesCfg
  languageValues
  clanLocations
}
