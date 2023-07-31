from "%globalsDarg/darg_library.nut" import *
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")


let curUnitMRankRange = Computed(function() {
  if (!curUnit.value)
    return null
  let isMaxMRank = !allUnitsCfg.value.findvalue(@(unitFromList)
    unitFromList.mRank > curUnit.value.mRank)
  let minMRank = curUnit.value.mRank == 1 ? 1 : curUnit.value.mRank - 1
  let maxMRank = isMaxMRank ? curUnit.value.mRank : curUnit.value.mRank + 1
  return { minMRank, maxMRank }
})

return {
    curUnitMRankRange
}