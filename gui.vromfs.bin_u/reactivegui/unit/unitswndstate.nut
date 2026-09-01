from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campUnitsCfg, campMyUnits, curUnit
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%rGui/unit/hangarUnit.nut" import setHangarUnit


let visibleUnitsList = Computed(@() campUnitsCfg.get()
  .filter(@(u) (!u?.isHidden && u.name not in unreleasedUnits.get()) || u.name in campMyUnits.get()))

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
  visibleUnitsList
}
