from "%globalsDarg/darg_library.nut" import *
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { sortUnits } = require("%rGui/unit/unitUtils.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")


let availableUnitsList = Computed(@() campUnitsCfg.get()
  .filter(@(u) (!u?.isHidden && u.name in releasedUnits.get()) || u.name in campMyUnits.get())
  .map(@(u, id) campMyUnits.get()?[id] ?? u)
  .values()
  .sort(sortUnits))

let sizePlatoon = Computed(@() (availableUnitsList.get()?[0].platoonUnits ?? []).len())

let curSelectedUnit = Watched(null)
let curUnitName = Computed(@() curUnit.get()?.name)

curSelectedUnit.subscribe(function(unitId) {
  if (unitId != null)
    setHangarUnit(unitId)
})

curCampaign.subscribe(function(_) {
  if (curSelectedUnit.get() != null)
    curSelectedUnit.set(curUnitName.get())
})

return {
  curSelectedUnit
  curUnitName
  availableUnitsList
  sizePlatoon
}
