from "%globalsDarg/darg_library.nut" import *
let { getUnitName } = require("%appGlobals/unitPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let { mkMissionResultTitle } = require("%rGui/debriefing/missionResultTitle.nut")
let { mkLevelProgressLine } = require("%rGui/debriefing/levelProgressLine.nut")
let { mkTotalRewardCountsUnit } = require("%rGui/debriefing/totalRewardCounts.nut")
let { getBestUnitName, getUnit, getUnitRewards, getLevelProgress, sortUnitMods } = require("%rGui/debriefing/debrUtils.nut")
let { getLevelUnlockPlateAnimTime, mkLevelUnlockPlatesContainer,
  mkDebrPlateMod, mkDebrPlatePoints, plateH, platesGap, scrollBoxMarginV
} = require("%rGui/debriefing/debrLevelUnlockPlates.nut")

let levelProgressAnimStartTime = 0.0
let levelUnlocksAnimStartTime = 1.0
let rewardsAnimStartTime = 0.5

let unlockPlatesContainerHeight = plateH * 3 + platesGap * 2 + scrollBoxMarginV * 2

function mkUnitLevelUnlockPlates(unit, unitExp, debrData, delay) {
  let res = {
    levelUnlocksAnimTime = 0
    levelUnlocksComps = null
  }
  if (unit == null)
    return res

  let { items = {} } = debrData
  let { prevLevel, unlockedLevel } = getLevelProgress(unit, unitExp?.totalExp ?? 0)
  let startLevel = prevLevel + 1
  let endLevel = max(startLevel, unlockedLevel)
  let { modPresetCfg = {}, levelsSp = {} } = unit
  let spLevels = levelsSp?.levels ?? []

  let list = []
  let spData = {data = {sp = 0, reqLevel = 0, isUnlocked = false}, ctor = mkDebrPlatePoints}
  for (local l = startLevel; l <= endLevel; l++) {
    let isUnlocked = l <= unlockedLevel
    
    let modsList = modPresetCfg
      .map(@(mod, name) mod.__merge({ name }))
      .values()
      .filter(@(mod) mod?.reqLevel == l && !mod?.isHidden && (mod.name not in items))
    modsList.sort(sortUnitMods)
    list.extend(modsList.map(@(v) { isUnlocked, data = v, ctor = mkDebrPlateMod }))
    
    let sp = spLevels?[l - 1] ?? 0
    if (sp > 0) {
      let data = { sp = spData.data.sp + sp, reqLevel = l, name = $"sp{l}" }
      spData.data = data
      spData.isUnlocked <- isUnlocked
    }
  }
  if (spData.data.sp > 0)
    list.append(spData)
  let total = list.len()
  let itemTime = getLevelUnlockPlateAnimTime(total)
  res.levelUnlocksAnimTime = total * itemTime
  res.levelUnlocksComps = list.map(function(v, idx) {
    let { ctor, data, isUnlocked } = v
    let unlockDelay = delay + (itemTime * idx)
    return ctor(data, isUnlocked, unlockDelay)
  })
  return res
}

function mkDebriefingWndTabUnit(debrData, params) {
  let { campaign = "" } = debrData
  let unitName = getBestUnitName(debrData)
  let unit = getUnit(unitName, debrData)
  if (unit == null)
    return null

  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsUnit(debrData, rewardsAnimStartTime)
  if (totalRewardCountsComp == null)
    return null

  let unitExp = getUnitRewards(unit?.name, debrData)?.exp
  let { levelProgressLineComp, levelProgressLineAnimTime } = mkLevelProgressLine(unit, unitExp,
    getUnitName(unitName),
    loc(getCampaignPresentation(campaign).debrUnitLevelDescLocId),
    levelProgressAnimStartTime,  unitExpColor)
  let { levelUnlocksComps, levelUnlocksAnimTime } = mkUnitLevelUnlockPlates(unit, unitExp, debrData, levelUnlocksAnimStartTime)

  let { needBtnUnit = true } = params
  let timeShow = max(
      levelProgressAnimStartTime + levelProgressLineAnimTime,
      levelUnlocksAnimStartTime + levelUnlocksAnimTime,
      rewardsAnimStartTime + totalRewardsShowTime
    ) + (needBtnUnit ? buttonsShowTime : 0)

  let comp = {
    size = FLEX
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkMissionResultTitle(debrData, false)
          {
            size = const [SIZE_TO_CONTENT, FLEX]
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            children = [
              levelProgressLineComp
              {
                size = FLEX
                gap = hdpx(100)
                children = [
                  panelBg.__merge(totalRewardCountsComp.__update({
                    size = SIZE_TO_CONTENT
                    pos = [hdpx(85), hdpx(145)]
                  }))
                  mkLevelUnlockPlatesContainer(levelUnlocksComps).__update({
                    pos = [hdpx(1000), 0],
                    size = [SIZE_TO_CONTENT, unlockPlatesContainerHeight]
                  })
                ]
              }
            ]
          }
        ]
      }
      {
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        children = btnTryPremium
      }
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = params.needBtnUnit
  }
}

return mkDebriefingWndTabUnit
