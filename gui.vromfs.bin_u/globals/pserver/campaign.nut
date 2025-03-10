let { Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let { serverConfigs } = require("servConfigs.nut")
let servProfile = require("servProfile.nut")
let { set_current_campaign } = require("pServerApi.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { setTimeout } = require("dagor.workcycle")

let defaultCampaign = "tanks"

let campaignStatsRemap = {
  ships_new = "ships"
}

let selectedCampaign = sharedWatched("selectedCampaign", @() null) //selectedByPlayer
let campaignsLevelInfo = Computed(@()(servProfile.get()?.levelInfo ?? {}))
let savedCampaign = Computed(@() campaignsLevelInfo.get().findindex(@(i) i?.isCurrent ?? false)) //saved on pServer
let isAnyCampaignSelected = Computed(@() (selectedCampaign.value ?? savedCampaign.value) != null)

let campaignsList = Computed(@() serverConfigs.value?.circuit.campaigns.available ?? [ defaultCampaign ])

let curCampaign = Computed(@()
  campaignsList.value.contains(selectedCampaign.value) ? selectedCampaign.value
    : campaignsList.value.contains(savedCampaign.value) ? savedCampaign.value
    : campaignsList.value?[0])

let curCampaignBit = Computed(@() serverConfigs.get()?.campaignCfg[curCampaign.get()].bit ?? 0)

function setCampaign(campaign) {
  selectedCampaign(campaign)
  if (campaign != savedCampaign.value)
    set_current_campaign(campaign)
}

savedCampaign.subscribe(@(_)
  setTimeout(0.1, @() savedCampaign.value == selectedCampaign.value ? selectedCampaign(null) : null))

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
}.map(@(value, key) Computed(@() campProfile.value?[key] ?? value))

let isCampaignWithSlots = Computed(@() (campConfigs.get()?.campaignCfg.totalSlots ?? 0) > 0)
let curCampaignSlots = Computed(@() isCampaignWithSlots.get() ? campProfile.get()?.campaignSlots : null)
let curCampaignSlotUnits = Computed(function(prev) {
  let res = curCampaignSlots.get()?.slots
    .map(@(s) s.name)
    .filter(@(v) v != "")
  return isEqual(res, prev) ? prev : res
})

return exportProfile.__update({
  isProfileReceived = Computed(@() servProfile.get().len() > 0)
  campaignsLevelInfo
  curCampaign
  defaultCampaign
  setCampaign
  campaignsList
  isAnyCampaignSelected
  campConfigs
  campProfile
  curCampaignSlots
  curCampaignSlotUnits
  isCampaignWithUnitsResearch = Computed(@() curCampaign.get() in serverConfigs.get()?.unitTreeNodes)
  isCampaignWithSlots
  getCampaignStatsId
})
