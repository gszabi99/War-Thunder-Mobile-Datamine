from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[UNSEEN_REWARDS] ")
let { resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { unseenPurchases, lootboxes } = require("%appGlobals/pServer/campaign.nut")
let { clear_unseen_purchases } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { G_STAT, G_MEDAL } = require("%appGlobals/rewardType.nut")
let unseenPurchasesDebug = require("%rGui/shop/unseenPurchasesDebug.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")

let invisibleGoodsTypes = [G_STAT, G_MEDAL] 
  .reduce(@(res, v) res.$rawset(v, true), {})

let ignoreUnseen = Watched({}) 
let isShowDelayed = Watched(false)
let skipUnseenMessageAnimOnce = Watched(false)
let isUnseenGoodsVisible = @(goods, source, srvCfg, lboxes) (goods.gType not in invisibleGoodsTypes)
  && (goods.gType != "lootbox"
    || (source == "lootbox" && (lboxes?[goods.id] ?? 0) > 0 && (srvCfg?.lootboxesCfg[goods.id].openType != "jackpot_only")))  
let seenPurchasesNoNeedToShow = Computed(function() {
  let lboxes = lootboxes.get()
  return unseenPurchases.get()
    .filter(@(data) data.goods.findvalue(@(g) isUnseenGoodsVisible(g, data.source, serverConfigs.get(), lboxes)) == null)
})
let unseenPurchasesExt = Computed(@() unseenPurchasesDebug.get()
  ?? (isShowDelayed.get() ? {}
    : unseenPurchases.get().filter(@(_, id) id not in ignoreUnseen.get()
        && id not in seenPurchasesNoNeedToShow.get())))

let unseenPurchasesCount = keepref(Computed(@() unseenPurchases.get().len()))
unseenPurchasesCount.subscribe(@(c) logR("unseenPurchasesCount = ", c))
let unseenPurchasesCountExt = keepref(Computed(@() unseenPurchasesExt.get().len()))
unseenPurchasesCountExt.subscribe(@(c) logR("unseenPurchasesCountExt = ", c))

let unseenGroups = [
  {
    isFit = @(purch) purch?.source.startswith("userstatReward&[{") ?? false
    sourcePrefix = "userstatReward&"
    style = "leaderboard"
  }
  {
    isFit = @(purch) purch?.source.endswith("&customStyle") ?? false
    sourcePostfix = "&customStyle"
    style = "customTexts"
  }
]

let activeUnseenPurchasesGroup = Computed(function() {
  if (unseenPurchasesExt.get().len() != 0)
    foreach(group in unseenGroups) {
      let list = unseenPurchasesExt.get().filter(group.isFit)
      if (list.len() > 0)
        return group.filter(@(v) type(v) != "function")
          .__update({ list })
    }
  return { list = unseenPurchasesExt.get() }
})

function markPurchasesSeen(seenIds) {
  if (unseenPurchasesDebug.get() != null)
    return unseenPurchasesDebug.set(null)

  let hasNotIgnore = seenIds.findvalue(@(id) id not in ignoreUnseen.get()) != null
  if (!hasNotIgnore)
    return

  ignoreUnseen.mutate(function(v) {
    foreach (id in seenIds)
      v[id] <- true
    foreach (id in v.keys())
      if (id not in unseenPurchases.get())
        v.$rawdelete(id)
  })
  clear_unseen_purchases(seenIds)
}

markPurchasesSeen(seenPurchasesNoNeedToShow.get().keys())
seenPurchasesNoNeedToShow.subscribe(@(v) markPurchasesSeen(v.keys()))

isLoggedIn.subscribe(@(_) ignoreUnseen.set({}))
subscribeResetProfile(@() ignoreUnseen.set({}))

let customUnseenPurchHandlers = []
let customUnseenPurchVersion = Watched(0)
let incCustomVersion = @() customUnseenPurchVersion.set(customUnseenPurchVersion.get() + 1)

let customUnseenData = Computed(function() {
  let ver = customUnseenPurchVersion.get() 
  foreach (idx, cfg in customUnseenPurchHandlers) {
    let list = unseenPurchasesExt.get().filter(cfg.isFit)
    if (list.len() > 0)
      return { idx, list }
  }
  return null
})

customUnseenData.subscribe(function(data) {
  if (data != null)
    customUnseenPurchHandlers?[data.idx].show(data.list)
})

function removeCustomUnseenPurchHandler(showUnseen) {
  let idx = customUnseenPurchHandlers.findindex(@(h) h.show == showUnseen)
  if (idx == null)
    return
  customUnseenPurchHandlers.remove(idx)
  incCustomVersion()
}

function addCustomUnseenPurchHandler(isUnseenFit, showUnseen) {
  let idx = customUnseenPurchHandlers.findindex(@(h) h.show == showUnseen)
  if (idx != null)
    customUnseenPurchHandlers.remove(idx)
  customUnseenPurchHandlers.append({ isFit = isUnseenFit, show = showUnseen })
  incCustomVersion()
}

let unseenPurchaseUnitPlateKey = @(name) name == null ? null : $"unseenPurchaseUnitPlate:{name}"

function undelayShow() {
  logR("undelayShow unseen")
  isShowDelayed.set(false)
}
function delayShow(time) {
  if (time > 0) {
    logR("delayShow unseen for ", time)
    isShowDelayed.set(true)
    resetTimeout(time, undelayShow)
  }
  else {
    logR("undelayShow unseen")
    isShowDelayed.set(false)
  }
}

register_command(@() console_print("unseenPurchasesExt = ", unseenPurchasesExt.get()) , "debug.currentUnseenPurchases") 
register_command(@() console_print("activeUnseenPurchasesGroup = ", activeUnseenPurchasesGroup.get()) , "debug.activeUnseenPurchasesGroup") 
register_command(@() console_print("activeUnseenPurchasesGroup.list = ", activeUnseenPurchasesGroup.get().list) , "debug.activeUnseenPurchasesGroup.list") 

return {
  unseenPurchasesExt
  activeUnseenPurchasesGroup
  markPurchasesSeen
  customUnseenPurchVersion
  removeCustomUnseenPurchHandler
  addCustomUnseenPurchHandler
  hasActiveCustomUnseenView = Computed(@() customUnseenData.get() != null)
  delayUnseedPurchaseShow = delayShow
  isShowUnseenDelayed = isShowDelayed
  skipUnseenMessageAnimOnce
  isUnseenGoodsVisible
  unseenPurchaseUnitPlateKey
}