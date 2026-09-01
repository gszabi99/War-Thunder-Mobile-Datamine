from "%globalsDarg/darg_library.nut" import *
from "android.billing.googleplay" import getCountryCode
from "android.platform" import isDownloadedFromGooglePlay
from "app" import get_base_game_version_str
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/version_compare.nut" import check_version
from "%appGlobals/clientState/clientState.nut" import isInMenu, isOutOfBattleAndResults
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, get_migrate_acc_info, migAccInfoInProgress
from "%appGlobals/permissions.nut" import external_gp_build_released
from "%rGui/account/emailRegistrationState.nut" import canUpgradeGuestAccountToGaijinID, openGuestEmailRegistration
from "%rGui/account/linkEmailForGaijinLogin.nut" import canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader, wndHeaderHeight
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/components/textButton.nut" import textButtonBattle
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import locColorTable


const INCOMPATIBLE_FROM_VERSION = "1.26.0.0"
const GUEST_MSG_UID = "migrateGuestUpgrade"

local info = null

let wndW = min(hdpx(1782), saSize[0])
let wndH = min(hdpx(972),  saSize[1])
const wndPadW = hdpx(90)
const wndPadH = hdpx(50)
let contentW = wndW - (2 * wndPadW)
const parGap = hdpx(40)
const advGap = hdpx(30)
const urlColor = 0xFF17C0FC
const urlHoverColor = 0xFF84E0FA
const urlLineWidth = hdpxi(1)

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

function openPixelSitePage() {
  if (info?.PIXEL_SITE_URL != null)
    eventbus_send("openUrl", { baseUrl = info.PIXEL_SITE_URL })
}

function upgradeGuestAccount() {
  if (canLinkEmailForGaijinLogin.get())
    openLinkEmailForGaijinLogin()
  else if (canUpgradeGuestAccountToGaijinID.get())
    openGuestEmailRegistration()
}

function onMigrateClick() {
  if (!canLinkEmailForGaijinLogin.get() && !canUpgradeGuestAccountToGaijinID.get())
    return openMigrationWebpageAndMaybeClose()

  openMsgBox({
    uid = GUEST_MSG_UID
    title = utf8ToUpper(info?.guestAccTitle ?? "")
    text = info?.guestAccDesc ?? ""
    function onBgClick() {
      closeMsgBox(GUEST_MSG_UID)
      close()
    }
    buttons = [{ text = info?.btnGaijinId, styleId = "PRIMARY", isDefault = true, cb = upgradeGuestAccount }]
  })
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
        ? mkIcon(advIcons[idx], hdpx(60))
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

function mkUrlLink(text, action) {
  if (text == "")
    return null
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    rendObj = ROBJ_TEXT
    text
    color = (stateFlags.get() & S_HOVER) ? urlHoverColor : urlColor
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = action
    children = {
      size = const [flex(), urlLineWidth]
      vplace = ALIGN_BOTTOM
      rendObj = ROBJ_SOLID
      color = (stateFlags.get() & S_HOVER) ? urlHoverColor : urlColor
    }
  }.__update(fontTinyAccented)
}

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
      padding = const [wndPadH, wndPadW]
      flow = FLOW_VERTICAL
      children = [
        {
          size = flex()
          flow = FLOW_VERTICAL
          gap = hdpx(70)
          children = [
            mkTextarea(utf8ToUpper(info?.subtitle ?? ""),
              { size = const [flex(), SIZE_TO_CONTENT], halign = ALIGN_CENTER }.__update(fontBoldSmall))
            {
              size = [flex(), SIZE_TO_CONTENT]
              margin = [0, 0, hdpx(30), 0]
              flow = FLOW_HORIZONTAL
              gap = parGap
              children = mkParComps()
            }
            {
              size = const [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = advGap
              children = mkAdvComps()
            }
          ]
        }
        {
          size = const [flex(), SIZE_TO_CONTENT]
          vplace = ALIGN_BOTTOM
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          children = [
            {
              flow = FLOW_VERTICAL
              gap = hdpx(20)
              children = [
                mkUrlLink(info?.btnApp ?? "", openRegionalAppPageInGooglePlay)
                mkUrlLink(info?.btnPix ?? "", openPixelSitePage)
              ]
            }
            { size = FLEX }
            textButtonBattle(utf8ToUpper(info?.btnMigrate ?? ""), onMigrateClick)
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

const alwaysOnTop = true
let canClear = @() canClose
registerScene("suggestMigrateAcc", mkScene, close, needSuggestMigrateAcc, alwaysOnTop, canClear)
