from "%globalsDarg/darg_library.nut" import *
from "%rGui/controlsMenu/gpActBtn.nut" import EMPTY_ACTION
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/notifications/consentFirebase/consentState.nut" import isOpenedConsentFirebaseWnd, isOpenedMain, isOpenedPartners, isOpenedManage, showOptInfo
import "%rGui/notifications/consentFirebase/mkPageMain.nut" as mkPageMain
import "%rGui/notifications/consentFirebase/mkPageManage.nut" as mkPageManage
import "%rGui/notifications/consentFirebase/mkPageOptInfo.nut" as mkPageOptInfo
import "%rGui/notifications/consentFirebase/mkPagePartners.nut" as mkPagePartners

const key = "consentFirebase"

let consentFirebaseWnd = bgShaded.__merge({
  key
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  animations = wndSwitchAnim
  onClick = EMPTY_ACTION
  children = @() {
    watch = [isOpenedPartners, showOptInfo, isOpenedManage, isOpenedMain]
    children = isOpenedPartners.get() ? mkPagePartners()
      : showOptInfo.get() != null ? mkPageOptInfo()
      : isOpenedManage.get() ? mkPageManage()
      : isOpenedMain.get() ? mkPageMain()
      : null
  }
})

if (isOpenedConsentFirebaseWnd.get())
  addModalWindow(consentFirebaseWnd)
isOpenedConsentFirebaseWnd.subscribe(@(v) v ? addModalWindow(consentFirebaseWnd) : removeModalWindow(key))