from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")

let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { add_slot_attributes, slotInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { balance, SLOT_EXP_TANKS, SLOT_EXP_AIR } = require("%appGlobals/currenciesState.nut")
let { selectedSlotIdx, maxSlotLevels } = require("%rGui/slotBar/slotBarState.nut")
let { selAttributes, curCategoryId, attrPresets,
  calcStatus, sumCost, MAX_AVAIL_STATUS
} = require("%rGui/attributes/attrState.nut")


let slotExpByCamp = {
  tanks_new = SLOT_EXP_TANKS
  air = SLOT_EXP_AIR
}

let isSlotAttrOpened = mkWatched(persist, "isSlotAttrOpened", false)
let isSlotAttrAttached = mkWatched(persist, "isSlotAttrAttached", false)
let isOpenedSlotExpWnd = mkWatched(persist, "isOpenedSlotExpWnd", false)
let isOpenedSlotResetWnd = mkWatched(persist, "isOpenedSlotResetWnd", false)
let resetSlotSelectionData = mkWatched(persist, "resetSlotSelectionData", null)

let SEEN_SLOT_ATTRIBUTES = "seenSlotAttributes"
let seenSlotAttributes = mkWatched(persist, SEEN_SLOT_ATTRIBUTES, {})

let attrSlotData = Computed(function() {
  let slot = curSlots.get()?[selectedSlotIdx.get()]
  return {
    slot
    preset = attrPresets.get()?[campConfigs.get()?.campaignCfg.slotAttrPreset] ?? []
  }
})

let slotUnitName = Computed(@() attrSlotData.get().slot?.name ?? "")
let slotAttributes = Computed(@() attrSlotData.get().slot?.attrLevels ?? {})
let slotLevel = Computed(@() attrSlotData.get().slot?.level ?? 0)
let slotLevelsToMax = Computed(@() (maxSlotLevels.get()?.len() ?? 0) - (attrSlotData.get().slot?.level ?? 0))

let slotLevelResetPrice = Computed(@() campConfigs.get()?.campaignCfg.slotLevelResetPrice)
let slotSkillsResetPrice = Computed(@() campConfigs.get()?.campaignCfg.slotSkillsResetPrice)
let isResetSlotLevelAllowed = Computed(@() (slotLevelResetPrice.get()?.price ?? 0) > 0 && slotLevel.get() > 0)
let isResetSlotSkillsAllowed = Computed(@() (slotSkillsResetPrice.get()?.price ?? 0) > 0
  && null != slotAttributes.get().findindex(@(c) null != c.findindex(@(a) a > 0))
  && slotLevelsToMax.get() > 0)

function resetAttrState() {
  selAttributes.set({})
  deferOnce(@() curCategoryId.set(attrSlotData.get().preset?[0].id))
}
resetAttrState()
slotUnitName.subscribe(@(_) resetAttrState())

let curCategory = Computed(@() attrSlotData.get().preset.findvalue(@(p) p.id == curCategoryId.get()))

let selAttrSpCost = Computed(function() {
  local res = 0
  let { slot, preset } = attrSlotData.get()
  if (slot == null)
    return 0
  foreach (cat in preset)
    foreach (attr in cat.attrList)
      res += sumCost(attr.levelCost, slot.attrLevels?[cat.id][attr.id] ?? 0, selAttributes.get()?[cat.id][attr.id])
  return res
})

let totalSlotSp = Computed(@() attrSlotData.get().slot?.sp ?? 0)
let leftSlotSp = Computed(@() totalSlotSp.get() - selAttrSpCost.get())
let isSlotMaxSkills = Computed(function() {
  let { slot, preset } = attrSlotData.get()
  if (slot == null)
    return false
  return null == preset.findvalue(@(cat)
    null != cat.attrList.findvalue(@(attr) attr.levelCost.len() > (slot.attrLevels?[cat.id][attr.id] ?? 0)))
})

let curCampSlotExpId = Computed(@() slotExpByCamp?[curCampaign.get()])
let curCampSlotExp = Computed(@() balance.get()?[curCampSlotExpId.get()] ?? 0)
let needDistributeCampaignSlotExp = Computed(@() curCampSlotExp.get() > 0 && slotLevelsToMax.get() > 0)

function mkUnseenSlotAttrByIdx(idx) {
  let attrDataByIdx = Computed(function() {
    let slot = curSlots.get()?[idx]
    return {
      slot
      preset = attrPresets.get()?[campConfigs.get()?.campaignCfg.slotAttrPreset] ?? []
    }
  })

  let selSpCost = Computed(function() {
    local res = 0
    let { slot, preset } = attrDataByIdx.get()
    if (slot == null)
      return 0
    foreach (cat in preset)
      foreach (attr in cat.attrList)
        res += sumCost(attr.levelCost, slot.attrLevels?[cat.id][attr.id] ?? 0, selAttributes.get()?[cat.id][attr.id])
    return res
  })

  let totalSp = Computed(@() attrDataByIdx.get().slot?.sp ?? 0)
  let leftSp = Computed(@() totalSp.get() - selSpCost.get())

  let isMaxSkills = Computed(function() {
    let { slot, preset } = attrDataByIdx.get()
    if (slot == null)
      return false
    return null == preset.findvalue(@(cat)
      null != cat.attrList.findvalue(@(attr) attr.levelCost.len() > (slot.attrLevels?[cat.id][attr.id] ?? 0)))
  })

  let isMaxSlotLevel = Computed(@() (maxSlotLevels.get()?.len() ?? 0) <= (attrDataByIdx.get()?.slot.level ?? 0))

  return Computed(function() {
    let { slot = null, preset = null } = attrDataByIdx.get()
    let { attrLevels = null } = slot
    let isUnseenByBalance = curCampSlotExp.get() > 0 && !isMaxSlotLevel.get()
    if (attrLevels == null || preset == null || leftSp.get() <= 0 || isMaxSkills.get())
      return { status = -1, statusByCat = [], isUnseen = isUnseenByBalance }
    let selAttr = selAttributes.get()
    let avail = array(MAX_AVAIL_STATUS, 0)
    let availCats = []
    foreach (cat in preset) {
      let cAvail = array(MAX_AVAIL_STATUS, 0)
      foreach (attr in cat.attrList) {
        let level = selAttr?[cat.id][attr.id] ?? attrLevels?[cat.id][attr.id] ?? 0
        if (attr.levelCost.len() <= level)
          continue
        avail[0]++
        cAvail[0]++
        local cost = 0
        for (local inc = 0; inc < MAX_AVAIL_STATUS - 1; inc++) {
          cost += attr.levelCost?[level + inc] ?? 0
          if (cost <= leftSp.get()) {
            avail[inc + 1]++
            cAvail[inc + 1]++
          }
          else
            break
        }
      }
      availCats.append(cAvail)
    }

    let statusByCat = availCats.map(calcStatus)
    let seenSlotLevel = seenSlotAttributes.get()?[curCampaign.get()][idx]
    let isUnseenByAttr = statusByCat.len() > 0
      && (isMaxSlotLevel.get() || !seenSlotLevel || (slot?.level ?? 0) > seenSlotLevel)
    return {
      status = calcStatus(avail)
      statusByCat
      isUnseen = isUnseenByAttr || isUnseenByBalance
    }
  })
}

function applyAttributes() {
  if (selAttrSpCost.get() <= 0 || slotInProgress.get() != null)
    return
  add_slot_attributes(curCampaign.get(), selectedSlotIdx.get(), selAttributes.get(), selAttrSpCost.get())
}

function markSlotAttributesSeen(slotIdx) {
  if (slotIdx == null)
    return
  let curSlotLevel = curSlots.get()?[slotIdx]?.level

  seenSlotAttributes.mutate(function(v) {
    if(curCampaign.get() not in v)
      v[curCampaign.get()] <- {}
    return v[curCampaign.get()][slotIdx] <- curSlotLevel
  })

  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_SLOT_ATTRIBUTES)
  sBlk.addBlock(curCampaign.get())[slotIdx.tostring()] = curSlotLevel

  eventbus_send("saveProfile", {})
}

function loadSeenSlotAttributes() {
  if (!isSettingsAvailable.get())
    return seenSlotAttributes.set({})
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_SLOT_ATTRIBUTES]
  if (!isDataBlock(htBlk))
    return seenSlotAttributes.set({})

  let res = {}
  foreach (campaign, slotIndexes in htBlk) {
    let seenSlots = {}
    eachParam(slotIndexes, @(level, idx) seenSlots[idx.tointeger()] <- level)
    if (seenSlots.len() > 0)
      res[campaign] <- seenSlots
  }
  seenSlotAttributes.set(res)
}

function hasUpgradedAttrUnitNotUpdatable() {
  foreach (unit in campMyUnits.get())
    if (!unit.isPremium && !unit.isUpgraded)
      foreach (attributes in unit.attrLevels)
        foreach (attr in attributes)
          if (attr > 0)
            return true
  return false
}

if (seenSlotAttributes.get().len() == 0)
  loadSeenSlotAttributes()

isSettingsAvailable.subscribe(@(_) loadSeenSlotAttributes())

let openSlotExpWnd = @() isOpenedSlotExpWnd.set(true)

function openSlotAttrWnd() {
  isSlotAttrOpened.set(true)
  if (needDistributeCampaignSlotExp.get())
    openSlotExpWnd()
}

local wasExp = curCampSlotExp.get()
curCampSlotExp.subscribe(function(exp) {
  if (isSlotAttrOpened.get() && exp > wasExp)
    openSlotExpWnd()
  wasExp = exp
})

register_command(function() {
  seenSlotAttributes.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_SLOT_ATTRIBUTES)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_slot_attributes")

return {
  openSlotAttrWnd
  openSlotExpWnd
  openSlotResetWnd = @() isOpenedSlotResetWnd.set(true)
  isSlotAttrOpened
  isSlotAttrAttached
  isOpenedSlotExpWnd
  isOpenedSlotResetWnd
  resetSlotSelectionData
  isOpenedSlotSelection = Computed(@() resetSlotSelectionData.get() != null)
  attrSlotIdx = selectedSlotIdx

  slotLevelResetPrice
  slotSkillsResetPrice
  isResetSlotLevelAllowed
  isResetSlotSkillsAllowed
  attrSlotData
  slotUnitName
  slotLevel
  curCategory
  slotAttributes
  selAttrSpCost
  totalSlotSp
  leftSlotSp
  isSlotMaxSkills
  mkUnseenSlotAttrByIdx
  resetAttrState
  applyAttributes
  hasUpgradedAttrUnitNotUpdatable
  slotLevelsToMax
  seenSlotAttributes
  markSlotAttributesSeen
  curCampSlotExpId
  curCampSlotExp
  needDistributeCampaignSlotExp
}
