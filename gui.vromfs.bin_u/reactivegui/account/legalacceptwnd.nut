from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { isOpenedLegalWnd } = require("%appGlobals/loginState.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { urlText } = require("%rGui/components/urlText.nut")
let { buttonsHGap, mkCustomButton, buttonStyles } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { legalToApprove } = require("%appGlobals/legal.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")

const WND_UID = "legalAcceptWnd"

let urlColor = 0xFF17C0FC
let wndWidthDefault = hdpx(1300)
let wndHeight = hdpx(650)

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
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    wrap(
      mkTextRow(
        loc("legals/byClickingBtnYouAcceptAllLegals")
        mkTextarea
        {
          ["{btnText}"] = mkTextarea(utf8ToUpper(loc("terms_wnd/accept/noNewLine"))), 
          ["{termsOfServiceUrl}"] = legalInfoUrl(legalToApprove["termsofservice"]), 
          ["{gameRulesUrl}"] = legalInfoUrl(legalToApprove["gamerules"]), 
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
    sendUiBqEvent("legal_accept_wnd", { id = "accept" })
    eventbus_send("acceptAllLegals", {})
  },
  buttonStyles.PRIMARY.__merge({ hotkeys = ["^J:X"] }))

let wndContent = {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap =  { size = flex() }
  padding = buttonsHGap
  children = [
    legalList
    acceptButton
  ]
}

let legalWnd = bgShaded.__merge({
  key = WND_UID
  size = flex()
  onAttach = @() sendUiBqEvent("legal_accept_wnd", { id = "open" })
  onClick = EMPTY_ACTION
  children = @() modalWndBg.__merge({
    flow = FLOW_VERTICAL
    size = [ wndWidthDefault, wndHeight ]
    children = [
      modalWndHeader(loc("terms_wnd/header"), { minWidth = SIZE_TO_CONTENT, padding = [ 0, buttonsHGap ] })
      wndContent
    ]
  })
  animations = wndSwitchAnim
})

if (isOpenedLegalWnd.value)
  addModalWindow(legalWnd)
isOpenedLegalWnd.subscribe(@(v) v ? addModalWindow(legalWnd) : removeModalWindow(WND_UID))
