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

let memberSortOptions = [
  {
    id = "campaigns"
    buildCtx = function(users, deps) {
      let campaigns = deps.campaigns()
      let allInfo = deps.allInfo()
      let totals = {}

      foreach (user in users) {
        let uid = user.userId.tostring()
        let userCampaigns = allInfo?[uid]?.general.campaigns

        local total = 0
        foreach (campaign in campaigns)
          total += userCampaigns?[campaign].level ?? 0

        totals[uid] <- total
      }

      return { totals }
    }
    getKey = @(user, ctx) ctx.totals?[user.userId.tostring()] ?? 0
  }
  {
    id = "rank"
    buildCtx = @(_, deps) { grades = deps.grades() }
    getKey = @(user, ctx) ctx.grades?[user?.gradeStr].order ?? -1
  }
  {
    id = "alphabet"
    buildCtx = function(users, deps) {
      let contacts = deps.contacts()
      let nicks = {}
      foreach (user in users) {
        let uid = user.userId.tostring()
        nicks[uid] <- (contacts?[uid].realnick ?? uid).tolower()
      }
      return { nicks }
    }
    getKey = @(user, ctx) ctx.nicks?[user.userId.tostring()] ?? user.userId.tostring()
  }
]

let memberSortingCfg = {
  locTitle = "clans/members/sortBy"
  values = memberSortOptions.map(@(o) o.id)
  valToString = @(v) $"clans/members/sort/{v}"
  btnMinWidth = hdpx(300)
  col = 3
}

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
  memberSortOptions
  memberSortingCfg
  gradesSettingscfg
  languagesCfg
  languageValues
  clanLocations
}
