from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let iOsPlaform = require("ios.platform")
let { getTrackingPermission, ATT_DENIED } = iOsPlaform

let idfaPermission = Watched(getTrackingPermission())
let isIdfaDenied = Computed(@() idfaPermission.get() == ATT_DENIED)

eventbus_subscribe("ios.platform.onPermissionTrackCallback", @(p) idfaPermission.set(p.value))

return {
  isIdfaDenied
}



