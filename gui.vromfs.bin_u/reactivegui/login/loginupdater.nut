from "%globalsDarg/darg_library.nut" import *
from "app" import get_base_game_version_str
from "contentUpdater" import UPDATER_DOWNLOADING, UPDATER_PURIFYING, UPDATER_DOWNLOADING_YUP
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/updater/updaterErrors.nut" import getErrorName
from "%globalsDarg/components/titleLogo.nut" import mkTitleLogo
from "%globalsDarg/loading/loadingProgressbar.nut" import mkProgressStatusText, mkProgressbar, progressbarGap
from "%globalsDarg/updaterUtils.nut" import getDownloadInfoText
from "%rGui/guiFpsLimit.nut" import addFpsLimit, removeFpsLimit
from "%rGui/loading/loadingScreen.nut" import gradientLoadingTip
from "%rGui/login/loginUpdaterState.nut" import updaterState
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const spinnerSize = hdpx(100)

let defaultStatusText = @(s) s?.percent == null ? loc("pl1/check_profile")
  : "".concat(loc("pl1/check_profile"), colon, s.percent.tointeger(), "%")

let statusByStage = {
  [UPDATER_DOWNLOADING] = function(s) {
    let action = loc("updater/downloading")
    let info = getDownloadInfoText(s?.toDownload ?? 0, s?.etaSec ?? 0, s?.dspeed ?? 0)
    return info != ""
      ? "".concat(action, loc("ui/parentheses/space", { text = info }))
      : action
  },
  [UPDATER_PURIFYING] = @(_) loc("pl1/check_profile"),
  [UPDATER_DOWNLOADING_YUP] = @(_) loc("pl1/check_profile"),
}

let statusText = Computed(function() {
  let { stage = null, errorCode = null } = updaterState.get()
  return errorCode != null ? loc($"updater/error/{getErrorName(errorCode)}")
    : stage != null ? (statusByStage?[stage] ?? defaultStatusText)(updaterState.get())
    : ""
})

let progressPercent = Computed(@() updaterState.get()?.percent ?? 0)

let infoComp = @() {
  watch = myUserId
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  text = "\n".concat(
    "".concat(loc("userID"), colon, myUserId.get())
    "".concat(loc("mainmenu/version"), colon, get_base_game_version_str())
  )
}.__update(fontTiny)

let bottomBlock = {
  size = FLEX
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = progressbarGap
  children = [
    mkProgressStatusText(statusText, infoComp)
    mkProgressbar(progressPercent)
  ]
}

let tip = gradientLoadingTip.__merge({ pos = const [0, sh(-15)] })

let waitSpinner = {
  size = const [spinnerSize, spinnerSize]
  hplace = ALIGN_RIGHT
  margin = saBordersRv
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#progress_bar_circle.svg:{spinnerSize}:{spinnerSize}")
  color = 0x01606060
  transform = {}
  animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3.0, play = true, loop = true }]
}

let loginUpdaterKey = {}
let mkLoginUpdater = @() {
  key = loginUpdaterKey
  size = FLEX
  children = [
    waitSpinner
    mkTitleLogo({ margin = saBordersRv })
    {
      size = FLEX
      padding = saBordersRv
      children = [
        tip
        bottomBlock
      ]
    }
  ]
  onAttach = @() addFpsLimit(loginUpdaterKey)
  onDetach = @() removeFpsLimit(loginUpdaterKey)
  animations = wndSwitchAnim
}

return mkLoginUpdater
