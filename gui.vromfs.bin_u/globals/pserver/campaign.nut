
let { Computed } = require("frp")
let { serverConfigs } = require("servConfigs.nut")
let servProfile = require("servProfile.nut")
let { set_current_campaign } = require("pServerApi.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { setTimeout } = require("dagor.workcycle")

let defaultCampaign = "tanks"

let selectedCampaign = sharedWatched("selectedCampaign", @() null) //selectedByPlayer
let savedCampaign = Computed(@() (servProfile.value?.levelInfo ?? {}).findindex(@(i) i?.isCurrent ?? false)) //saved on pServer
let isAnyCampaignSelected = Computed(@() (selectedCampaign.value ?? savedCampaign.value) != null)

let campaignsList = Computed(@() serverConfigs.value?.circuit.campaigns.available ?? [ defaultCampaign ])

let curCampaign = Computed(@()
  campaignsList.value.contains(selectedCampaign.value) ? selectedCampaign.value
    : campaignsList.value.contains(savedCampaign.value) ? savedCampaign.value
    : campaignsList.value?[0])

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

let campConfigs = Computed(function() {
  let campaign = curCampaign.value
  let res = clone (serverConfigs.value ?? {})
  chooseByCampaign(res, "playerLevels", campaign)
  chooseByCampaign(res, "playerLevelsInfo", campaign)
  chooseByCampaign(res, "playerLevelRewards", campaign)
  filterByCampaign(res, "clientMissionRewards", campaign)
  filterByCampaign(res, "allUnits", campaign)
  filterByCampaign(res, "allItems", campaign)
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

function filterByCampaignTbl(res, prev, key, campaign, compareList) {
  if (key not in res)
    return
  let newList = res[key].filter(@(_, id) compareList?[id].campaign == campaign)
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

let campProfile = Computed(function(prev) {
  let res = clone (servProfile.value ?? {})
  let campaign = curCampaign.value
  let { allUnits = {}, allItems = {} } = campConfigs.value
  filterByCampaignTbl(res, prev, "units", campaign, allUnits)
  filterByCampaignTbl(res, prev, "items", campaign, allItems)
  chooseListByCampaignTbl(res, prev, "receivedLevelsRewards", campaign)
  chooseListByCampaignTbl(res, prev, "levelInfo", campaign)
  chooseListByCampaignTbl(res, prev, "sharedStatsByCampaign", campaign)
  chooseOneByCampaignTbl(res, prev, "activeOffers", campaign)
  return res
})


let exportProfile = {
  units = {}
  items = {}
  levelInfo = {}
  lastBattles = {}
  premium = {}
  purchasesCount = {}
  receivedLevelsRewards = {}
  receivedMissionRewards = {}
  receivedSchRewards = {}
  sharedStats = {}
  sharedStatsByCampaign = {}
  unseenPurchases = {}
  activeOffers = null
  abTests = {}
  decorators = {}
}.map(@(value, key) Computed(@() campProfile.value?[key] ?? value))

return exportProfile.__update({
  isProfileReceived = Computed(@() servProfile.value.len() > 0)
  curCampaign
  defaultCampaign
  setCampaign
  campaignsList
  isAnyCampaignSelected
  campConfigs
  campProfile
})
