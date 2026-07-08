from "%globalsDarg/darg_library.nut" import *
from "app" import get_base_game_version_str
from "eventbus" import eventbus_send
from "android.platform" import isDownloadedFromGooglePlay
from "android.billing.googleplay" import getCountryCode
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/platform.nut" import is_android
from "%sqstd/version_compare.nut" import check_version
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/permissions.nut" import external_gp_build_released
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator
from "%appGlobals/clientState/clientState.nut" import isInMenu, isOutOfBattleAndResults
from "%rGui/navState.nut" import registerScene
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader, wndHeaderHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp

const INCOMPATIBLE_FROM_VERSION = "1.26.0.0"
const MIGRATE_ACCOUNT_INFO_URL = "auto_login https://login.gaijin.net/ru/migrate?game=wtm"
const SUGGEST_MIGRATE_ACC_GOOGLE_MSG = "suggest_migrate_acc_google_msg"

let wndW = hdpx(1000)
let wndH = hdpx(800)
let wndPad = hdpx(30)

let isSuggested = hardPersistWatched("suggestMigrateAccGoogle.isSuggested", false)
let shouldsuggestMigrateAcc = keepref(Computed(@() external_gp_build_released.get() && !isExternalOperator()
  && is_android && isDownloadedFromGooglePlay() && ["RU","BY"].contains(getCountryCode())))
let needsuggestMigrateAcc = keepref(Computed(@() shouldsuggestMigrateAcc.get() && !isSuggested.get()
  && isInMenu.get() && isOutOfBattleAndResults.get()))

let ver = get_base_game_version_str()
let canClose = ver == "" || check_version($"<{INCOMPATIBLE_FROM_VERSION}", ver)

let close = @() canClose ? isSuggested.set(true) : null

function openMigrationWebpageAndMaybeClose() {
  eventbus_send("openUrl", { baseUrl = MIGRATE_ACCOUNT_INFO_URL })
  close()
}

let mkTextarea = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontSmall, ovr)

let mkContent = @() modalWndBg.__merge({
  size = [wndW, wndH]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), wndHeaderHeight]
      valign = ALIGN_CENTER
      children = [
        modalWndHeader("migrateAcc/wndTitle")
        !canClose ? null : closeWndBtn(close, { hotkeys = [btnBEscUp] })
      ]
    }
    {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      padding = wndPad
      children = mkTextarea("migrateAcc/msg", { maxWidth = wndW - wndPad })
    }
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      padding = wndPad
      children = textButtonPrimary(utf8ToUpper(loc("migrateAcc/btn")), openMigrationWebpageAndMaybeClose)
    }
  ]
})

let mkScene = @() {
  key = SUGGEST_MIGRATE_ACC_GOOGLE_MSG
  size = FLEX
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkContent()
}

let alwaysOnTop = true
let canClear = @() canClose
registerScene("suggestMigrateAccGoogle", mkScene, close, needsuggestMigrateAcc, alwaysOnTop, canClear)
