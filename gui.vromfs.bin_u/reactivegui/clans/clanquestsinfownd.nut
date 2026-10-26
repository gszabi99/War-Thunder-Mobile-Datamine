from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import G_BLUEPRINT, G_UNIT, G_PRIZE_TICKET
from "%rGui/clans/clanQuestsState.nut" import clanProgressCfg
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader
from "%rGui/rewards/rewardViewInfo.nut" import mkViewInfo
from "%rGui/shop/unseenPurchaseAddMessage.nut" import mkBlueprintPlate, mkUnitPlate, arrowIcon
from "%rGui/style/stdColors.nut" import commonTextColor


const WND_UID = "clanQuestsInfoWnd"
const wndPadding = hdpx(60)
const textWidth = hdpx(1000)

let clanUnitNames = Computed(function() {
  let { prizeTicketsCfg = {}, allUnits = {} } = serverConfigs.get()
  let names = {}
  foreach (stage in clanProgressCfg.get()?.stages ?? [])
    foreach (goods in stage.rewards)
      foreach (variant in goods.gType == G_PRIZE_TICKET ? (prizeTicketsCfg?[goods.id].variants ?? []) : [[goods]])
        foreach (r in variant)
          if (r.gType == G_BLUEPRINT)
            names[r.id] <- true
  let campaign = curCampaign.get()
  let all = names.keys().sort()
  let campaignNames = all.filter(@(name) allUnits?[name].campaign == campaign)
  return campaignNames.len() > 0 ? campaignNames : all
})

let mkText = @(text) {
  size = [textWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = commonTextColor
  halign = ALIGN_CENTER
  text
}.__update(fontSmall)

let mkBlueprintsToUnitRow = @(unitName, targetCount, available) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(70)
  children = [
    mkBlueprintPlate(mkViewInfo(unitName, G_BLUEPRINT, targetCount), available)
    arrowIcon
    mkUnitPlate(mkViewInfo(unitName, G_UNIT))
  ]
}

let blueprintsToUnitRows = @() {
  watch = [clanUnitNames, serverConfigs, servProfile]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = clanUnitNames.get().map(@(name) mkBlueprintsToUnitRow(name,
    serverConfigs.get()?.allBlueprints[name].targetCount ?? 1, servProfile.get()?.blueprints[name] ?? 0))
}

let openClanQuestsInfoWnd = @() addModalWindowWithHeader(WND_UID,
  loc("clan/quests/getClanVehicles"),
  {
    padding = wndPadding
    flow = FLOW_VERTICAL
    gap = hdpx(40)
    halign = ALIGN_CENTER
    children = [
      mkText(loc("clan/quests/clanBlueprintsHint"))
      blueprintsToUnitRows
      mkText(loc("clan/quests/clanBlueprintsUpgradeHint"))
    ]
  })

return { openClanQuestsInfoWnd }
