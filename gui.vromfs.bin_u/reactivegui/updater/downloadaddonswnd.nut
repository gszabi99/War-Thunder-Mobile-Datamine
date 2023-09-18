from "%globalsDarg/darg_library.nut" import *
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
let backButton = require("%rGui/components/backButton.nut")
let { translucentIconButton } = require("%rGui/components/translucentButton.nut")
let { toggleWithLabel } = require("%rGui/components/toggle.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let wndUid = "downloadAddonsWnd"
let spinnerSize = hdpx(100).tointeger()
let downloadingColor = 0xFF00FDFF
let checkingColor = 0x80808080

let statusText = Computed(@() wantStartDownloadAddons.value.len() == 0 ? loc("updater/status/complete")
  : isDownloadPaused.value ? "".concat(
      loc("updater/status/paused", { addonInfo = downloadAddonsStr.value }),
      colon, getDownloadInfoText(totalSizeBytes.value, 0, 0))
  : isDownloadPausedByConnection.value ? "".concat(
      loc("updater/status/pausedByConnection", { addonInfo = downloadAddonsStr.value }),
      colon, getDownloadInfoText(totalSizeBytes.value, 0, 0))
  : updaterError.value != null ? loc($"updater/error/{updaterError.value}")
  : !isStageDownloading.value ? loc("pl1/check_profile")
  : "".concat(
      loc("updater/status/downloading", { addonInfo = downloadAddonsStr.value }),
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

let limitedDownloadToggle = toggleWithLabel(allowLimitedDownload, loc("btn/allowMobileNetworkDownload"))

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

let function pauseButton() {
  let res = { watch = [isDownloadPaused, isDownloadPausedByConnection, wantStartDownloadAddons] }
  if (wantStartDownloadAddons.value.len() == 0)
    return res
  return res.__update({
    opacity = isDownloadPausedByConnection.value ? 0.3 : 1.0
    children = translucentIconButton(
      isDownloadPaused.value || isDownloadPausedByConnection.value
        ? "ui/gameuiskin#replay_play.svg"
        : "ui/gameuiskin#replay_pause.svg",
      @() isDownloadPausedByConnection.value ? openLimitConnectionMsgBox()
        : isDownloadPaused(!isDownloadPaused.value),
      hdpxi(45),
      [hdpx(105), hdpx(80)]
    )
  })
}

let bottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    pauseButton
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        @() {
          watch = statusText
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = statusText.value
        }.__update(fontMediumShaded)
        {
          size = [flex(), hdpx(15)]
          rendObj = ROBJ_SOLID
          color = 0xFF827A7A
          children = @() {
            watch = [progressPercent, isStageDownloading]
            size = [pw(progressPercent.value ?? 0), flex()]
            rendObj = ROBJ_SOLID
            color = isStageDownloading.value ? downloadingColor : checkingColor
          }
        }
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

if (downloadWndParams.value != null)
  openProgressWnd()
downloadWndParams.subscribe(@(p) p == null ? removeModalWindow(wndUid)
  : openProgressWnd())
