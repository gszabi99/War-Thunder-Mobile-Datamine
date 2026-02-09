from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "ios.platform" import getTrackingPermission, ATT_DENIED

let idfaPermission = Watched(getTrackingPermission())
let isIdfaDenied = Computed(@() idfaPermission.get() == ATT_DENIED)

eventbus_subscribe("ios.platform.onPermissionTrackCallback", @(p) idfaPermission.set(p.value))

return {
  isIdfaDenied
}
