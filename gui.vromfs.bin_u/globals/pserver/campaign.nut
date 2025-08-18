let { Computed } = require("frp")
let { serverConfigs } = require("servConfigs.nut")
let servProfile = require("servProfile.nut")
let { set_current_campaign } = require("pServerApi.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { resetTimeout } = require("dagor.workcycle")

let defaultCampaign = "tanks"

let campaignStatsRemap = {
  ships_new = "ships"
}

let selectedCampaign = sharedWatched("selectedCampaign", @() null) 
let campaignsLevelInfo = Computed(@()(servProfile.get()?.levelInfo ?? {}))
let savedCampaign = Computed(@() campaignsLevelInfo.get().findindex(@(i) i?.isCurrent ?? false)) 
let isAnyCampaignSelected = Computed(@() (selectedCampaign.get() ?? savedCampaign.get()) != null)

let campaignsList = Computed(@() serverConfigs.get()?.circuit.campaigns.available ?? [ defaultCampaign ])

let curCampaign = Computed(@()
  campaignsList.get().contains(selectedCampaign.get()) ? selectedCampaign.get()
    : campaignsList.get().contains(savedCampaign.get()) ? savedCampaign.get()
    : campaignsList.get()?[0])

let curCampaignBit = Computed(@() serverConfigs.get()?.campaignCfg[curCampaign.get()].bit ?? 0)

function setCampaign(campaign) {
  selectedCampaign(campaign)
  if (campaign != savedCampaign.get())
    set_current_campaign(campaign)
}

savedCampaign.subscribe(@(_)
  resetTimeout(0.1, @() savedCampaign.value == selectedCampaign.get() ? selectedCampaign(null) : null))

function chooseByCampaign(res, key, campaign) {
  if (key in res)
    res[key] = res[key]?[campaign]
}

function filterByCampaign(res, key, campaign) {
  if (key in res)
    res[key] = res[key].filter(@(o) o?.campaign == campaign)
}

function filterByCampaignMask(res, key, campaignBit) {
  if (key in res)
    res[key] = res[key].filter(@(o) (o.campaigns & campaignBit) != 0)
}

let campConfigs = Computed(function() {
  let campaign = curCampaign.get()
  let campaignBit = curCampaignBit.get()
  let res = clone (serverConfigs.get() ?? {})
  chooseByCampaign(res, "campaignCfg", campaign)
  chooseByCampaign(res, "playerLevels", campaign)
  chooseByCampaign(res, "playerLevelsInfo", campaign)
  chooseByCampaign(res, "playerLevelRewards", campaign)
  filterByCampaign(res, "clientMissionRewards", campaign)
  filterByCampaign(res, "allUnits", campaign)
  filterByCampaignMask(res, "allBoosters", campaignBit)
  filterByCampaignMask(res, "allItems", campaignBit)
  filterByCampaignMask(res, "infoPopups", campaignBit)
  return res
})

function newIfHasChanges(newList, prevList) {
  if (newList.len() != prevList.len())
    return newList

  foreach (name, val in newList)
    if (prevList?[name] != val)
      return newList
  return prevList
}

function filterByListTbl(res, prev, key, compareList) {
  if (key not in res)
    return
  let newList = res[key].filter(@(_, id) id in compareList)
  let prevList = prev?[key] ?? {}
  res[key] = newIfHasChanges(newList, prevList)
}

function chooseListByCampaignTbl(res, prev, key, campaign) {
  if (key not in res)
    return
  let newList = res[key]?[campaign] ?? {}
  let prevList = prev?[key] ?? {}
  res[key] = newIfHasChanges(newList, prevList)
}

function chooseOneByCampaignTbl(res, prev, key, campaign) {
  if (key not in res)
    return
  let newV = res[key]?[campaign]
  let prevV = prev?[key]
  res[key] = newV == prevV ? prevV : newV
}

let getCampaignStatsId = @(campaign) campaignStatsRemap?[campaign] ?? campaign

let campProfile = Computed(function(prev) {
  let res = clone (servProfile.get() ?? {})
  let campaign = curCampaign.get()
  let { allUnits = {}, allItems = {} } = campConfigs.get()
  filterByListTbl(res, prev, "units", allUnits)
  filterByListTbl(res, prev, "items", allItems)
  chooseListByCampaignTbl(res, prev, "receivedLvlRewards", campaign)
  chooseListByCampaignTbl(res, prev, "levelInfo", campaign)
  chooseListByCampaignTbl(res, prev, "sharedStatsByCampaign", getCampaignStatsId(campaign))
  chooseListByCampaignTbl(res, prev, "unitTreeNodes", campaign)
  chooseListByCampaignTbl(res, prev, "penalties", campaign)
  chooseOneByCampaignTbl(res, prev, "activeOffers", campaign)
  chooseOneByCampaignTbl(res, prev, "campaignSlots", campaign)
  return res
})


let exportProfile = {
  units = {}
  items = {}
  levelInfo = {}
  lastBattles = {}
  premium = {}
  subscriptions = {}
  purchasesCount = {}
  todayPurchasesCount = {}
  receivedLvlRewards = {}
  receivedMissionRewards = {}
  receivedSchRewards = {}
  sharedStats = {}
  sharedStatsByCampaign = {}
  unseenPurchases = {}
  activeOffers = null
  abTests = {}
  decorators = {}
  blueprints = {}
  goodsLimitReset = {}
  lootboxes = {}
}.map(@(value, key) Computed(@() campProfile.get()?[key] ?? value))

return exportProfile.__update({
  isProfileReceived = Computed(@() servProfile.get().len() > 0)
  firstLoginTime = Computed(@() servProfile.get()?.sharedStats.firstLoginTime ?? 0)
  campaignsLevelInfo
  curCampaign
  defaultCampaign
  setCampaign
  campaignsList
  isAnyCampaignSelected
  campConfigs
  campProfile
  isCampaignWithUnitsResearch = Computed(@() curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
  getCampaignStatsId
})
