from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { openMsgBox, closeMsgBox, defaultBtnsCfg } = require("%rGui/components/msgBox.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")

let persistMsgBoxes = persist("persistMsgBoxes", @() [])

let ctors = {
  errorMsg = msgBoxError
}

let function open(msg) {
  let { isPersist = false, buttons = defaultBtnsCfg, viewType = "" } = msg

  let function onClose() {
    let idx = persistMsgBoxes.indexof(msg)
    if (idx != null)
      persistMsgBoxes.remove(idx)
  }
  if (isPersist)
    persistMsgBoxes.append(msg)

  let ctor = ctors?[viewType] ?? openMsgBox
  ctor(msg.__merge({
    buttons = buttons.map(@(btn) btn.__merge({
      function cb() {
        let { eventId = null, context = {} } = btn
        onClose()
        if (eventId != null)
          send($"fMsgBox.onClick.{eventId}", context)
      }
    }))
  }), KWARG_NON_STRICT)
}

let msgs = clone persistMsgBoxes
persistMsgBoxes.clear()
msgs.each(open)

subscribe("fMsgBox.open", open)
subscribe("fMsgBox.close", @(msg) closeMsgBox(msg.uid))