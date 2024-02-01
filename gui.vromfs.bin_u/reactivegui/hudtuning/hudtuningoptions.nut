from "%globalsDarg/darg_library.nut" import *
let { isCurPresetChanged, transformInProgress, closeTuning, saveCurrentTransform, tuningTransform,
  history, curHistoryIdx, tuningUnitType
} = require("hudTuningState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { tuningBtn, tuningBtnWithActivity, tuningBtnImg,
  btnBgColorPositive, btnBgColorNegative, btnBgColorDisabled, btnBgColorDefault,
  btnImgColor, btnImgColorDisabled
} = require("tuningBtn.nut")
let chooseTuningUnitTypeWnd = require("chooseTuningUnitTypeWnd.nut")

let gap = hdpx(30)

let isOpen = mkWatched(persist, "isOpen", true)

function askSaveAndClose() {
  if (!isCurPresetChanged.value) {
    closeTuning()
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = closeTuning }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        cb = function() {
          saveCurrentTransform()
          closeTuning()
        }
      }
    ]
  })
}

let toggleBtn = @() {
  watch = isOpen
  hplace = ALIGN_LEFT
  pos = [sw(37), 0]
  children = tuningBtn("ui/gameuiskin#hud_tank_arrow_segment.svg",
    @() isOpen(!isOpen.value),
    isOpen.value ? "hudTuning/toggle/desc/hide" : "hudTuning/toggle/desc/show",
    {
      color = btnBgColorDefault
      transform = isOpen.value ? {} : { rotate = 180 }
      transitions = [{ prop = AnimProp.rotate, duration = 0.2, easing = InOutQuad }]
    })
}

let exitBtn = @() {
  watch = isCurPresetChanged
  children = tuningBtn("ui/gameuiskin#icon_exit.svg",
    askSaveAndClose,
    "hudTuning/exit/desc",
    {
      color = isCurPresetChanged.value ? btnBgColorNegative : btnBgColorPositive
    })
}

let saveBtn = tuningBtnWithActivity(isCurPresetChanged, "ui/gameuiskin#icon_save.svg",
  saveCurrentTransform,"hudTuning/save/desc")

let resetBtn = @() {
  watch = tuningTransform
  children = (tuningTransform.value?.len() ?? 0) == 0 ? null
    : tuningBtn("ui/gameuiskin#icon_reset_to_default.svg",
        @() tuningTransform({}),"hudTuning/reset/desc",
        { color = btnBgColorNegative })
}

function historyBack() {
  if ((curHistoryIdx.value ?? 0) != 0 && history.value.len() != 0)
    tuningTransform(history.value[min(curHistoryIdx.value - 1, history.value.len() - 1)])
}

function historyFwd() {
  if (curHistoryIdx.value != null && curHistoryIdx.value < history.value.len() - 1)
    tuningTransform(history.value[curHistoryIdx.value + 1])
}

let historyBackBtn = tuningBtnWithActivity(Computed(@() (curHistoryIdx.value ?? 0) > 0),
  "ui/gameuiskin#icon_cancel.svg",
  historyBack, "hudTuning/back/desc")

function historyFwdBtn() {
  let isAvailable = curHistoryIdx.value != null && curHistoryIdx.value < history.value.len() - 1
  return {
    watch = [curHistoryIdx, history]
    children = tuningBtn(
      tuningBtnImg("ui/gameuiskin#icon_cancel.svg",
        { flipX = true, color = isAvailable ? btnImgColor : btnImgColorDisabled }),
      historyFwd,"hudTuning/fwd/desc",
      {
        color = isAvailable ? btnBgColorDefault : btnBgColorDisabled
      })
  }
}

let changeUnitTypeBtn = tuningBtn("ui/gameuiskin#campaign.svg", chooseTuningUnitTypeWnd,
  "hudTuning/changeHudType/desc")

let curUnitTypeInfo = @() {
  watch = tuningUnitType
  rendObj = ROBJ_TEXT
  text = loc($"mainmenu/type_{tuningUnitType.value}")
  color = 0xC0C0C0C0
}.__update(fontSmall)

let content = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  children = [
    exitBtn
    changeUnitTypeBtn
    saveBtn
    historyBackBtn
    historyFwdBtn
    resetBtn
    { size = flex() }
    curUnitTypeInfo
  ]
}

let hudTuningOptions = @() {
  watch = transformInProgress
  size = [flex(), SIZE_TO_CONTENT]
  transform = { translate = [0, transformInProgress.value == null ? 0 : hdpx(-500)] }
  transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
  children = [
    @() {
      watch = isOpen
      size = [flex(), SIZE_TO_CONTENT]
      padding = [saBordersRv[0], saBordersRv[1], gap, saBordersRv[1]]
      rendObj = ROBJ_SOLID
      color = 0xC0000000
      children = content
      transform = { translate = [0, isOpen.value ? 0 : hdpx(-500)] }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    }
    toggleBtn
  ]
}

return hudTuningOptions