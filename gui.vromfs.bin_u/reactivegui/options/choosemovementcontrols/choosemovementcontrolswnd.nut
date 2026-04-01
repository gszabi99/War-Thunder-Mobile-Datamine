from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { reorderList, applyCtrlType, isChooseMovementControlsOpened, isChooseWalkerMovementControlsOpened, getCurCtrlTypeW,
  closeChooseMovementControls } = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")
let { textButtonPrimary, buttonStyles } = require("%rGui/components/textButton.nut")
let { groundMoveCtrlTypesList, ctrlTypeToString } = require("%rGui/options/chooseMovementControls/groundMoveControlType.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let controlsTypesButton = require("%rGui/options/chooseMovementControls/controlsTypesButton.nut")
let controlsTypesAnimsCtors = require("%rGui/options/chooseMovementControls/controlsTypesAnims.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let isWndOpened = Computed(@() isChooseMovementControlsOpened.get() || isChooseWalkerMovementControlsOpened.get())
let defaultValue = "stick_static"
let btnW = evenPx(380)
let btnH = hdpx(510)
let btnGap = hdpxi(30)
let contentWidth = ((btnW + btnGap) * groundMoveCtrlTypesList.len()) - btnGap

let selectedValue = Watched("")

let txtBase = {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = 0xFFFFFFFF
}.__merge(fontTiny)

let txt = @(ovr) txtBase.__merge(ovr)

let txtArea = @(ovr) txtBase.__merge({
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}, ovr)


let mkBtnContent = @(id, isRecommended) {
  size = [btnW, btnH]
  padding = const [hdpx(10), 0, 0, 0]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    controlsTypesAnimsCtors?[id]()
    {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        txt({ text = ctrlTypeToString(id) }.__update(fontSmall))
        txt({ text = isRecommended ? loc("option_recommended") : "" })
      ]
    }
  ]
}

let mkOptButtonsRow = @() {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = btnGap
  children = reorderList(groundMoveCtrlTypesList, defaultValue).map(@(id) controlsTypesButton(
    mkBtnContent(id, defaultValue == id),
    Computed(@() id == selectedValue.get()),
    @() selectedValue.set(id)))
}

let getDescText = @(id, isRecommended) id == "" ? "" : "".concat(
  ctrlTypeToString(id),
  isRecommended
    ? loc("ui/parentheses/space" { text = loc("option_recommended") })
    : "",
  " ", loc("ui/mdash"), " ",
  loc($"options/{id}/info"),
  "\n\n",
  loc("option_can_be_changed_later")
)

let mkChooseMoveControlsWnd = bgShaded.__merge({
  key = {}
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  onAttach = @() selectedValue.set(getCurCtrlTypeW()?.get() ?? defaultValue)
  children = {
    size = FLEX_H
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      modalWndBg.__merge({
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        children = [
          modalWndHeaderWithClose(loc("options/choose_movement_controls"), closeChooseMovementControls)
          {
            size = [contentWidth, SIZE_TO_CONTENT]
            margin = [btnGap, btnGap*3]
            gap = btnGap
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              mkOptButtonsRow()
              @() txtArea({
                watch = [selectedValue]
                minHeight = hdpx(132)
                text = getDescText(selectedValue.get(), defaultValue == selectedValue.get())
              })
              @() {
                watch = selectedValue
                padding = const [hdpx(10), 0]
                children = selectedValue.get() == ""
                  ? { size = [0, buttonStyles.defButtonHeight] }
                  : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), @() applyCtrlType(selectedValue.get()), { hotkeys = ["^J:X | Enter"] })
              }
            ]
          }
        ]
      })
    ]
  }
  animations = wndSwitchAnim
})

registerScene("chooseMovementControls", mkChooseMoveControlsWnd, closeChooseMovementControls, isWndOpened)
