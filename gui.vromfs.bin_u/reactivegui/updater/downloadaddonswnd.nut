from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/components/titleLogo.nut" import mkTitleLogo
from "%globalsDarg/loading/loadingProgressbar.nut" import mkProgressStatusText, mkProgressbar, progressbarGap
from "%globalsDarg/updaterUtils.nut" import getDownloadInfoText
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/toggle.nut" import horizontalToggleWithLabel
from "%rGui/components/translucentButton.nut" import translucentIconButton
from "%rGui/guiFpsLimit.nut" import addFpsLimit, removeFpsLimit
from "%rGui/loading/loadingScreen.nut" import loadingAnimBg, gradientLoadingTip
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/updater/updaterState.nut" import downloadWndParams, closeDownloadAddonsWnd, wantStartDownloadAddons,
  isDownloadPaused, downloadAddonsStr, totalSizeBytes, downloadState, updaterError, progressPercent,
  allowLimitedDownload, isDownloadPausedByConnection, isDownloadInProgress, isStageDownloading


const wndUid = "downloadAddonsWnd"
let spinnerSize = hdpx(100).tointeger()
const downloadingColor = 0xFFE8E8E8
const checkingColor = 0x80808080

let progressPercentInt = Computed(@() progressPercent.get() ?? 0)

let statusText = Computed(@() wantStartDownloadAddons.get().len() == 0 ? loc("updater/status/complete")
  : isDownloadPaused.get() ? "".concat(
      loc("updater/status/paused", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.get(), 0, 0))
  : isDownloadPausedByConnection.get() ? "".concat(
      loc("updater/status/pausedByConnection", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.get(), 0, 0))
  : updaterError.get() != null ? loc($"updater/error/{updaterError.get()}")
  : !isStageDownloading.get() ? loc("pl1/check_profile")
  : "".concat(
      loc("updater/status/downloading", { addonInfo = downloadAddonsStr.get() }),
      colon, getDownloadInfoText(totalSizeBytes.get(), downloadState.get()?.etaSec ?? 0, downloadState.get()?.dspeed ?? 0))
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
    isDownloadInProgress.get() ? waitSpinner : null
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

let tip = gradientLoadingTip.__merge({ pos = const [0, sh(-15)] })

let openLimitConnectionMsgBox = @() openMsgBox({
  text = loc("msg/allowMobileNetworkDownload")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "download", styleId = "PRIMARY", isDefault = true,
      function cb() {
        allowLimitedDownload.set(true)
        isDownloadPaused.set(false)
      }
    }
  ]
})

function pauseButton() {
  let res = { watch = [isDownloadPaused, isDownloadPausedByConnection, wantStartDownloadAddons] }
  if (wantStartDownloadAddons.get().len() == 0)
    return res
  return res.__update({
    opacity = isDownloadPausedByConnection.get() ? 0.3 : 1.0
    children = translucentIconButton(
      isDownloadPaused.get() || isDownloadPausedByConnection.get()
        ? "ui/gameuiskin#replay_play.svg"
        : "ui/gameuiskin#replay_pause.svg",
      @() isDownloadPausedByConnection.get() ? openLimitConnectionMsgBox()
        : isDownloadPaused.set(!isDownloadPaused.get()),
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
  size = FLEX
  children = [
    loadingAnimBg
    {
      size = FLEX
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
  size = FLEX
  children = mkProgressWnd()
  onClick = @() null
})

if (downloadWndParams.get() != null)
  openProgressWnd()
downloadWndParams.subscribe(@(p) p == null ? removeModalWindow(wndUid)
  : openProgressWnd())
