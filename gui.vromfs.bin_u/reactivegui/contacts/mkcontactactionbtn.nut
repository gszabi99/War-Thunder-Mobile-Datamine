from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonMultiline, mergeStyles, mkCustomButton, mkImageTextContent } = require("%rGui/components/textButton.nut")
let { COMMON, PRIMARY, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { friendsUids } = require("%rGui/contacts/contactLists.nut")

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

function mkExtContactActionBtn(cfg, userId) {
  let { locId, mkIsVisible, action, mkIsInProgress = null } = cfg.action
  if (cfg?.onlyForFriends && userId not in friendsUids.get())
    return null
  let isVisible = mkIsVisible(userId)
  let isInProgress = mkIsInProgress?(userId) ?? neverInProgress
  return @() {
    watch = [isVisible, isInProgress, friendsUids]
    children = !isVisible.value ? null
      : isInProgress.value ? progressWait
      : mkCustomButton(
          mkImageTextContent(cfg.icon, CS_COMMON.iconSize, utf8ToUpper(loc(locId))),
          @() action(userId),
          mergeStyles(PRIMARY, { hotkeys = cfg.hotkeys }))
  }
}

return {
  mkContactActionBtn
  mkContactActionBtnPrimary = @(actionCfg, userId, btnStyle = {})
    mkContactActionBtn(actionCfg, userId, mergeStyles(PRIMARY, btnStyle))
  mkExtContactActionBtn
}