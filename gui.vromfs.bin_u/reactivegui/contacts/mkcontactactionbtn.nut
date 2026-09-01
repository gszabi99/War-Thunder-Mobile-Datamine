from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/buttonStyles.nut" import COMMON, PRIMARY, defButtonHeight, defButtonMinWidth
from "%rGui/components/currencyComp.nut" import CS_COMMON
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonMultiline, mergeStyles, mkCustomButton, mkImageTextContent
from "%rGui/contacts/contactLists.nut" import friendsUids


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
    children = !isVisible.get() ? null
      : isInProgress.get() ? progressWait
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
    children = !isVisible.get() ? null
      : isInProgress.get() ? progressWait
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