from "%globalsDarg/darg_library.nut" import *
from "contentUpdater" import get_all_library_versions
from "dagor.system" import DBGLEVEL
from "%sqstd/version_compare.nut" import check_version
from "%rGui/appStoreVersion.nut" import appStoreProdVersion


let logUpdate = log_with_prefix("[UPDATE]: ")


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