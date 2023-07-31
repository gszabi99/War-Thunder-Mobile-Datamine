from "%globalsDarg/darg_library.nut" import *
let { get_current_mission_name } = require("mission")
let { register_command } = require("console")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { textButtonPrimary, buttonStyles } = require("%rGui/components/textButton.nut")
let { firstBattleTutor, tutorialMissions } = require("%rGui/tutorial/tutorialMissions.nut")
let { tankMoveControlType } = require("%rGui/options/options/controlsOptions.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let controlsTypesButton = require("controlsTypesButton.nut")
let controlsTypesAnims = require("controlsTypesAnims.nut")
let { defaultValue, needRecommend } = require("movementControlsTests.nut")

let curControlType = tankMoveControlType.value
let ctrlTypesList = tankMoveControlType.list
let ctrlTypeToString = tankMoveControlType.valToString

let btnW = evenPx(380)
let btnH = hdpx(510)
let btnGap = hdpxi(30)
let contentWidth = ((btnW + btnGap) * ctrlTypesList.len()) - btnGap
let bgGradWidth = contentWidth + hdpx(400)

let selectedValue = Watched("")
let updateSelectedVal = @() selectedValue(needRecommend.value ? defaultValue.value : "")
defaultValue.subscribe(@(_) updateSelectedVal())
needRecommend.subscribe(@(_) updateSelectedVal())
updateSelectedVal()

let haveApplied = mkWatched(persist, "haveApplied", false)
let needShowForDebug = mkWatched(persist, "needShowForDebug", false)

let function close() {
  curControlType(selectedValue.value)
  sendUiBqEvent("choose_tank_control_in_tutorial", { id = curControlType.value })
  haveApplied(true)
  needShowForDebug(false)
}

let needChooseMoveControlsType = Computed(@() !haveApplied.value && (
  (isInBattle.value && curCampaign.value == "tanks"
      && get_current_mission_name() == (tutorialMissions?[firstBattleTutor.value] ?? ""))
    || needShowForDebug.value
))

let function reorderList(list, valToPlaceFirst) {
  let idx = list.indexof(valToPlaceFirst) ?? 0
  return [].extend(list.slice(idx, list.len()), list.slice(0, idx))
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

let optButtonsRow = @() {
  watch = [defaultValue, needRecommend]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = btnGap
  children = reorderList(ctrlTypesList, defaultValue.value).map(@(id) controlsTypesButton(
    mkBtnContent(id, needRecommend.value && defaultValue.value == id),
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

let chooseMoveControlsTypeWnd = bgShaded.__merge({
  key = {}
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  stopMouse = true
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
            watch = [selectedValue, defaultValue, needRecommend]
            minHeight = hdpx(132)
            text = getDescText(selectedValue.value, needRecommend.value && defaultValue.value == selectedValue.value)
          })
          @() {
            watch = selectedValue
            padding = [hdpx(10), 0]
            children = selectedValue.value == ""
              ? { size = [0, buttonStyles.defButtonHeight] }
              : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), close, { hotkeys = ["^J:X | Enter"] })
          }
        ]
      }
    ]
  }
})

register_command(function() {
  if (!isInBattle.value)
    console_print("This command works only in the battle") // warning disable: -forbidden-function
  haveApplied(false)
  needShowForDebug(true)
}, "ui.chooseMovementControls")

return {
  needChooseMoveControlsType
  chooseMoveControlsTypeWnd
}
