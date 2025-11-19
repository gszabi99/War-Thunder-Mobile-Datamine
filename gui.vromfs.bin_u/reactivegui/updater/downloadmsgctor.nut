from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/bqClient.nut" import sendLoadingAddonsBqEvent
from "%appGlobals/updater/addons.nut" import mbToString, toMB
from "%rGui/notifications/foreignMsgBox.nut" import getFMsgButtons, registerFMsgCreator
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText, closeMsgBox
from "%rGui/updater/downloadSize.nut" import mkDlSizeComp


registerFMsgCreator("downloadMsg",
  function(msg) {
    let { addons = [], units = [], bqAction = "", bqData = {}, text, uid = "downloadMsg", title = null } = msg
    let totalSize = mkDlSizeComp(addons, units, "downloadMsg: ")

    local isBqActionSend = false
    function sendToBqOnce() {
      if (isBqActionSend)
        return
      isBqActionSend = true
      let sizeMb = totalSize.get() < 0 ? -1 : toMB(totalSize.get())
      if (totalSize.get() > 0)
        log($"[ADDONS] show download size: {sizeMb}MB (addons {addons.len()}, units {units.len()})")
      sendLoadingAddonsBqEvent(bqAction, addons, units, bqData.__merge({ sizeMb }))
    }

    if (totalSize.get() > 0)
      sendToBqOnce()
    else
      totalSize.subscribe(@(v) v > 0 ? sendToBqOnce() : null)

    let content = @() msgBoxText(
      text.subst({ size = mbToString(toMB(totalSize.get())) }),
      {
        watch = totalSize
        key = totalSize
        onDetach = sendToBqOnce
      })

    totalSize.subscribe(@(v) v == 0 ? closeMsgBox(uid) : null)

    openMsgBox({
      uid
      title
      text = content
      buttons = getFMsgButtons(msg)
    })
  })
