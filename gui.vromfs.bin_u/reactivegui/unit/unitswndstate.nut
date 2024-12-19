from "%globalsDarg/darg_library.nut" import *
let { setHangarUnit } = require("hangarUnit.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { allUnitsCfg, myUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { sortUnits } = require("%rGui/unit/unitUtils.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")


let availableUnitsList = Computed(@() allUnitsCfg.value
  .filter(@(u) (!u?.isHidden && u.name in releasedUnits.get()) || u.name in myUnits.value)
  .map(@(u, id) myUnits.value?[id] ?? u)
  .values()
  .sort(sortUnits))

let sizePlatoon = Computed(@() (availableUnitsList.value?[0].platoonUnits ?? []).len())

let curSelectedUnit = Watched(null)
let curUnitName = Computed(@() curUnit.value?.name)

curSelectedUnit.subscribe(function(unitId) {
  if (unitId != null)
    setHangarUnit(unitId)
})

curCampaign.subscribe(function(_) {
  if (curSelectedUnit.value != null)
    curSelectedUnit.set(curUnitName.value)
})

curUnitName.subscribe(function(v) {
  if (v != null && curSelectedUnit.value != null)
    curSelectedUnit.set(v)
})

return {
  curSelectedUnit
  curUnitName
  availableUnitsList
  sizePlatoon
}
