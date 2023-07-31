from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { openMsgBox, closeMsgBox, defaultBtnsCfg } = require("%rGui/components/msgBox.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")

let persistMsgBoxes = hardPersistWatched("persistMsgBoxes", [])

let ctors = {
  errorMsg = msgBoxError
}

let function open(msg) {
  let { isPersist = false, buttons = defaultBtnsCfg, viewType = "" } = msg

  let function onClose() {
    let idx = persistMsgBoxes.value.indexof(msg)
    if (idx != null)
      persistMsgBoxes.mutate(@(v) v.remove(idx))
  }
  if (isPersist)
    persistMsgBoxes.mutate(@(v) v.append(msg))

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

let function restorePersist() {
  let msgs = persistMsgBoxes.value
  persistMsgBoxes([])
  msgs.each(open)
}
restorePersist()

hasModalWindows.subscribe(function(v) {
  if (!v)
    defer(function() {
      if (!hasModalWindows.value && persistMsgBoxes.value.len() > 0)
        restorePersist()
    })
})

subscribe("fMsgBox.open", open)
subscribe("fMsgBox.close", @(msg) closeMsgBox(msg.uid))
