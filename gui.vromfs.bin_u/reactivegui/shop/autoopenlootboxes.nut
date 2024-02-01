from "%globalsDarg/darg_library.nut" import *
let { lootboxInProgress, open_lootbox_several, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { unseenPurchasesExt, isShowUnseenDelayed } = require("unseenPurchasesState.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let lootboxOpenRouletteConfig = require("lootboxOpenRouletteConfig.nut")

let ERROR_UPDATE_DELAY = 60
let wasErrorSoon = Watched(false)

let lootboxes = Computed(function() {
  let { lootboxesCfg = {} } = serverConfigs.value
  let roulette = {}
  let silent = {}
  foreach(id, v in servProfile.value?.lootboxes ?? {}) {
    if (v == 0 || id not in lootboxesCfg)
      continue
    let { openType = "" } = lootboxesCfg[id]
    if (openType in lootboxOpenRouletteConfig || openType == "roulette")
      roulette[id] <- v
    else
      silent[id] <- v
  }
  return { roulette, silent }
})

let canOpenSilent = Computed(@() !isInBattle.value && lootboxInProgress.value == null && !wasErrorSoon.value)
let canOpenWithWindow = Computed(@() canOpenSilent.value
  && isLoggedIn.value
  && unseenPurchasesExt.value.len() == 0
  && !isShowUnseenDelayed.value
  && !isTutorialActive.value
  && !hasJustUnlockedUnitsAnimation.value)

let idToSilentOpen = keepref(Computed(@() canOpenSilent.value ? lootboxes.value.silent.findindex(@(_) true) : null))

registerHandler("onAutoOpenLootbox", @(res) res?.error == null ? null : wasErrorSoon(true))

function tryOpen() {
  if (idToSilentOpen.value != null)
    open_lootbox_several(idToSilentOpen.value, lootboxes.value.silent?[idToSilentOpen.value] ?? 1, "onAutoOpenLootbox")
}
tryOpen()
idToSilentOpen.subscribe(@(_) deferOnce(tryOpen))

let resetError = @() wasErrorSoon(false)
wasErrorSoon.subscribe(@(v) v ? resetTimeout(ERROR_UPDATE_DELAY, resetError) : null)

return {
  lootboxes
  canOpenWithWindow
  wasErrorSoon
}