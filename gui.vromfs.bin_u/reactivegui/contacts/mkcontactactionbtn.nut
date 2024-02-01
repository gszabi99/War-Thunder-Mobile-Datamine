from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonMultiline, mergeStyles } = require("%rGui/components/textButton.nut")
let { COMMON, PRIMARY, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { spinner } = require("%rGui/components/spinner.nut")

let neverInProgress = Watched(false)

let progressWait = {
  size = [defButtonMinWidth, defButtonHeight]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = spinner
}

function mkContactActionBtn(actionCfg, userId, btnStyle = {}) {
  let { locId, mkIsVisible, action, mkIsInProgress = null } = actionCfg
  let isVisible = mkIsVisible(userId)
  let isInProgress = mkIsInProgress?(userId) ?? neverInProgress
  return @() {
    watch = [isVisible, isInProgress]
    children = !isVisible.value ? null
      : isInProgress.value ? progressWait
      : textButtonMultiline(utf8ToUpper(loc(locId)), @() action(userId), mergeStyles(COMMON, btnStyle))
  }
}

return {
  mkContactActionBtn
  mkContactActionBtnPrimary = @(actionCfg, userId, btnStyle = {})
    mkContactActionBtn(actionCfg, userId, mergeStyles(PRIMARY, btnStyle))
}