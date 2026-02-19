from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/notifications/consentTcf/consentTcfState.nut" import isOpenedConsentTcfWnd, isConsentInitializing,
  isVendorDataLoading, isLoadError, isOpenedPartners, isOpenedPartnersExt, isOpenedManage, showPurposeInfo,
  totalPartners, doSkipClose
from "%rGui/notifications/consentTcf/consentTcfComps.nut" import mkContent, mkStatusContent
import "%rGui/notifications/consentTcf/mkPageIntro.nut" as mkPageIntro
import "%rGui/notifications/consentTcf/mkPagePartners.nut" as mkPagePartners
import "%rGui/notifications/consentTcf/mkPageManage.nut" as mkPageManage
import "%rGui/notifications/consentTcf/mkPagePurpose.nut" as mkPagePurpose
import "%rGui/notifications/consentTcf/mkPagePartnersExt.nut" as mkPagePartnersExt

const key = "consentTcf"

let mkIntroStatus = @(text, onClose = null)
  mkContent(loc("consent_tcf/intro/header"), mkStatusContent(text), null, onClose)

let mkPageStatusWait = @() mkIntroStatus(loc("msgbox/please_wait"))
let mkPageStatusInitializing = @() mkIntroStatus(loc("wait/common/initializing"))
let mkPageStatusLoading = @() mkIntroStatus(loc("wait/common/loading"))
let mkPageStatusLoadError = @() mkIntroStatus("\n".concat(loc("failed_to_load_data"), loc("try_again_later")), doSkipClose)

let consentTcfWnd = bgShaded.__merge({
  key
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  animations = wndSwitchAnim
  onClick = @() null
  children = @() {
    watch = [isLoadError, isConsentInitializing, isVendorDataLoading, totalPartners, isOpenedPartners,
      showPurposeInfo, isOpenedPartnersExt, isOpenedManage]
    children = isLoadError.get() ? mkPageStatusLoadError()
      : isConsentInitializing.get() ? mkPageStatusInitializing()
      : isVendorDataLoading.get() ? mkPageStatusLoading()
      : totalPartners.get() == 0 ? mkPageStatusWait()
      : isOpenedPartners.get() ? mkPagePartners()
      : showPurposeInfo.get() != null ? mkPagePurpose()
      : isOpenedPartnersExt.get() ? mkPagePartnersExt()
      : isOpenedManage.get() ? mkPageManage()
      : mkPageIntro()
  }
})

if (isOpenedConsentTcfWnd.get())
  addModalWindow(consentTcfWnd)
isOpenedConsentTcfWnd.subscribe(@(v) v ? addModalWindow(consentTcfWnd) : removeModalWindow(key))