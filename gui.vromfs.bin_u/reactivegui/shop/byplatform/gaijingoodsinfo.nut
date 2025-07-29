from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { requestData, createGuidsRequestParams } = require("%rGui/shop/httpRequest.nut")


const REPEAT_ON_ERROR_SEC = 60
const NO_ANSWER_TIMEOUT_SEC = 60
const AUTO_UPDATE_TIME_SEC = 3600

let isGoodsRequested = hardPersistWatched("goodsGaijin.isGoodsRequested", false)
let allGuids = hardPersistWatched("goodsGaijin.allGuids", {})
let goodsInfo = hardPersistWatched("goodsGaijin.goodsInfo", {})
let lastError = hardPersistWatched("goodsGaijin.lastError", null)
let lastUpdateTime = hardPersistWatched("goodsGaijin.lastUpdateTime", 0)
let needForceUpdate = Watched(false)
let needRetry = Computed(@() lastError.value != null && !isInBattle.get() && !isGoodsRequested.value)

let resetRequestedFlag = @() isGoodsRequested(false)
isGoodsRequested.subscribe(@(_) resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag))
if (isGoodsRequested.value)
  resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag)

let guidsForRequest = keepref(Computed(function(prev) {
  if (!isAuthorized.value)
    return []
  let res = allGuids.value.filter(@(_, guid) needForceUpdate.value || (guid not in goodsInfo.value))
    .keys()
  return isEqual(prev, res) ? prev : res
}))

function refreshAvailableGuids() {
  if (guidsForRequest.value.len() == 0)
    return
  logG("requestData: ", guidsForRequest.value)
  isGoodsRequested(true)
  requestData(
    "https://api.gaijinent.com/item_info.php",
    createGuidsRequestParams(guidsForRequest.value),
    function(data) {
      isGoodsRequested(false)
      lastError(null)
      lastUpdateTime(serverTime.get())
      let list = data?.items
      if (type(list) == "table" && list.len() > 0)
        goodsInfo.mutate(@(v) v.__update(list))
    },
    function(errData) {
      isGoodsRequested(false)
      lastError(errData)
    }
  )
}

guidsForRequest.subscribe(@(_) deferOnce(refreshAvailableGuids))
needRetry.subscribe(@(v) v ? resetTimeout(REPEAT_ON_ERROR_SEC, refreshAvailableGuids)
  : clearTimer(refreshAvailableGuids))
if (needRetry.value)
  resetTimeout(REPEAT_ON_ERROR_SEC, refreshAvailableGuids)
else if (goodsInfo.value.len() == 0)
  refreshAvailableGuids()

let forceUpdateAllGuids = @() needForceUpdate(true)
function startAutoUpdateTimer() {
  needForceUpdate(false)
  if (isInBattle.get() || lastUpdateTime.value <= 0)
    clearTimer(forceUpdateAllGuids)
  else
    resetTimeout(max(0.1, lastUpdateTime.value + AUTO_UPDATE_TIME_SEC - serverTime.get()), forceUpdateAllGuids)
}
startAutoUpdateTimer()
lastUpdateTime.subscribe(@(_) startAutoUpdateTimer())
isInBattle.subscribe(@(_) startAutoUpdateTimer())

function addGoodsInfoGuids(guids) {
  let newGuids = clone allGuids.value
  foreach(guid in guids)
    newGuids[guid] <- true
  if (newGuids.len() != allGuids.value.len())
    allGuids(newGuids)
}

let addGoodsInfoGuid = @(guid) guid in allGuids.value ? null
  : allGuids.mutate(@(v) v[guid] <- true)

return {
  addGoodsInfoGuids
  addGoodsInfoGuid
  goodsInfo
}