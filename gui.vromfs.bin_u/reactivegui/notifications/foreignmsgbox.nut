from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { openMsgBox, closeMsgBox, defaultBtnsCfg } = require("%rGui/components/msgBox.nut")
let { modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let msgBoxError = require("%rGui/components/msgBoxError.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let openMsgAccStatus = require("%rGui/components/openMsgAccStatus.nut")

let persistMsgBoxes = hardPersistWatched("persistMsgBoxes", [])

function removeMsg(msg) {
  let idx = persistMsgBoxes.get().indexof(msg)
  if (idx != null)
    persistMsgBoxes.mutate(@(v) v.remove(idx))
}

let getButtons = @(msg)
  (msg?.buttons ?? defaultBtnsCfg).map(@(btn) btn.__merge({
      function cb() {
        let { eventId = null, context = {} } = btn
        removeMsg(msg)
        if (eventId != null)
          eventbus_send($"fMsgBox.onClick.{eventId}", context)
      }
    }))

let ctors = {
  errorMsg = @(msg) msgBoxError(msg.__merge({ buttons = getButtons(msg) }), KWARG_NON_STRICT)
  accStatusMsg = @(msg) openMsgAccStatus(msg.__merge({ buttons = getButtons(msg) }))

  function withWndClose(msg) {
    let { text, title = null } = msg
    let uid = msg?.uid ?? $"msgbox_{text}"
    openMsgBox(
      msg.__merge({
        uid
        title = modalWndHeaderWithClose(title,
          function() {
            removeMsg(msg)
            closeMsgBox(uid)
          })
        buttons = getButtons(msg)
      }),
      KWARG_NON_STRICT)
  }
}

function registerFMsgCreator(id, ctor) {
  if (id in ctors)
    logerr($"Duplicate fMsg ctro id: {id}")
  ctors[id] <- ctor
}

function open(msg) {
  let { isPersist = false, viewType = "", canShowOverHud = false } = msg
  let canShowNow = canShowOverHud || !isHudAttached.get()
  if (isPersist || !canShowNow)
    persistMsgBoxes.mutate(@(v) v.append(msg))
  if (!canShowNow)
    return

  if (viewType in ctors)
    ctors[viewType](msg)
  else
    openMsgBox(msg.__merge({ buttons = getButtons(msg) }), KWARG_NON_STRICT)
}

function close(msg) {
  removeMsg(msg)
  closeMsgBox(msg.uid)
}

function restorePersist() {
  if (persistMsgBoxes.get().len() == 0)
    return
  let msgs = persistMsgBoxes.get()
  persistMsgBoxes.set([])
  msgs.each(open)
}
restorePersist()

hasModalWindows.subscribe(function(v) {
  if (!v)
    deferOnce(function() {
      if (!hasModalWindows.get())
        restorePersist()
    })
})
isHudAttached.subscribe(function(v) {
  if (!v)
    deferOnce(function() {
      if (!isHudAttached.get())
        restorePersist()
    })
})

eventbus_subscribe("fMsgBox.open", open)
eventbus_subscribe("fMsgBox.close", close)

return {
  getFMsgButtons = getButtons
  registerFMsgCreator
}