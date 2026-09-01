from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/decorators/decoratorState.nut" import myNameWithFrame


let changeNameScene = {
  size = FLEX
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP
  gap = hdpx(80)
  children = [
    @() {
      watch = myNameWithFrame
      rendObj = ROBJ_TEXT
      text = myNameWithFrame.get() ?? ""
    }.__update(fontMedium)
    {
      size = FLEX_H
      behavior = Behaviors.TextArea
      rendObj = ROBJ_TEXTAREA
      halign = ALIGN_CENTER
      text = loc("mainmenu/questionChangeName")
    }.__update(fontMedium)
    textButtonCommon(utf8ToUpper(loc("mainmenu/btnChangeName")), @() eventbus_send("changeName", {}))
  ]
}

return changeNameScene