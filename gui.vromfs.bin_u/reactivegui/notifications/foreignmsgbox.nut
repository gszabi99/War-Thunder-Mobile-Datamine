from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { openMsgBox, closeMsgBox, defaultBtnsCfg } = require("%rGui/components/msgBox.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")

let persistMsgBoxes = hardPersistWatched("persistMsgBoxes", [])

let ctors = {
  errorMsg = msgBoxError
}

let function open(msg) {
  let { isPersist = false, buttons = defaultBtnsCfg, viewType = "", canShowOverHud = false } = msg
  let canShowNow = canShowOverHud || !isHudAttached.value
  if (isPersist || !canShowNow)
    persistMsgBoxes.mutate(@(v) v.append(msg))
  if (!canShowNow)
    return

  let function onClose() {
    let idx = persistMsgBoxes.value.indexof(msg)
    if (idx != null)
      persistMsgBoxes.mutate(@(v) v.remove(idx))
  }

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
  if (persistMsgBoxes.value.len() == 0)
    return
  let msgs = persistMsgBoxes.value
  persistMsgBoxes([])
  msgs.each(open)
}
restorePersist()

hasModalWindows.subscribe(function(v) {
  if (!v)
    deferOnce(function() {
      if (!hasModalWindows.value)
        restorePersist()
    })
})
isHudAttached.subscribe(function(v) {
  if (!v)
    deferOnce(function() {
      if (!isHudAttached.value)
        restorePersist()
    })
})

subscribe("fMsgBox.open", open)
subscribe("fMsgBox.close", @(msg) closeMsgBox(msg.uid))
