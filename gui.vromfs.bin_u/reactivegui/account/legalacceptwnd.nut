from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { legalListForApprove } = require("%appGlobals/loginState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { msgBoxHeader, msgBoxBg } = require("%rGui/components/msgBox.nut")
let urlText = require("%rGui/components/urlText.nut")
let { buttonsHGap, mkCustomButton, buttonStyles } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { legalSorted } = require("%appGlobals/legal.nut")

const WND_UID = "legalAcceptWnd"
let isOpened = keepref(Computed(@() legalListForApprove.value.findvalue(@(v) v) != null))

let urlColor = 0xFF17C0FC
let wndWidthDefault = hdpx(1100)
let wndHeight = hdpx(650)

let urlStyle = { ovr = { color = urlColor }, childOvr = { color = urlColor } }
let function legalInfo(legalCfg) {
  let { url, locId } = legalCfg
  return urlText(loc(locId), url, urlStyle)
}

let legalList = @() {
  size = [flex(), SIZE_TO_CONTENT]
  gap = hdpx(50)
  flow = FLOW_VERTICAL
  children = legalSorted
    .filter(@(l) legalListForApprove.value?[l.id] ?? false)
    .map(legalInfo)
}

let acceptText = {
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  halign = ALIGN_CENTER
  text = utf8ToUpper(loc("terms_wnd/accept"))
}.__update(fontTinyAccentedShaded)

let acceptButton = mkCustomButton(
  acceptText,
  @() send("acceptAllLegals", {}),
  buttonStyles.PRIMARY
)

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

if (isOpened.value)
  addModalWindow(legalWnd)
isOpened.subscribe(@(v) v ? addModalWindow(legalWnd) : removeModalWindow(WND_UID))
