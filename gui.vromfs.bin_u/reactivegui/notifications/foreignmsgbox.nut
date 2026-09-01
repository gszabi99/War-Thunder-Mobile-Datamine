from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/hudState.nut" import isHudAttached
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/components/modalWnd.nut" import modalWndHeaderWithClose
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox, defaultBtnsCfg
import "%rGui/components/msgBoxError.nut" as msgBoxError
import "%rGui/components/openMsgAccStatus.nut" as openMsgAccStatus


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