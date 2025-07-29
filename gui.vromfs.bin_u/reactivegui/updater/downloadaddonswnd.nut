from "%globalsDarg/darg_library.nut" import *
let { mkProgressStatusText, mkProgressbar, progressbarGap } = require("%globalsDarg/loading/loadingProgressbar.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { downloadWndParams, closeDownloadAddonsWnd, wantStartDownloadAddons, isDownloadPaused, downloadAddonsStr,
  totalSizeBytes, downloadState, updaterError, progressPercent, allowLimitedDownload,
  isDownloadPausedByConnection, isDownloadInProgress, isStageDownloading
} = require("updaterState.nut")
let { loadingAnimBg, gradientLoadingTip } = require("%rGui/loading/loadingScreen.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")
let { getDownloadInfoText } = require("%globalsDarg/updaterUtils.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { translucentIconButton } = require("%rGui/components/translucentButton.nut")
let { horizontalToggleWithLabel } = require("%rGui/components/toggle.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let wndUid = "downloadAddonsWnd"
let spinnerSize = hdpx(100).tointeger()
let downloadingColor = 0xFFE8E8E8
let checkingColor = 0x80808080

let progressPercentInt = Computed(@() progressPercent.get() ?? 0)

let statusText = Computed(@() wantStartDownloadAddons.get().len() == 0 ? loc("updater/status/complete")
  : isDownloadPaused.get() ? "".concat(
      loc("updater/status/paused", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.value, 0, 0))
  : isDownloadPausedByConnection.value ? "".concat(
      loc("updater/status/pausedByConnection", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.value, 0, 0))
  : updaterError.get() != null ? loc($"updater/error/{updaterError.get()}")
  : !isStageDownloading.get() ? loc("pl1/check_profile")
  : "".concat(
      loc("updater/status/downloading", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.value, downloadState.value?.etaSec ?? 0, downloadState.value?.dspeed ?? 0))
)

let waitSpinner = {
  size = [spinnerSize, spinnerSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#progress_bar_circle.svg:{spinnerSize}:{spinnerSize}")
  color = 0x01606060
  transform = {}
  animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3.0, play = true, loop = true }]
}

let limitedDownloadToggle = horizontalToggleWithLabel(allowLimitedDownload, loc("btn/allowMobileNetworkDownload"))

let headerRight = @() {
  watch = isDownloadInProgress
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    limitedDownloadToggle
    isDownloadInProgress.value ? waitSpinner : null
  ]
}

let mkHeaderLeft = @() {
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    backButton(closeDownloadAddonsWnd)
    mkTitleLogo()
  ]
}

let tip = gradientLoadingTip.__merge({ pos = [0, sh(-15)] })

let openLimitConnectionMsgBox = @() openMsgBox({
  text = loc("msg/allowMobileNetworkDownload")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "download", styleId = "PRIMARY", isDefault = true,
      function cb() {
        allowLimitedDownload(true)
        isDownloadPaused(false)
      }
    }
  ]
})

function pauseButton() {
  let res = { watch = [isDownloadPaused, isDownloadPausedByConnection, wantStartDownloadAddons] }
  if (wantStartDownloadAddons.get().len() == 0)
    return res
  return res.__update({
    opacity = isDownloadPausedByConnection.value ? 0.3 : 1.0
    children = translucentIconButton(
      isDownloadPaused.get() || isDownloadPausedByConnection.value
        ? "ui/gameuiskin#replay_play.svg"
        : "ui/gameuiskin#replay_pause.svg",
      @() isDownloadPausedByConnection.value ? openLimitConnectionMsgBox()
        : isDownloadPaused(!isDownloadPaused.get()),
      hdpxi(45),
      [hdpx(105), hdpx(80)]
    )
  })
}

let bottomBlock = {
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    pauseButton
    @() {
      watch = isStageDownloading
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = progressbarGap
      children = [
        mkProgressStatusText(statusText)
        mkProgressbar(progressPercentInt, isStageDownloading.get() ? downloadingColor : checkingColor)
      ]
    }
  ]
}

let progressWndKey = {}
let mkProgressWnd = @() {
  key = progressWndKey
  size = flex()
  children = [
    loadingAnimBg
    {
      size = flex()
      padding = saBordersRv
      children = [
        mkHeaderLeft()
        headerRight
        tip
        bottomBlock
      ]
    }
  ]
  animations = wndSwitchAnim
  onAttach = @() addFpsLimit(progressWndKey)
  onDetach = @() removeFpsLimit(progressWndKey)
}

let openProgressWnd = @() addModalWindow({
  key = wndUid
  size = flex()
  children = mkProgressWnd()
  onClick = @() null
})

if (downloadWndParams.get() != null)
  openProgressWnd()
downloadWndParams.subscribe(@(p) p == null ? removeModalWindow(wndUid)
  : openProgressWnd())
