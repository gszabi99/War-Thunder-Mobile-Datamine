from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "dagor.workcycle" import deferOnce
from "contentUpdater" import get_total_size_async
from "%appGlobals/updater/addonsState.nut" import isAddonsAndUnitsInfoActual, unitSizes
from "%appGlobals/updater/addons.nut" import toMB
let logA = log_with_prefix("[ADDONS_INFO] ")


let DL_SIZE_EVENT_ID = "onDlSizeUpdate"

let dlSizes = Watched({})

isAddonsAndUnitsInfoActual.subscribe(@(v) v || dlSizes.get().len() == 0 ? null : dlSizes.set({}))

function onGetDlSize(evt) {
  foreach (id, size in evt)
    logA($"Receive total size id = {id}: {toMB(size)}MB")
  dlSizes.set(dlSizes.get().__merge(evt))
}
eventbus_subscribe(DL_SIZE_EVENT_ID, onGetDlSize)

function mkDlSizeComp(addons, units, logPrefix = "") {
  if (units.len() + addons.len() == 0)
    return Watched(0)
  if (units.len() == 1 && addons.len() == 0)
    return Computed(@() unitSizes.get()?[units[0]] ?? -1)

  let id = (addons.reduce(@(res, u) res + u.hash(), 0) + units.reduce(@(res, u) res + u.hash(), 0))
    .tostring()
  function refresh() {
    logA($"{logPrefix}Request total size (total addons: {addons.len()}, total units: {units.len()}, id = {id})")
    get_total_size_async(DL_SIZE_EVENT_ID, id, addons, units)
  }
  if (id not in dlSizes.get())
    refresh()

  let res = Computed(@() dlSizes.get()?[id] ?? -1)
  res.subscribe(function(_) {
    if (id not in dlSizes.get())
      deferOnce(refresh)
  })
  return res
}

function mkDlSizeCompByTablesWatch(dlInfo, logPrefix = "") {
  let id = Computed(function() {
    let { addons = {}, units = {} } = dlInfo.get()
    if (addons.len() == 0 && units.len() <= 1)
      return null
    return (addons.reduce(@(res, _, a) res + a.hash(), 0) + units.reduce(@(res, _, u) res + u.hash(), 0))
      .tostring()
  })
  let res = Computed(function() {
    let { addons = {}, units = {} } = dlInfo.get()
    if (units.len() + addons.len() == 0)
      return 0
    if (units.len() == 1 && addons.len() == 0)
      return unitSizes.get()?[units.findindex(@(_) true)] ?? -1
    return dlSizes.get()?[id.get()] ?? -1
  })

  function refresh() {
    if (id.get() == null)
      return
    logA($"{logPrefix}Request total size (total addons: {dlInfo.get()?.addons.len()}, total units: {dlInfo.get()?.units.len()}, id = {id.get()})")
    get_total_size_async(DL_SIZE_EVENT_ID, id.get(), dlInfo.get()?.addons.keys() ?? [], dlInfo.get()?.units.keys() ?? [])
  }
  if (id.get() not in dlSizes.get())
    refresh()
  res.subscribe(function(_) {
    if (id.get() not in dlSizes.get())
      deferOnce(refresh)
  })
  id.subscribe(function(v) {
    if (v not in dlSizes.get())
      deferOnce(refresh)
  })
  return res
}

return {
  mkDlSizeComp
  mkDlSizeCompByTablesWatch
}