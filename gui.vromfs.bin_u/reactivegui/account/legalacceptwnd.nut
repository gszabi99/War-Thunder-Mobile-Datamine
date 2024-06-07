from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { isOpenedLegalWnd } = require("%appGlobals/loginState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { msgBoxHeader, msgBoxBg } = require("%rGui/components/msgBox.nut")
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
  text = replaceExtremeSpacesToNbsp(text) // FIXME: nbsp is workaround because 'preformatted = FMT_KEEP_SPACES' does not keep extreme spaces
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
          ["{btnText}"] = mkTextarea(utf8ToUpper(loc("terms_wnd/accept/noNewLine"))), //warning disable: -forgot-subst
          ["{termsOfServiceUrl}"] = legalInfoUrl(legalToApprove["termsofservice"]), //warning disable: -forgot-subst
          ["{gameRulesUrl}"] = legalInfoUrl(legalToApprove["gamerules"]), //warning disable: -forgot-subst
          ["{privacyPolicyUrl}"] = legalInfoUrl(legalToApprove["privacypolicy"]) //warning disable: -forgot-subst
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
  @() eventbus_send("acceptAllLegals", {}),
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
  onClick = EMPTY_ACTION
  children = @() msgBoxBg.__merge({
    flow = FLOW_VERTICAL
    size = [ wndWidthDefault, wndHeight ]
    children = [
      msgBoxHeader(loc("terms_wnd/header"), { minWidth = SIZE_TO_CONTENT, padding = [ 0, buttonsHGap ] })
      wndContent
    ]
  })
  animations = wndSwitchAnim
})

if (isOpenedLegalWnd.value)
  addModalWindow(legalWnd)
isOpenedLegalWnd.subscribe(@(v) v ? addModalWindow(legalWnd) : removeModalWindow(WND_UID))
