from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { onControlsApply } = require("chooseMovementControlsState.nut")
let { textButtonPrimary, buttonStyles } = require("%rGui/components/textButton.nut")
let { tankMoveCtrlTypesList, currentTankMoveCtrlType, ctrlTypeToString
} = require("tankMoveControlType.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let controlsTypesButton = require("controlsTypesButton.nut")
let controlsTypesAnims = require("controlsTypesAnims.nut")

let defaultValue = "stick_static"
let btnW = evenPx(380)
let btnH = hdpx(510)
let btnGap = hdpxi(30)
let contentWidth = ((btnW + btnGap) * tankMoveCtrlTypesList.len()) - btnGap
let bgGradWidth = contentWidth + hdpx(400)

let selectedValue = Watched("")

let function apply() {
  currentTankMoveCtrlType(selectedValue.value)
  onControlsApply()
}

let orderByFirstVal = {
  stick         = [ "stick", "stick_static", "arrows" ]
  stick_static  = [ "stick_static", "stick", "arrows" ]
  arrows        = [ "arrows", "stick", "stick_static" ]
}

let function reorderList(list, valToPlaceFirst) {
  return (orderByFirstVal?[valToPlaceFirst] ?? orderByFirstVal.stick)
    .filter(@(v) list.contains(v))
}

let txtBase = {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = 0xFFFFFFFF
}.__merge(fontTiny)

let txt = @(ovr) txtBase.__merge(ovr)

let txtArea = @(ovr) txtBase.__merge({
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}, ovr)

let doubleSideGradBG = {
  size = [bgGradWidth, flex()]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, 0.45 * bgGradWidth]
  color = 0xA0000000
}
let doubleSideGradLine = doubleSideGradBG.__merge({
  size = [bgGradWidth, hdpx(4)]
  color = 0xFFACACAC
})
let bgGradientComp = {
  size = flex()
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    doubleSideGradLine
    doubleSideGradBG
    doubleSideGradLine
  ]
}

let mkBtnContent = @(id, isRecommended) {
  size = [btnW, btnH]
  padding = [hdpx(10), 0, 0, 0]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    controlsTypesAnims?[id]
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

let optButtonsRow = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = btnGap
  children = reorderList(tankMoveCtrlTypesList, defaultValue).map(@(id) controlsTypesButton(
    mkBtnContent(id, defaultValue == id),
    Computed(@() id == selectedValue.value),
    @() selectedValue(id)))
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

let onAttach = @() selectedValue(currentTankMoveCtrlType.value)

let chooseMoveControlsScene = bgShaded.__merge({
  key = {}
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  stopMouse = true
  onAttach
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      bgGradientComp
      {
        size = [contentWidth, SIZE_TO_CONTENT]
        padding = [btnGap, 0]
        gap = btnGap
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          txt({ text = loc("options/choose_movement_controls")}.__update(fontMedium))
          optButtonsRow
          @() txtArea({
            watch = [selectedValue]
            minHeight = hdpx(132)
            text = getDescText(selectedValue.value, defaultValue == selectedValue.value)
          })
          @() {
            watch = selectedValue
            padding = [hdpx(10), 0]
            children = selectedValue.value == ""
              ? { size = [0, buttonStyles.defButtonHeight] }
              : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), apply, { hotkeys = ["^J:X | Enter"] })
          }
        ]
      }
    ]
  }
})

return chooseMoveControlsScene
