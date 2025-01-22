from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[UNSEEN_REWARDS] ")
let { resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { unseenPurchases, lootboxes } = require("%appGlobals/pServer/campaign.nut")
let { clear_unseen_purchases } = require("%appGlobals/pServer/pServerApi.nut")
let unseenPurchasesDebug = require("unseenPurchasesDebug.nut")

let invisibleGoodsTypes = ["stat", "medal"] //temporary medals no need to be shown
  .reduce(@(res, v) res.$rawset(v, true), {})

let ignoreUnseen = Watched({}) //no need to persist them if has errors with pServer, better to show window again after reload scripts.
let isShowDelayed = Watched(false)
let skipUnseenMessageAnimOnce = Watched(false)
let isUnseenGoodsVisible = @(goods, source, lboxes) (goods.gType not in invisibleGoodsTypes)
  && (goods.gType != "lootbox" || (source == "lootbox" && (lboxes?[goods.id] ?? 0) > 0))  //show not opened lootboxes
let seenPurchasesNoNeedToShow = Computed(function() {
  let lboxes = lootboxes.get()
  return unseenPurchases.value
    .filter(@(data) data.goods.findvalue(@(g) isUnseenGoodsVisible(g, data.source, lboxes)) == null)
})
let unseenPurchasesExt = Computed(@() unseenPurchasesDebug.value
  ?? (isShowDelayed.value ? {}
    : unseenPurchases.value.filter(@(_, id) id not in ignoreUnseen.value
        && id not in seenPurchasesNoNeedToShow.value)))

let unseenPurchasesCount = keepref(Computed(@() unseenPurchases.value.len()))
unseenPurchasesCount.subscribe(@(c) logR("unseenPurchasesCount = ", c))
let unseenPurchasesCountExt = keepref(Computed(@() unseenPurchasesExt.value.len()))
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
  if (unseenPurchasesExt.value.len() != 0)
    foreach(group in unseenGroups) {
      let list = unseenPurchasesExt.value.filter(group.isFit)
      if (list.len() > 0)
        return group.filter(@(v) type(v) != "function")
          .__update({ list })
    }
  return { list = unseenPurchasesExt.value }
})

function markPurchasesSeen(seenIds) {
  if (unseenPurchasesDebug.value != null)
    return unseenPurchasesDebug(null)

  let hasNotIgnore = seenIds.findvalue(@(id) id not in ignoreUnseen.value) != null
  if (!hasNotIgnore)
    return

  ignoreUnseen.mutate(function(v) {
    foreach (id in seenIds)
      v[id] <- true
  })
  clear_unseen_purchases(seenIds)
}

markPurchasesSeen(seenPurchasesNoNeedToShow.value.keys())
seenPurchasesNoNeedToShow.subscribe(@(v) markPurchasesSeen(v.keys()))

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
  isShowDelayed(false)
}
function delayShow(time) {
  if (time > 0) {
    logR("delayShow unseen for ", time)
    isShowDelayed(true)
    resetTimeout(time, undelayShow)
  }
  else {
    logR("undelayShow unseen")
    isShowDelayed(false)
  }
}

register_command(@() console_print("unseenPurchasesExt = ", unseenPurchasesExt.value) , "debug.currentUnseenPurchases") //warning disable: -forbidden-function
register_command(@() console_print("activeUnseenPurchasesGroup = ", activeUnseenPurchasesGroup.value) , "debug.activeUnseenPurchasesGroup") //warning disable: -forbidden-function
register_command(@() console_print("activeUnseenPurchasesGroup.list = ", activeUnseenPurchasesGroup.value.list) , "debug.activeUnseenPurchasesGroup.list") //warning disable: -forbidden-function

return {
  unseenPurchasesExt
  activeUnseenPurchasesGroup
  markPurchasesSeen
  customUnseenPurchVersion
  removeCustomUnseenPurchHandler
  addCustomUnseenPurchHandler
  hasActiveCustomUnseenView = Computed(@() customUnseenData.value != null)
  delayUnseedPurchaseShow = delayShow
  isShowUnseenDelayed = isShowDelayed
  skipUnseenMessageAnimOnce
  isUnseenGoodsVisible
  unseenPurchaseUnitPlateKey
}