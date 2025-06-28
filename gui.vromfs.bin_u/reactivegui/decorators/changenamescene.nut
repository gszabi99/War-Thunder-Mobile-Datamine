from "%globalsDarg/darg_library.nut" import *
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { eventbus_send } = require("eventbus")

let { myNameWithFrame } = require("%rGui/decorators/decoratorState.nut")

let changeNameScene = {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP
  gap = hdpx(80)
  children = [
    @() {
      watch = myNameWithFrame
      rendObj = ROBJ_TEXT
      text = myNameWithFrame.value ?? ""
    }.__update(fontMedium)
    {
      size = FLEX_H
      behavior = Behaviors.TextArea
      rendObj = ROBJ_TEXTAREA
      halign = ALIGN_CENTER
      text = loc("mainmenu/questionChangeName")
    }.__update(fontMedium)
    textButtonPrimary(loc("mainmenu/btnChangeName"), @() eventbus_send("changeName", {}))
  ]
}

return changeNameScene