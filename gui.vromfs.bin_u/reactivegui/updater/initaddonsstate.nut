from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADDONS_INFO] ")
let { eventbus_subscribe } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { get_addons_size_async, get_units_size_async, get_all_addons_from_yup_async
} = require("contentUpdater")
let { get_unittags_blk } = require("blkGetters")
let { ndbWrite } = require("nestdb")
let { isEqual } = require("%sqstd/underscore.nut")
let { eachBlock } = require("%sqstd/datablock.nut")
let { addonsSizes, isAddonsSizesActual, unitSizes, isUnitSizesActual, yupAddons, allAddons,
  UNIT_SIZES_NDB, UNIT_SIZES_ACTUAL_NDB, UNIT_SIZES_EVENT_ID
} = require("%appGlobals/updater/addonsState.nut")
let { isGameUpdatedOnLogin, isReadyToFullLoad } = require("%appGlobals/loginState.nut")


let MB = 1 << 20
let toMB = @(b) (b + (MB / 2)) / MB

let needRequestAddonsSizes = keepref(Computed(@() isReadyToFullLoad.get() && !isAddonsSizesActual.get() && yupAddons.get() != null))

function onGetYupAddons(evt) {
  let { addons = [] } = evt
  logA("Get yup addons: ", addons.len())
  let addonsTbl = {}
  foreach (a in addons)
    addonsTbl[a] <- true
  if ("ignore" in addonsTbl)
    addonsTbl.$rawdelete("ignore")
  yupAddons.set(addonsTbl)
}
eventbus_subscribe("getYupAddons", onGetYupAddons)
yupAddons.whiteListMutatorClosure(onGetYupAddons)

function requestYupAddons() {
  logA("Request yup addons")
  get_all_addons_from_yup_async("getYupAddons")
}
if (yupAddons.get() == null)
  requestYupAddons()


function onGetAddonsSizes(evt) {
  if (!isEqual(addonsSizes.get(), evt)) {
    addonsSizes.set(clone evt)

    local messageArr = [ "Get addons sizes:" ]
    if (DBGLEVEL > 0) {
      let addons = addonsSizes.get().keys().sort()
      let addonsCount = addons.len()
      for (local idx = 0; idx < addonsCount; idx += 5) {
        let chunk = addons.slice(idx, idx + 5)
        messageArr.append(", ".join(chunk.map(function(a) {
          let size = addonsSizes.get()[a]
          return $"{a}: {toMB(size)}MB ({size})"
        })))
      }
    }
    else
      messageArr.append($"Received {addonsSizes.get().len()} addons")
    logA("\n".join(messageArr))
  }
  else
    logA("Get addons sizes: unchanged")
  isAddonsSizesActual.set(true)
}
eventbus_subscribe("getAllAddonsSizesEvent", onGetAddonsSizes)
addonsSizes.whiteListMutatorClosure(onGetAddonsSizes)

function requestAddonsSizes() { 
  if (allAddons.get().len() == 0)
    return
  logA("Request addons sizes ", allAddons.get().len())
  get_addons_size_async("getAllAddonsSizesEvent", allAddons.get().keys())
}
if (needRequestAddonsSizes.get())
  requestAddonsSizes()
needRequestAddonsSizes.subscribe(@(v) v ? requestAddonsSizes() : null)


let unitsListCache = []
function getUnitsList() {
  if (unitsListCache.len() == 0) {
    if (!isReadyToFullLoad.get())
      logerr("Call get_unittags_blk() while not isReadyToFullLoad")
    eachBlock(get_unittags_blk(), @(blk) unitsListCache.append(blk.getBlockName()))
  }
  return unitsListCache
}

function onGetUnitsSizes(evt) {
  let prevSizes = unitSizes.get()
  let newSizes = evt.filter(@(v, k) v != prevSizes?[k])
  if (newSizes.len() > 0) {
    local messageArr = [ "Get units sizes:" ]
    if (DBGLEVEL > 0) {
      let names = newSizes.keys().sort()
      let total = newSizes.len()
      local minS = null
      local maxS = null
      for (local idx = 0; idx < total; idx += 5) {
        let chunk = names.slice(idx, idx + 5)
        messageArr.append(", ".join(chunk.map(function(n) {
          let size = newSizes[n]
          if (size == 0)
            return $"{n}: 0"
          minS = min(size, minS ?? size)
          maxS = max(size, maxS ?? size)
          return $"{n}: {toMB(size)}MB ({size})"
        })))
      }
      messageArr.append($"Min size = {toMB(minS ?? 0)}MB, max size = {toMB(maxS ?? 0)}MB")
    }
    else
      messageArr.append($"Received {newSizes.len()} unit sizes. {newSizes.reduce(@(res, v) v == 0 ? res + 1 : res, 0)} already downloaded")

    unitSizes.set(unitSizes.get().__merge(evt))
    ndbWrite(UNIT_SIZES_NDB, unitSizes.get())
    for (local i = 0; i < messageArr.len(); i += 10)
      logA("\n".join(messageArr.slice(i, i + 10)))
  }
  else
    logA("Get units sizes: unchanged")
  isUnitSizesActual.set(true)
}
eventbus_subscribe(UNIT_SIZES_EVENT_ID, onGetUnitsSizes)
unitSizes.whiteListMutatorClosure(onGetUnitsSizes)

let needRequestUnitSizes = keepref(Computed(@() isReadyToFullLoad.get() && !isUnitSizesActual.get()))
function requestUnitsSizes() { 
  let sizes = unitSizes.get()
  let list = (sizes.len() == 0 ? getUnitsList() : getUnitsList().filter(@(u) sizes?[u] != 0))
    .reduce(@(res, v) res.$rawset(v, [v]), {})
  logA("Request units sizes ", list.len())
  get_units_size_async(UNIT_SIZES_EVENT_ID, list)
}
if (needRequestUnitSizes.get())
  requestUnitsSizes()
needRequestUnitSizes.subscribe(function(v) {
  if (!v)
    return
  this_subscriber_call_may_take_up_to_usec(10 * get_slow_subscriber_threshold_usec())
  requestUnitsSizes()
})

isUnitSizesActual.subscribe(@(v) ndbWrite(UNIT_SIZES_ACTUAL_NDB, v))

isGameUpdatedOnLogin.subscribe(function(v) {
  if (!v)
    return
  isAddonsSizesActual.set(false)
  isUnitSizesActual.set(false)
})
