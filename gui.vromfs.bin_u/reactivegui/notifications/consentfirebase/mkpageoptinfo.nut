from "%globalsDarg/darg_library.nut" import *
from "%rGui/notifications/consentFirebase/consentState.nut" import showOptInfo
from "%rGui/notifications/consentFirebase/consentComps.nut" import mkContent

let close = @() showOptInfo.set(null)

let infoComp = @() {
  watch = showOptInfo
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = showOptInfo.get() == null ? "" : loc($"consentWnd/manage/desc/{showOptInfo.get()}")
}.__update(fontTiny)

return @() mkContent(loc("msgbox/error_link_format_game"), infoComp, null, close)
