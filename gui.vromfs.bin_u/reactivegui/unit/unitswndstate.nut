from "%globalsDarg/darg_library.nut" import *
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")


let visibleUnitsList = Computed(@() campUnitsCfg.get()
  .filter(@(u) (!u?.isHidden && u.name not in unreleasedUnits.get()) || u.name in campMyUnits.get()))

let sizePlatoon = Computed(@() visibleUnitsList.get().findvalue(@(_) true)?.platoonUnits.len() ?? 0)

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
  sizePlatoon
}
