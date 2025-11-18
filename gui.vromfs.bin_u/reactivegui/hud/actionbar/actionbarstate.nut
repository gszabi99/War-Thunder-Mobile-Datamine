from "%globalsDarg/darg_library.nut" import *
let { getActionBarItems } = require("hudActionBar")
let { clearTimer, setInterval, resetTimeout } = require("dagor.workcycle")
let { get_mission_time } = require("mission")
let { isEqual } = require("%sqstd/underscore.nut")
let { getActionType, AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON } = require("%rGui/hud/actionBar/actionType.nut")

let actionBar = Watched([])
let actionBarUpdaters = Watched({})
let needUpdate = keepref(Computed(@() actionBarUpdaters.get().len() > 0))

let emptyActionItem = {count = 0, available = false, shortcutIdx = -1, weaponName = "", countEx = 0}
let actionItemsInCd = Watched({})

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
  let cur = actionBarByType(actionBar.get())
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
  let types = actionBarItems.get().map(@(_) true)
  return isEqual(prev, types) ? prev : types
})

let updateActionBar = @() actionBar.set(getActionBarItems())
let updateActionBarDelayed = @() gui_scene.resetTimeout(0.1, @() updateActionBar())

let primaryAction = Computed(@() actionBarItems.get()?[AB_PRIMARY_WEAPON])
let secondaryAction = keepref(Computed(@() actionBarItems.get()?[AB_SECONDARY_WEAPON]))

let startActionBarUpdate = @(id) id in actionBarUpdaters.get() ? null
  : actionBarUpdaters.mutate(@(v) v[id] <- true)
let stopActionBarUpdate = @(id) id not in actionBarUpdaters.get() ? null
  : actionBarUpdaters.mutate(@(v) v.$rawdelete(id))

needUpdate.subscribe(function(v) {
  clearTimer(updateActionBar)
  if (v) {
    updateActionBar()
    setInterval(0.3, updateActionBar)
  }
})

function updateActionsCd() {
  let cdActions = {}
  let t = get_mission_time()
  local nextCd = null
  foreach (aType, action in actionBarItems.get()) {
    let { cooldownEndTime = 0 } = action
    if (cooldownEndTime <= t)
      continue
    cdActions[aType] <- true
    nextCd = min(cooldownEndTime, nextCd ?? cooldownEndTime)
  }
  if (!isEqual(actionItemsInCd.get(), cdActions))
    actionItemsInCd.set(cdActions)
  let timeLeft = (nextCd ?? 0) - t
  if (timeLeft > 0)
    resetTimeout(timeLeft, updateActionsCd)
}
actionItemsInCd.whiteListMutatorClosure(updateActionsCd)
actionBarItems.subscribe(@(_) updateActionsCd())

return {
  updateActionBarDelayed
  startActionBarUpdate
  stopActionBarUpdate
  actionBarItems
  actionItemsInCd
  curActionBarTypes
  primaryAction
  secondaryAction
  emptyActionItem
}
