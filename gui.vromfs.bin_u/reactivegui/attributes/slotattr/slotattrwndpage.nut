from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import setInterval, clearTimer
from "sound_wt" import playSound
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitTags.nut" import getUnitTagsShop
from "%rGui/attributes/attrBlockComp.nut" import applyAttrRowChange, lastClickTime, boost_cooldown, rowHeight,
  progressBtnGap, mkProgressBtnContentDec, mkProgressBarSlider, mkRowLabel, mkRowValue, startIncBtnGlare,
  mkProgressBtnContentInc, mkNextIncCost, mkProgressBtn, incBtnAnimRepeat
from "%rGui/attributes/attrState.nut" import selAttributes, curCategoryId, getMaxAttrLevelData
from "%rGui/attributes/attrValues.nut" import getAttrLabelText, getAttrValData
import "%rGui/attributes/slotAttr/buySlotLevelWnd.nut" as buySlotLevelWnd
from "%rGui/attributes/slotAttr/slotAttrState.nut" import slotUnitName, curCategory, slotAttributes, totalSlotSp,
  leftSlotSp
from "%rGui/attributes/unitAttr/unitAttrState.nut" import attrUnitType
from "%rGui/slotBar/slotBarState.nut" import selectedSlotIdx
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


function applyAttrRowChangeOrBoost(catId, attr, tryValue, selLevel, minLevel, maxLevel) {
  if (applyAttrRowChange(catId, attr.id, tryValue, selLevel, minLevel, maxLevel)) {
    playSound("click")
    return
  }
  playSound("meta_denied")
  let currTime = get_time_msec()
  if (lastClickTime + boost_cooldown < currTime) { 
    let nextIncCost = attr.levelCost?[selLevel.get()] ?? 0 
    if (nextIncCost > 0 && tryValue > selLevel.get())
      buySlotLevelWnd(selectedSlotIdx.get())
  }
}

function mkAttrRow(unitName, catId, attr, idx) {
  let shopCfg = getUnitTagsShop(unitName)
  let minLevel = Computed(@() slotAttributes.get()?[catId][attr.id] ?? 0) 
  let selLevel = Computed(@() max(selAttributes.get()?[catId][attr.id] ?? minLevel.get(), minLevel.get())) 
  let maxLevel = Computed(@() getMaxAttrLevelData(attr, selLevel.get(), leftSlotSp.get()).maxLevel) 
  let totalLevels = attr.levelCost.len() 
  let nextIncCost = Computed(@() attr.levelCost?[selLevel.get()] ?? 0)
  let canDec = Computed(@() selLevel.get() > minLevel.get())
  let canInc = Computed(@() selLevel.get() < maxLevel.get())
  let attrLocName = getAttrLabelText(attrUnitType.get(), attr.id)
  let mkBtnOnClick = @(diff) @() applyAttrRowChangeOrBoost(catId, attr, selLevel.get() + diff, selLevel, minLevel, maxLevel)
  let onChangeValue = @(val) applyAttrRowChange(catId, attr.id, val, selLevel, minLevel, maxLevel)
  let unitMods = Computed(@() campMyUnits.get()?[unitName].mods ?? {})
  let curValueData = Computed(@() getAttrValData(attrUnitType.get(), attr, minLevel.get(), shopCfg, serverConfigs.get(), unitMods.get()))
  let selValueData = Computed(@() selLevel.get() > minLevel.get()
    ? getAttrValData(attrUnitType.get(), attr, selLevel.get(), shopCfg, serverConfigs.get(), unitMods.get())
    : [])
  let hasSp = Computed(@() totalSlotSp.get() > 0 )
  let hasChanges = Computed(@() selValueData.get().len() > 0)

  return @() {
    watch = hasSp
    size = [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    gap = progressBtnGap
    valign = ALIGN_CENTER
    children = [
      mkProgressBtn(mkProgressBtnContentDec(canDec), mkBtnOnClick(-1))
      @() {
        watch = hasChanges
        size = FLEX
        valign = ALIGN_CENTER
        children = [
          {
            size = FLEX
            flow = FLOW_HORIZONTAL
            gap = hdpx(10)
            children = [
              mkRowLabel(attrLocName)
              mkRowValue(curValueData, selValueData)
            ]
          }
          mkProgressBarSlider(selLevel, totalLevels, onChangeValue, hasChanges.get())
        ]
      }
      {
        key = $"slotAttrProgressBtn_{idx}" 
        children = mkProgressBtn(mkProgressBtnContentInc(canInc), mkBtnOnClick(1))
      }
      hasSp.get() ? mkNextIncCost(nextIncCost, canInc, totalSlotSp) : null
    ]
  }
}

let slotAttrPage = @() {
  key = "slotAttributesList" 
  watch = [curCategory, slotUnitName]
  size = FLEX_H
  onAttach = @() setInterval(incBtnAnimRepeat, startIncBtnGlare)
  onDetach = @() clearTimer(startIncBtnGlare)
  children = {
    key = curCategory.get()
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = (curCategory.get()?.attrList ?? [])
      .map(@(attr, idx) mkAttrRow(slotUnitName.get(), curCategoryId.get(), attr, idx))
    animations = wndSwitchAnim
  }
}

return { slotAttrPage }
