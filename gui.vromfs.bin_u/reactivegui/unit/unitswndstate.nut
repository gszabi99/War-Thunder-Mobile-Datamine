from "%globalsDarg/darg_library.nut" import *
let { setHangarUnit } = require("hangarUnit.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { sortUnits } = require("%rGui/unit/unitUtils.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")


let availableUnitsList = Computed(@() campUnitsCfg.get()
  .filter(@(u) (!u?.isHidden && u.name in releasedUnits.get()) || u.name in campMyUnits.get())
  .map(@(u, id) campMyUnits.get()?[id] ?? u)
  .values()
  .sort(sortUnits))

let sizePlatoon = Computed(@() (availableUnitsList.value?[0].platoonUnits ?? []).len())

let curSelectedUnit = Watched(null)
let curUnitName = Computed(@() curUnit.get()?.name)

curSelectedUnit.subscribe(function(unitId) {
  if (unitId != null)
    setHangarUnit(unitId)
})

curCampaign.subscribe(function(_) {
  if (curSelectedUnit.value != null)
    curSelectedUnit.set(curUnitName.value)
})

curUnitName.subscribe(function(v) {
  if (v != null && curSelectedUnit.get() == null)
    curSelectedUnit.set(v)
})

return {
  curSelectedUnit
  curUnitName
  availableUnitsList
  sizePlatoon
}
