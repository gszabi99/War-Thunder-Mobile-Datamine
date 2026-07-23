from "%globalsDarg/darg_library.nut" import *
from "app" import get_base_game_version_str
from "eventbus" import eventbus_send
from "android.platform" import isDownloadedFromGooglePlay
from "android.billing.googleplay" import getCountryCode
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/version_compare.nut" import check_version
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/permissions.nut" import external_gp_build_released
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator
from "%appGlobals/clientState/clientState.nut" import isInMenu, isOutOfBattleAndResults
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, get_migrate_acc_info, migAccInfoInProgress
from "%rGui/navState.nut" import registerScene
from "%rGui/style/stdColors.nut" import locColorTable
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader, wndHeaderHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/textButton.nut" import textButtonBattle, textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/account/linkEmailForGaijinLogin.nut" import canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin
from "%rGui/account/emailRegistrationState.nut" import canUpgradeGuestAccountToGaijinID, openGuestEmailRegistration

const INCOMPATIBLE_FROM_VERSION = "1.26.0.0"

local info = null

let wndW = min(hdpx(1782), saSize[0])
let wndH = min(hdpx(972),  saSize[1])
let wndPadW = hdpx(90)
let wndPadH = hdpx(50)
let contentW = wndW - (2 * wndPadW)
let parGap = hdpx(40)
let advGap = hdpx(40)

let isSuggested = hardPersistWatched("suggestMigrateAcc.isSuggested", false)
let shouldsuggestMigrateAcc = keepref(Computed(@() external_gp_build_released.get() && !isExternalOperator()
  && isDownloadedFromGooglePlay() && ["RU","BY"].contains(getCountryCode())))
let needSuggestMigrateAcc = keepref(Computed(@() shouldsuggestMigrateAcc.get() && !isSuggested.get()
  && isInMenu.get() && isOutOfBattleAndResults.get()))

let ver = get_base_game_version_str()
let canClose = ver == "" || check_version($"<{INCOMPATIBLE_FROM_VERSION}", ver)

registerHandler("onMigAccInfoReceived", function(res) { info = res })
let requestInfo = @() get_migrate_acc_info("onMigAccInfoReceived")
needSuggestMigrateAcc.subscribe(@(v) (!v || info != null) ? null : requestInfo())
if (needSuggestMigrateAcc.get())
  requestInfo()

let close = @() canClose ? isSuggested.set(true) : null

function openMigrationWebpageAndMaybeClose() {
  if (info?.MIGRATE_ACCOUNT_INFO_URL != null)
    eventbus_send("openUrl", { baseUrl = info.MIGRATE_ACCOUNT_INFO_URL })
  close()
}

function openRegionalAppPageInGooglePlay() {
  if (info?.REGIONAL_APP_GOOGLEPLAY_URL != null)
    eventbus_send("openUrl", { baseUrl = info.REGIONAL_APP_GOOGLEPLAY_URL })
}

let mkTextarea = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontTiny, ovr)

let mkIcon = @(imgPath, size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{imgPath}:{size}:{size}:P")
  keepAspect = true
}

let mkBlockSize = @(cols, totalW, horGap) [(totalW - (horGap * (cols - 1))) / cols, SIZE_TO_CONTENT]

function mkParComps() {
  let parTexts = [ info?.par1 ?? "", info?.par2 ?? "", info?.par3 ?? "" ]
  let size = mkBlockSize(parTexts.len(), contentW, parGap)
  return parTexts.map(@(txt) mkTextarea(txt, { size, colorTable = locColorTable }))
}

function mkAdvComps() {
  let advTexts = [ info?.adv1 ?? "", info?.adv2 ?? "", info?.adv3 ?? "", info?.adv4 ?? "" ]
  let advIcons = [ info?.adv1ico, info?.adv2ico, info?.adv3ico, info?.adv4ico ]
  let size = mkBlockSize(advTexts.len(), contentW, advGap)
  return advTexts.map(@(txt, idx) {
    size
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = [
      advIcons?[idx] != null
        ? mkIcon(advIcons[idx], hdpx(50))
        : null
      mkTextarea(utf8ToUpper(txt), { size = FLEX_H, halign = ALIGN_CENTER }.__update(fontBoldVeryTinyAccented))
    ]
  })
}

let mkStatusText = @(text) mkTextarea(text, { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, halign = ALIGN_CENTER })

let loadingWnd = modalWndBg.__merge({
  size = [wndW, wndH]
  children = mkStatusText(loc("wait/common/loading"))
})

let errorWnd = modalWndBg.__merge({
  size = [wndW, wndH]
  children = [
    !canClose ? null
      : {
          size = [flex(), wndHeaderHeight]
          children = closeWndBtn(close, { hotkeys = [btnBEscUp] })
        }
    mkStatusText("\n".concat(loc("failed_to_load_data"), loc("try_again_later")))
  ]
})

let mkContentWnd = @() modalWndBg.__merge({
  size = [wndW, wndH]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), wndHeaderHeight]
      valign = ALIGN_CENTER
      children = [
        modalWndHeader(utf8ToUpper(info?.title ?? ""))
        !canClose ? null : closeWndBtn(close, { hotkeys = [btnBEscUp] })
      ]
    }
    {
      size = flex()
      padding = [wndPadH, wndPadW]
      flow = FLOW_VERTICAL
      children = [
        {
          size = flex()
          flow = FLOW_VERTICAL
          gap = hdpx(70)
          children = [
            mkTextarea(utf8ToUpper(info?.subtitle ?? ""),
              { size = [flex(), SIZE_TO_CONTENT], halign = ALIGN_CENTER }.__update(fontBoldSmall))
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = parGap
              children = mkParComps()
            }
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = advGap
              children = mkAdvComps()
            }
          ]
        }
        @() {
          watch = [canLinkEmailForGaijinLogin, canUpgradeGuestAccountToGaijinID]
          size = [flex(), SIZE_TO_CONTENT]
          vplace = ALIGN_BOTTOM
          flow = FLOW_HORIZONTAL
          children = [
            textButtonPrimary(utf8ToUpper(info?.btnApp ?? ""), openRegionalAppPageInGooglePlay)
            { size = [hdpx(50), flex()] }
            canLinkEmailForGaijinLogin.get()
                ? textButtonPrimary(utf8ToUpper(info?.btnGaijinId ?? ""), openLinkEmailForGaijinLogin)
              : canUpgradeGuestAccountToGaijinID.get()
                ? textButtonPrimary(utf8ToUpper(info?.btnGaijinId ?? ""), openGuestEmailRegistration)
              : null
            { size = FLEX }
            textButtonBattle(utf8ToUpper(info?.btnMigrate ?? ""), openMigrationWebpageAndMaybeClose)
          ]
        }
      ]
    }
  ]
})

let wndComp = @() {
  watch = migAccInfoInProgress
  children = (info == null || migAccInfoInProgress.get())
      ? loadingWnd
    : info?.error != null
      ? errorWnd
    : mkContentWnd()
}

let mkScene = @() bgShaded.__merge({
  key = {}
  size = FLEX
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = wndComp
})

let alwaysOnTop = true
let canClear = @() canClose
registerScene("suggestMigrateAcc", mkScene, close, needSuggestMigrateAcc, alwaysOnTop, canClear)
