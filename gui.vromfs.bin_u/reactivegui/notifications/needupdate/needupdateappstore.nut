from "%globalsDarg/darg_library.nut" import *
let { get_all_library_versions } = require("contentUpdater")
let { check_version } = require("%sqstd/version_compare.nut")
let { appStoreProdVersion } = require("%rGui/appStoreVersion.nut")


let needSuggestToUpdate = Computed(function() {
  let actualVersion = appStoreProdVersion.get() ?? ""
  if (actualVersion == "")
    return false
  let all = get_all_library_versions()
  return all.len() != 0 && null == all.findvalue(@(v) check_version($">={actualVersion}", v))
})

return {
  needSuggestToUpdate
}