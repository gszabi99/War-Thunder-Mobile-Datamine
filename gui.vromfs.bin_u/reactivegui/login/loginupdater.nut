from "%globalsDarg/darg_library.nut" import *
let { get_base_game_version_str } = require("app")
let { UPDATER_DOWNLOADING, UPDATER_PURIFYING, UPDATER_DOWNLOADING_YUP
} = require("contentUpdater")
let { mkProgressStatusText, mkProgressbar, progressbarGap } = require("%globalsDarg/loading/loadingProgressbar.nut")
let { updaterState } = require("loginUpdaterState.nut")
let { gradientLoadingTip } = require("%rGui/loading/loadingScreen.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")
let { getDownloadInfoText } = require("%globalsDarg/updaterUtils.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let spinnerSize = hdpx(100)

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
  return errorCode != null ? loc($"updater/error/{errorCode}")
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
  size = flex()
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = progressbarGap
  children = [
    mkProgressStatusText(statusText, infoComp)
    mkProgressbar(progressPercent)
  ]
}

let tip = gradientLoadingTip.__merge({ pos = [0, sh(-15)] })

let waitSpinner = {
  size = [spinnerSize, spinnerSize]
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
  size = flex()
  children = [
    waitSpinner
    mkTitleLogo({ margin = saBordersRv })
    {
      size = flex()
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
