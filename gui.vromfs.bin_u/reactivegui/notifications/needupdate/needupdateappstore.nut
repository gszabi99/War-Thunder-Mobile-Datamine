from "%globalsDarg/darg_library.nut" import *
let logUpdate = log_with_prefix("[UPDATE]: ")
let { get_all_library_versions } = require("contentUpdater")
let { check_version } = require("%sqstd/version_compare.nut")
let { appStoreProdVersion } = require("%rGui/appStoreVersion.nut")
let { DBGLEVEL } = require("dagor.system")


let needSuggestToUpdate = Computed(function() {
  if (DBGLEVEL > 0)
    return false
  let actualVersion = appStoreProdVersion.get() ?? ""
  if (actualVersion == "")
    return false
  let all = get_all_library_versions()
  return all.len() != 0 && null == all.findvalue(@(v) check_version($">={actualVersion}", v))
})

needSuggestToUpdate.subscribe(@(v) !v ? null : logUpdate($"Current version: {appStoreProdVersion.get()}"))

return {
  needSuggestToUpdate
}