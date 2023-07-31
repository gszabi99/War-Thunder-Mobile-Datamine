from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { register_command } = require("console")
let { dfAnimBottomCenter } = require("%rGui/style/unitDelayAnims.nut")
let { EII_TOOLKIT, EII_EXTINGUISHER, EII_MEDICALKIT, EII_SMOKE_SCREEN, EII_SMOKE_GRENADE,
  EII_SPECIAL_UNIT, EII_SPECIAL_UNIT_2, EII_ARTILLERY_TARGET } = require("%rGui/hud/weaponsButtonsConfig.nut")
let { touchButtonMargin } = require("%rGui/hud/hudTouchButtonStyle.nut")
let weaponsButtonsView = require("%rGui/hud/weaponsButtonsView.nut")
let { actionBarItems, curActionBarTypes, startActionBarUpdate, stopActionBarUpdate
} = require("actionBarState.nut")
let { unitType, isUnitDelayed } = require("%rGui/hudState.nut")


let debugButtons = mkWatched(persist, "debugButtons", 0)

let shipButtons = [EII_TOOLKIT, EII_SMOKE_SCREEN, EII_SMOKE_GRENADE]
let actionBarButtons = {
  [SHIP] = shipButtons,
  [SUBMARINE] = shipButtons,
  [TANK] = [EII_SPECIAL_UNIT, EII_SPECIAL_UNIT_2, EII_ARTILLERY_TARGET,
    EII_SMOKE_SCREEN, EII_SMOKE_GRENADE, EII_TOOLKIT, EII_EXTINGUISHER
  ],
  [AIR] = [],
}

let alwaysShow = [EII_TOOLKIT, EII_MEDICALKIT, EII_EXTINGUISHER]
  .reduce(function(res, v) {
    res[v] <- true
    return res
  }, {})

let incorrectUnitType = actionBarButtons.findindex(@(list) null != list.findvalue(@(a) "actionType" not in a))
assert(null == incorrectUnitType, $"ActionBar Cfg for unitType {incorrectUnitType} without actionType")

let debugActionItem = { count = 1, shortcutIdx = -1, cooldownTime = 10.0, selected = false, active = false }

let function actionBar() {
  local add = debugButtons.value
  return {
    watch = [curActionBarTypes, debugButtons, unitType, isUnitDelayed]
    key = actionBarItems
    hplace = ALIGN_RIGHT
    onAttach = @() startActionBarUpdate("mainActionBar")
    onDetach = @() stopActionBarUpdate("mainActionBar")

    flow = FLOW_HORIZONTAL
    gap = touchButtonMargin
    children = isUnitDelayed.value ? null
      : (actionBarButtons?[unitType.value] ?? []).map(function(config) {
          let { actionType } = config
          local dbgItem = null
          if (actionType not in curActionBarTypes.value && config not in alwaysShow) {
            if (add-- <= 0)
              return null
            dbgItem = debugActionItem
          }
          let actionItem = Computed(@() actionBarItems.value?[actionType] ?? dbgItem)
          return @() {
            watch = actionItem
            children = weaponsButtonsView[config.mkButtonFunction](config, actionItem.value)
          }
        })

    transform = {}
    animations = dfAnimBottomCenter
  }
}

register_command(function() {
  debugButtons(debugButtons.value > 0 ? 0 : 100)
  log("is show all actionbar buttons = ", debugButtons.value > 0)
}, "debug.showAllActionBarButtons")
register_command(function(count) {
  debugButtons(count)
  log($"show {debugButtons.value} more actionbar buttons")
}, "debug.showMoreActionBarButtons")

return actionBar
