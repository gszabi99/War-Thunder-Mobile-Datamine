from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%rGui/legal.nut" import legalToApprove
from "%appGlobals/loginState.nut" import isOpenedLegalWnd
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/textButton.nut" import buttonsHGap, mkCustomButton, buttonStyles
from "%rGui/components/urlText.nut" import urlText
from "%rGui/controlsMenu/gpActBtn.nut" import EMPTY_ACTION
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/login/legalState.nut" import acceptAllLegals, isAcceptLegalsInProgress


const WND_UID = "legalAcceptWnd"

const urlColor = 0xFF17C0FC
const wndWidthDefault = hdpx(1300)
const wndHeight = hdpx(650)

let urlStyle = { ovr = { color = urlColor }, childOvr = { color = urlColor } }
function legalInfoUrl(legalCfg) {
  let { url, locId } = legalCfg
  return urlText(loc($"{locId}"), url, urlStyle)
}

function replaceExtremeSpacesToNbsp(text) {
  local result = text
  if (result.startswith(" "))
    result = "".concat(nbsp, result.slice(1))
  if (result.endswith(" "))
    result = "".concat(result.slice(0, -1), nbsp)
  return result
}

let mkTextarea = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  preformatted = FMT_KEEP_SPACES
  text = replaceExtremeSpacesToNbsp(text) 
  maxWidth = wndWidthDefault - buttonsHGap
}.__update(fontSmall)

let legalList = {
  size = FLEX_H
  children = [
    wrap(
      mkTextRow(
        loc("legals/byClickingBtnYouAcceptAllLegals")
        mkTextarea
        {
          ["{btnText}"] = mkTextarea(utf8ToUpper(loc("terms_wnd/accept/noNewLine"))), 
          ["{termsOfServiceUrl}"] = legalInfoUrl(legalToApprove["termsofservice"]), 
          ["{privacyPolicyUrl}"] = legalInfoUrl(legalToApprove["privacypolicy"]) 
        }
      ),
      {
        width = wndWidthDefault - buttonsHGap
        flow = FLOW_HORIZONTAL
        vGap = hdpx(16)
      }
    )
  ]
}

let acceptText = {
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  halign = ALIGN_CENTER
  text = utf8ToUpper(loc("terms_wnd/accept"))
}.__update(fontTinyAccentedShaded)

let acceptButton = mkCustomButton(
  acceptText,
  function() {
    if (isAcceptLegalsInProgress.get())
      return
    sendUiBqEvent("legal_accept_wnd", { id = "accept" })
    acceptAllLegals()
  },
  buttonStyles.PRIMARY.__merge({ hotkeys = ["^J:X"] }))

let wndContent = {
  size = FLEX
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap =  { size = FLEX }
  padding = buttonsHGap
  children = [
    legalList
    acceptButton
  ]
}

let legalWnd = bgShaded.__merge({
  key = WND_UID
  size = FLEX
  onAttach = @() sendUiBqEvent("legal_accept_wnd", { id = "open" })
  onClick = EMPTY_ACTION
  children = @() modalWndBg.__merge({
    flow = FLOW_VERTICAL
    size = const [ wndWidthDefault, wndHeight ]
    children = [
      modalWndHeader(loc("terms_wnd/header"), { minWidth = SIZE_TO_CONTENT, padding = [ 0, buttonsHGap ] })
      wndContent
    ]
  })
  animations = wndSwitchAnim
})

if (isOpenedLegalWnd.get())
  addModalWindow(legalWnd)
isOpenedLegalWnd.subscribe(@(v) v ? addModalWindow(legalWnd) : removeModalWindow(WND_UID))
