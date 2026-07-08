from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/pServerApi.nut" import increase_vehicle_mastery_tier, unitMasteryTierInProgress
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import mkCustomButton, buttonStyles, mergeStyles,
  textButtonSecondary, textButtonInactive
from "%rGui/components/masteryTierComp.nut" import mkMasteryTierColorIcon, mkMasteryTierIcon
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitInfo, mkUnitBg, mkUnitImage,
  mkUnitTexts, mkUnitPlateBorder, mkUnitLevel
from "%rGui/slotBar/slotBarConsts.nut" import unitPlateSize
from "%rGui/quests/questsPkg.nut" import mkQuestText, btnSize, btnStyleSound, btnStyle
from "%rGui/quests/questBar.nut" import mkQuestBar
from "%rGui/components/levelBlockPkg.nut" import maxLevelStarChar


let MASTERY_WND = "masteryWnd"

let singleStarIconSize = hdpxi(80)
let singleStarMargin = hdpxi(12)

let imgLockSize = hdpxi(60)
let btnIconSize = hdpxi(80)
let smallGap = hdpx(12)
let smallPadding = hdpx(40)

let mkDefQuestData = @(quest) {
  required = quest?.amount ?? 0
  current = quest?.current ?? 0
  name = quest?.stat ? $"mastery/task/{quest?.stat}" : ""
  requirement = quest?.requirement ?? ""
  meta = quest?.meta.__merge({ isMastery = true }) ?? { isMastery = true }
}

let btnContent = {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    mkMasteryTierIcon(btnIconSize, 3)
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("mainmenu/btnMastery"))
    }.__update(fontTinyAccentedShadedBold)
  ]
}

function mkTask(idx, taskCfg, unit) {
  let currentProgress = Computed(function() {
    let { masteryProgress = 0, masteryTier = 0 } = unit.get()
    return masteryTier > idx ? taskCfg.amount
      : masteryTier == idx ? masteryProgress
      : 0
  })
  let hasReceived = Computed(@() (unit.get()?.rewardedMasteryTier ?? -1) > idx)
  let hasLock = Computed(@() (unit.get()?.masteryTier ?? -1) < idx)
  let canReceive = Computed(@() currentProgress.get() == taskCfg.amount)
  let triggerPostfix = $"{taskCfg.stat}_{idx}"
  return {
    size = FLEX_H
    rendObj = ROBJ_SOLID
    color = 0x80000000
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    padding = smallGap
    children = [
      function() {
        let questData = mkDefQuestData(taskCfg.__merge({ current = currentProgress.get() }))
        return {
          watch = currentProgress
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [
            mkQuestText(questData)
            mkQuestBar(questData, triggerPostfix)
          ]
        }
      }
      mkMasteryTierColorIcon(singleStarIconSize, idx + 1)
        .__update({ imageValign = ALIGN_BOTTOM, margin = idx == 0 ? [0, singleStarMargin] : null })
      @() {
        watch = [hasLock, hasReceived, canReceive]
        size = btnSize
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = hasLock.get()
            ? {
                rendObj = ROBJ_IMAGE
                size = imgLockSize
                image = Picture($"ui/gameuiskin#lock_icon.svg:{imgLockSize}:P")
                vplace = ALIGN_CENTER
                keepAspect = true
              }
          : hasReceived.get()
            ? {
                size = btnSize
                rendObj = ROBJ_TEXT
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                text = utf8ToUpper(loc("ui/received"))
                behavior = Behaviors.Button 
              }.__update(fontTinyAccentedShaded)
          : mkSpinnerHideBlock(unitMasteryTierInProgress,
              canReceive.get()
                ? textButtonSecondary(
                    utf8ToUpper(loc("btn/receive")),
                    @() increase_vehicle_mastery_tier(unit.get()?.name, idx + 1),
                    btnStyleSound)
                : textButtonInactive(
                    utf8ToUpper(loc("btn/receive")),
                    @() anim_start($"unfilledBarEffect_{triggerPostfix}"),
                    btnStyle))
      }
    ]
  }
}

function openUnitMastery(unit) {
  let unitTasks = Computed(@() serverConfigs.get()?.masteryPresetsCfg[unit.get()?.unitMastery] ?? [])
  let unitLvl = Computed(function() {
    let { level = 0, maxLevel = null } = unit.get()
    let maxLvl = maxLevel
      ?? campConfigs.get()?.unitLevels[unit.get()?.levelPreset].len() ?? 0  
    return level >= maxLvl ? maxLevelStarChar
      : level
  })
  addModalWindowWithHeader(MASTERY_WND, loc("header/masteryWnd"), {
    size = FLEX_H
    minWidth = hdpx(1100)
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    padding = smallPadding
    gap = smallPadding
    children = [
      @() {
        watch = unit
        size = unitPlateSize
        children = [
          mkUnitBg(unit.get())
          mkUnitImage(unit.get())
          mkUnitTexts(unit.get(), getUnitName(unit.get().name))
          mkUnitInfo(unit.get())
          mkUnitPlateBorder(Watched(false))
          mkUnitLevel(unitLvl.get(), unit.get().rewardedMasteryTier, { size = evenPx(32) })
        ]
      }
      @() {
        watch = unitTasks
        size = FLEX_H
        gap = smallGap
        flow = FLOW_VERTICAL
        children = unitTasks.get().map(@(v, idx) mkTask(idx, v, unit))
      }
    ]
  })
}

let mkHasUnseenMastery = @(unit) Computed(function() {
  if (unit.get() == null)
    return false
  let { masteryProgress = 0, masteryTier = 0, unitMastery = null, rewardedMasteryTier = 0 } = unit.get()
  if (rewardedMasteryTier < masteryTier)
    return true
  let taskCfg = serverConfigs.get()?.masteryPresetsCfg[unitMastery]?[masteryTier]
  return taskCfg != null && masteryProgress >= taskCfg.amount
})


function mkBtnOpenUnitMastery(unit, styleOvr) {
  let hasButton = Computed(function() {
    let { level = 0, maxLevel = 0, unitMastery = null } = unit.get()
    if (level < maxLevel)
      return false

    let cfg = serverConfigs.get()?.masteryPresetsCfg[unitMastery] ?? []
    return cfg.len() > 0
  })
  let hasUnseenMark = mkHasUnseenMastery(unit)
  return @() {
    watch = hasButton
    children = !hasButton.get() ? null
      : [
          mkCustomButton(btnContent,
            @() openUnitMastery(unit),
            mergeStyles(buttonStyles.COMMON, styleOvr))
          @() {
            watch = hasUnseenMark
            margin = hdpx(10)
            hplace = ALIGN_RIGHT
            children = hasUnseenMark.get() ? priorityUnseenMark : null
          }
        ]
  }
}

return {
  mkBtnOpenUnitMastery
  mkHasUnseenMastery
}
