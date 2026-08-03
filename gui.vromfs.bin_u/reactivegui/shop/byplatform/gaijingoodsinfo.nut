from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { requestData, createGuidsRequestParams } = require("%rGui/shop/httpRequest.nut")
let { getCurCircuitOverride } = require("%appGlobals/curCircuitOverride.nut")

let REPEAT_ON_ERROR_SEC = [60, 120, 240, 600, 900, 1200]
const NO_ANSWER_TIMEOUT_SEC = 60
const AUTO_UPDATE_TIME_SEC = 3600

let isGoodsRequested = hardPersistWatched("goodsGaijin.isGoodsRequested", false)
let allGuids = hardPersistWatched("goodsGaijin.allGuids", {})
let goodsInfo = hardPersistWatched("goodsGaijin.goodsInfo", {})
let lastError = hardPersistWatched("goodsGaijin.lastError", null)
let lastUpdateTime = hardPersistWatched("goodsGaijin.lastUpdateTime", 0)
let retryTimeIdx = hardPersistWatched("goodsGaijin.retryTimeIdx", -1)
let needForceUpdate = Watched(false)
let hasInfoAboutAllGuids = Computed(@() null == allGuids.get().findindex(@(_, guid) guid not in goodsInfo.get()))
let needRetryTime = keepref(Computed(@()
  isInBattle.get() || isGoodsRequested.get() || lastError.get() == null || hasInfoAboutAllGuids.get() ? 0 
    : (REPEAT_ON_ERROR_SEC?[min(retryTimeIdx.get(), REPEAT_ON_ERROR_SEC.len() - 1)] ?? 0)))

lastError.subscribe(@(v) retryTimeIdx.set(v == null ? -1 : retryTimeIdx.get() + 1))

let resetRequestedFlag = @() isGoodsRequested.set(false)
isGoodsRequested.subscribe(@(_) resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag))
if (isGoodsRequested.get())
  resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag)

let guidsForRequest = keepref(Computed(function(prev) {
  if (!isAuthorized.get())
    return []
  let res = allGuids.get().filter(@(_, guid) needForceUpdate.get() || (guid not in goodsInfo.get()))
    .keys()
  return isEqual(prev, res) ? prev : res
}))

function refreshAvailableGuids() {
  if (guidsForRequest.get().len() == 0)
    return
  logG("requestData: ", guidsForRequest.get())
  isGoodsRequested.set(true)
  requestData(
    getCurCircuitOverride("goodsInfoURL","https://api.gaijinent.com/item_info.php"),
    createGuidsRequestParams(guidsForRequest.get()),
    function(data) {
      isGoodsRequested.set(false)
      lastError.set(null)
      lastUpdateTime.set(serverTime.get())
      let list = data?.items
      if (type(list) == "table" && list.len() > 0)
        goodsInfo.mutate(@(v) v.__update(list))
    },
    function(errData) {
      isGoodsRequested.set(false)
      lastError.set(errData)
    }
  )
}

guidsForRequest.subscribe(@(_) deferOnce(refreshAvailableGuids))
needRetryTime.subscribe(@(v) v > 0 ? resetTimeout(v, refreshAvailableGuids)
  : clearTimer(refreshAvailableGuids))
if (needRetryTime.get() > 0)
  resetTimeout(needRetryTime.get(), refreshAvailableGuids)
else if (goodsInfo.get().len() == 0)
  refreshAvailableGuids()

let forceUpdateAllGuids = @() needForceUpdate.set(true)
function startAutoUpdateTimer() {
  needForceUpdate.set(false)
  if (isInBattle.get() || lastUpdateTime.get() <= 0)
    clearTimer(forceUpdateAllGuids)
  else
    resetTimeout(max(0.1, lastUpdateTime.get() + AUTO_UPDATE_TIME_SEC - serverTime.get()), forceUpdateAllGuids)
}
startAutoUpdateTimer()
lastUpdateTime.subscribe(@(_) startAutoUpdateTimer())
isInBattle.subscribe(@(_) startAutoUpdateTimer())

function addGoodsInfoGuids(guids) {
  let newGuids = clone allGuids.get()
  foreach(guid in guids)
    newGuids[guid] <- true
  if (newGuids.len() != allGuids.get().len())
    allGuids.set(newGuids)
}

let addGoodsInfoGuid = @(guid) guid in allGuids.get() ? null
  : allGuids.mutate(@(v) v[guid] <- true)

return {
  addGoodsInfoGuids
  addGoodsInfoGuid
  goodsInfo
}