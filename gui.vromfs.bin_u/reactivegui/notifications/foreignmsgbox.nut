from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { openMsgBox, closeMsgBox, defaultBtnsCfg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")

let persistMsgBoxes = hardPersistWatched("persistMsgBoxes", [])

let function removeMsg(msg) {
  let idx = persistMsgBoxes.value.indexof(msg)
  if (idx != null)
    persistMsgBoxes.mutate(@(v) v.remove(idx))
}

let getButtons = @(msg)
  (msg?.buttons ?? defaultBtnsCfg).map(@(btn) btn.__merge({
      function cb() {
        let { eventId = null, context = {} } = btn
        removeMsg(msg)
        if (eventId != null)
          send($"fMsgBox.onClick.{eventId}", context)
      }
    }))

let ctors = {
  errorMsg = @(msg) msgBoxError(msg.__merge({ buttons = getButtons(msg) }), KWARG_NON_STRICT)

  function withWndClose(msg) {
    let { text, title = null } = msg
    let uid = msg?.uid ?? $"msgbox_{text}"
    openMsgBox(
      msg.__merge({
        uid
        title = msgBoxHeaderWithClose(title,
          function() {
            removeMsg(msg)
            closeMsgBox(uid)
          })
        buttons = getButtons(msg)
      }),
      KWARG_NON_STRICT)
  }
}

let function open(msg) {
  let { isPersist = false, viewType = "", canShowOverHud = false } = msg
  let canShowNow = canShowOverHud || !isHudAttached.value
  if (isPersist || !canShowNow)
    persistMsgBoxes.mutate(@(v) v.append(msg))
  if (!canShowNow)
    return

  if (viewType in ctors)
    ctors[viewType](msg)
  else
    openMsgBox(msg.__merge({ buttons = getButtons(msg) }), KWARG_NON_STRICT)
}

let function close(msg) {
  removeMsg(msg)
  closeMsgBox(msg.uid)
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
subscribe("fMsgBox.close", close)
