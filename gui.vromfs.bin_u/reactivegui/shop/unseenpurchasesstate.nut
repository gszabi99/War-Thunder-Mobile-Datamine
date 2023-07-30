from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { unseenPurchases } = require("%appGlobals/pServer/campaign.nut")
let { clear_unseen_purchases } = require("%appGlobals/pServer/pServerApi.nut")
let unseenPurchasesDebug = require("unseenPurchasesDebug.nut")

let ignoreUnseen = Watched({}) //no need to persist them if has errors with pServer, better to show window again after reload scripts.
let isShowDelayed = Watched(false)
let unseenPurchasesExt = Computed(@() unseenPurchasesDebug.value
  ?? (isShowDelayed.value ? {}
    : unseenPurchases.value.filter(@(_, id) id not in ignoreUnseen.value)))

let function markPurchasesSeen(seenIds) {
  if (unseenPurchasesDebug.value != null)
    return unseenPurchasesDebug(null)

  ignoreUnseen.mutate(function(v) {
    foreach (id in seenIds)
      v[id] <- true
  })
  clear_unseen_purchases(seenIds)
}

let customUnseenPurchHandlers = []
let customUnseenPurchVersion = Watched(0)
let incCustomVersion = @() customUnseenPurchVersion(customUnseenPurchVersion.value + 1)

let customUnseenData = Computed(function() {
  let ver = customUnseenPurchVersion.value //warning disable: -declared-never-used
  foreach (idx, cfg in customUnseenPurchHandlers) {
    let list = unseenPurchasesExt.value.filter(cfg.isFit)
    if (list.len() > 0)
      return { idx, list }
  }
  return null
})

customUnseenData.subscribe(function(data) {
  if (data != null)
    customUnseenPurchHandlers?[data.idx].show(data.list)
})

let function removeCustomUnseenPurchHandler(showUnseen) {
  let idx = customUnseenPurchHandlers.findindex(@(h) h.show == showUnseen)
  if (idx == null)
    return
  customUnseenPurchHandlers.remove(idx)
  incCustomVersion()
}

let function addCustomUnseenPurchHandler(isUnseenFit, showUnseen) {
  let idx = customUnseenPurchHandlers.findindex(@(h) h.show == showUnseen)
  if (idx != null)
    customUnseenPurchHandlers.remove(idx)
  customUnseenPurchHandlers.append({ isFit = isUnseenFit, show = showUnseen })
  incCustomVersion()
}

let undelayShow = @() isShowDelayed(false)
let function delayShow(time) {
  isShowDelayed(true)
  resetTimeout(time, undelayShow)
}

return {
  unseenPurchasesExt
  markPurchasesSeen
  customUnseenPurchVersion
  removeCustomUnseenPurchHandler
  addCustomUnseenPurchHandler
  hasActiveCustomUnseenView = Computed(@() customUnseenData.value != null)
  delayUnseedPurchaseShow = delayShow
  isShowUnseenDelayed = isShowDelayed
}