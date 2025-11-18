from "%globalsDarg/darg_library.nut" import *
let { lootboxInProgress, open_lootbox_several, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { unseenPurchasesExt, isShowUnseenDelayed } = require("%rGui/shop/unseenPurchasesState.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let lootboxOpenRouletteConfig = require("%rGui/shop/lootboxOpenRouletteConfig.nut")

let ERROR_UPDATE_DELAY = 60
let wasErrorSoon = Watched(false)

let lootboxes = Computed(function() {
  let { lootboxesCfg = {} } = serverConfigs.get()
  let roulette = {}
  let silent = {}
  foreach(id, v in servProfile.get()?.lootboxes ?? {}) {
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

let canOpenSilent = Computed(@() !isInBattle.get() && lootboxInProgress.get() == null && !wasErrorSoon.get())
let canOpenWithWindow = Computed(@() canOpenSilent.get()
  && isLoggedIn.get()
  && unseenPurchasesExt.get().len() == 0
  && !isShowUnseenDelayed.get()
  && !isTutorialActive.get())

let idToSilentOpen = keepref(Computed(@() canOpenSilent.get() ? lootboxes.get().silent.findindex(@(_) true) : null))

registerHandler("onAutoOpenLootbox", @(res) res?.error == null ? null : wasErrorSoon.set(true))

function tryOpen() {
  if (idToSilentOpen.get() != null)
    open_lootbox_several(idToSilentOpen.get(), lootboxes.get().silent?[idToSilentOpen.get()] ?? 1, "onAutoOpenLootbox")
}
tryOpen()
idToSilentOpen.subscribe(@(_) deferOnce(tryOpen))

let resetError = @() wasErrorSoon.set(false)
wasErrorSoon.subscribe(@(v) v ? resetTimeout(ERROR_UPDATE_DELAY, resetError) : null)

return {
  lootboxes
  canOpenWithWindow
  wasErrorSoon
}