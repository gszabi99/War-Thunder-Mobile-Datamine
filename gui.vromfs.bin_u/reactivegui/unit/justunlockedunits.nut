from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { canBuyUnitsStatus, US_OWN, US_CAN_BUY } = require("%appGlobals/unitsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isUnitsWndAttached } = require("%rGui/mainMenu/mainMenuState.nut")


let UNLOCK_DELAY = 1.8
let UNLOCK_STEP = 1.5

let justUnlockedUnits = Watched(null)
let justBoughtUnits = Watched(null)
let isJustUnlockedUnitsOutdated = Watched(false)
let hasJustUnlockedUnitsAnimation = Computed(@() !isJustUnlockedUnitsOutdated.value
  && (justUnlockedUnits.value?.len() ?? 0) != 0)

local prevCanBuyUnitsStatus = null

let setOnlyNew = @(watch, cur) isEqual(cur, watch.get()) ? null : watch.set(cur)

function updateJustUnlockedUnits() {
  if (!isLoggedIn.get())
    return
  let unitsStatus = canBuyUnitsStatus.get()
  let prev = prevCanBuyUnitsStatus
  prevCanBuyUnitsStatus = unitsStatus
  if (prev == null || prev == unitsStatus)
    return

  let unlockedUnits = clone (justUnlockedUnits.get() ?? {})
  let boughtUnits = clone (justBoughtUnits.get() ?? {})

  foreach(unit, status in unitsStatus)
    if (prev?[unit] != null && prev[unit] != status) {
      if (status == US_OWN)
        boughtUnits[unit] <- UNLOCK_DELAY
      else if (status == US_CAN_BUY
          && unit not in serverConfigs.get()?.allBlueprints
          && (serverConfigs.get()?.unitResearchExp[unit] ?? 0) == 0)
        unlockedUnits[unit] <- UNLOCK_DELAY + UNLOCK_STEP
    }

  if (boughtUnits.len() == 0 && unlockedUnits.len() == 0)
    return null

  if (unlockedUnits.len() == 0)
    justUnlockedUnits(null)
  else
    setOnlyNew(justUnlockedUnits, unlockedUnits.__merge(boughtUnits))

  setOnlyNew(justBoughtUnits, boughtUnits)
}

function resetJustUnlockedUnits() {
  prevCanBuyUnitsStatus = null
  justUnlockedUnits.set(null)
  justBoughtUnits.set(null)
  isJustUnlockedUnitsOutdated.set(false)
  updateJustUnlockedUnits()
}

updateJustUnlockedUnits()
canBuyUnitsStatus.subscribe(@(_) updateJustUnlockedUnits())
curCampaign.subscribe(@(_) resetJustUnlockedUnits())
isLoggedIn.subscribe(@(_) resetJustUnlockedUnits())

let deleteJustUnlockedUnit = @(name) name not in justUnlockedUnits.value ? null
  : justUnlockedUnits.mutate(@(v) v.$rawdelete(name))
let deleteJustBoughtUnit = @(name) name not in justBoughtUnits.value ? null
  : justBoughtUnits.mutate(@(v) v.$rawdelete(name))

let restartOutdateTimer = @() resetTimeout(15.0, @() isJustUnlockedUnitsOutdated(true))
if (hasJustUnlockedUnitsAnimation.value)
  restartOutdateTimer()
justUnlockedUnits.subscribe(function(v) {
  isJustUnlockedUnitsOutdated(false)
  if (v)
    restartOutdateTimer()
})
isUnitsWndAttached.subscribe(@(v) v ? null : isJustUnlockedUnitsOutdated(true))

return {
  justBoughtUnits
  justUnlockedUnits
  hasJustUnlockedUnitsAnimation
  deleteJustUnlockedUnit
  deleteJustBoughtUnit
  UNLOCK_DELAY
}
