let { Computed } = require("frp")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")


let allMyBattleUnits = Computed(function() {
  let res = {}
  if (curCampaignSlotUnits.get() != null)
    curCampaignSlotUnits.get().each(@(name) res[name] <- true)
  else if (curUnit.value != null)
    res[curUnit.value.name] <- true
  return res
})

return {
  allMyBattleUnits
}