from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { mkSwitchComp } = require("%rGui/notifications/consentTcf/mkExpandableSwitch.nut")
let { isOpenedManage, isOpenedMain, showOptInfo, configManagePoints, defaultPointsTable, savedPoints,
  applyConsent } = require("%rGui/notifications/consentFirebase/consentState.nut")
let { mkContent, mkLinkText } = require("%rGui/notifications/consentFirebase/consentComps.nut")

let close = @() isOpenedManage.set(false)

function copyPoints(v){
  let savedPointsClone = clone v
  if((savedPointsClone?.len() ?? 0) == 0)
    return defaultPointsTable
  return savedPointsClone
}

let chosenPoints = copyPoints(savedPoints.get()).map(@(v) Watched(v))
savedPoints.subscribe(@(v) copyPoints(v).each(@(val, id) chosenPoints[id].set(val)))

let mkLabel = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontTiny)

let mkOptionRow = @(id, isEnabledW) {
  size = FLEX_H
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [
        mkLabel(loc($"consentWnd/manage/{id}"))
        mkLinkText(loc("msgbox/error_link_format_game"),
          @() showOptInfo.set(id))
      ]
    }
    mkSwitchComp(Watched(true), isEnabledW)
  ]
}

let manageButtons = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon(utf8ToUpper(loc("consentWnd/manage/acceptAll")), @() applyConsent(defaultPointsTable.map(@(_) true), { wnd="consentManage", action="accept_all" }))
    {size = flex()}
    textButtonPrimary(utf8ToUpper(loc("consentWnd/manage/acceptChoosen")), @() applyConsent(chosenPoints.map(@(v) v.get()), { wnd="consentManage", action="accept_chosen" }))
  ]
}

let pointsComp = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = configManagePoints.map(@(id) mkOptionRow(id, chosenPoints[id]))
}

return @() mkContent(loc("consentWnd/main/manage"), pointsComp, manageButtons, close, !isOpenedMain.get())
