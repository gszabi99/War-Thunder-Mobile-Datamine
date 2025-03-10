from "%globalsDarg/darg_library.nut" import *
let { getActionBarItems } = require("hudActionBar")
let { clearTimer, setInterval } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { getActionType, AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON } = require("actionType.nut")

let actionBar = Watched([])
let actionBarUpdaters = Watched({})
let needUpdate = keepref(Computed(@() actionBarUpdaters.value.len() > 0))

let emptyActionItem = {count = 0, available = false, shortcutIdx = -1, weaponName = "", countEx = 0}

function actionIsEqual(a, b) {
  if (type(a) != type(b))
    return false
  if (type(a) != "table")
    return a == b
  foreach (k, v in a)
    if (k != "cooldown" && v != b?[k])
      return false
  return true
}

let actionBarByType = @(ab) ab.reduce(function(res, a) {
  let aType = getActionType(a)
  if (aType != null)
    res[aType] <- a
  return res
}, {})

local actionBarItems = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = {}
  let cur = actionBarByType(actionBar.value)
  let res = {}
  local hasChanges = prev.len() != cur.len()
  foreach (aType, action in cur) {
    let prevAction = prev?[aType]
    let isChanged = !actionIsEqual(action, prevAction)
    res[aType] <- isChanged ? action : prevAction
    hasChanges = hasChanges || isChanged
  }
  return hasChanges ? res : prev
})

let curActionBarTypes = Computed(function(prev) {
  let types = actionBarItems.value.map(@(_) true)
  return isEqual(prev, types) ? prev : types
})

let updateActionBar = @() actionBar(getActionBarItems())
let updateActionBarDelayed = @() gui_scene.resetTimeout(0.1, @() updateActionBar())

let primaryAction = Computed(@() actionBarItems.value?[AB_PRIMARY_WEAPON])
let secondaryAction = keepref(Computed(@() actionBarItems.value?[AB_SECONDARY_WEAPON]))

let startActionBarUpdate = @(id) id in actionBarUpdaters.value ? null
  : actionBarUpdaters.mutate(@(v) v[id] <- true)
let stopActionBarUpdate = @(id) id not in actionBarUpdaters.value ? null
  : actionBarUpdaters.mutate(@(v) v.$rawdelete(id))

needUpdate.subscribe(function(v) {
  clearTimer(updateActionBar)
  if (v) {
    updateActionBar()
    setInterval(0.3, updateActionBar)
  }
})

return {
  updateActionBarDelayed
  startActionBarUpdate
  stopActionBarUpdate
  actionBarItems
  curActionBarTypes
  primaryAction
  secondaryAction
  emptyActionItem
}
