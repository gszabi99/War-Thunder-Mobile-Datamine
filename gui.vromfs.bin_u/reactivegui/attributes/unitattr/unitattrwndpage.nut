from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")

let { applyAttrRowChange, lastClickTime, boost_cooldown, rowHeight, progressBtnGap, mkProgressBtn,
  mkProgressBtnContentDec, mkRowProgressBar, mkRowLabel, mkRowValue, startIncBtnGlare, incBtnAnimRepeat,
  mkProgressBtnContentInc, mkNextIncCost
} = require("%rGui/attributes/attrBlockComp.nut")
let { selAttributes, curCategoryId, getMaxAttrLevelData } = require("%rGui/attributes/attrState.nut")
let { getAttrLabelText, getAttrValData } = require("%rGui/attributes/attrValues.nut")
let buyUnitLevelWnd = require("%rGui/attributes/unitAttr/buyUnitLevelWnd.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { attrUnitName, attrUnitType, curCategory, unitAttributes, totalUnitSp,
  leftUnitSp } = require("%rGui/attributes/unitAttr/unitAttrState.nut")

function applyAttrRowChangeOrBoost(catId, attr, tryValue, selLevel, minLevel, maxLevel) {
  if (!applyAttrRowChange(catId, attr.id, tryValue, selLevel, minLevel, maxLevel)) {
    let currTime = get_time_msec()
    if (lastClickTime + boost_cooldown < currTime) { 
      let nextIncCost = attr.levelCost?[selLevel.get()] ?? 0 
      if (nextIncCost > 0 && tryValue > selLevel.get())
        buyUnitLevelWnd(attrUnitName.get())
    }
  }
}

function mkAttrRow(attr) {
  let shopCfg = getUnitTagsShop(attrUnitName.get())
  let catId = curCategoryId.get()
  let minLevel = Computed(@() unitAttributes.get()?[catId][attr.id] ?? 0) 
  let selLevel = Computed(@() max(selAttributes.get()?[catId][attr.id] ?? minLevel.get(), minLevel.get())) 
  let maxLevel = Computed(@() getMaxAttrLevelData(attr, selLevel.get(), leftUnitSp.get()).maxLevel) 
  let totalLevels = attr.levelCost.len() 
  let nextIncCost = Computed(@() attr.levelCost?[selLevel.get()] ?? 0)
  let canDec = Computed(@() selLevel.get() > minLevel.get())
  let canInc = Computed(@() selLevel.get() < maxLevel.get())
  let attrLocName = getAttrLabelText(attrUnitType.get(), attr.id)
  let mkBtnOnClick = @(diff) @() applyAttrRowChangeOrBoost(catId, attr, selLevel.get() + diff, selLevel, minLevel, maxLevel)
  let mkCellOnClick = @(val) @() applyAttrRowChange(catId, attr.id, val, selLevel, minLevel, maxLevel)
  let unitMods = Computed(@() campMyUnits.get()?[attrUnitName.get()].mods ?? {})
  let curValueData = Computed(@() getAttrValData(attrUnitType.get(), attr, minLevel.get(), shopCfg, serverConfigs.get(), unitMods.get()))
  let selValueData = Computed(@() selLevel.get() > minLevel.get()
    ? getAttrValData(attrUnitType.get(), attr, selLevel.get(), shopCfg, serverConfigs.get(), unitMods.get())
    : [])
  let hasSp = Computed(@() totalUnitSp.get() > 0 )

  return @() {
    watch = hasSp
    size = [ flex(), rowHeight ]
    flow = FLOW_HORIZONTAL
    gap = progressBtnGap
    valign = ALIGN_CENTER
    children = [
      mkProgressBtn(mkProgressBtnContentDec(canDec), mkBtnOnClick(-1))
      {
        size = flex()
        valign = ALIGN_CENTER
        children = [
          {
            size = flex()
            flow = FLOW_HORIZONTAL
            gap = hdpx(10)
            children = [
              mkRowLabel(attrLocName)
              mkRowValue(curValueData, selValueData)
            ]
          }
          mkRowProgressBar(minLevel, selLevel, maxLevel, totalLevels, mkCellOnClick)
        ]
      }
      mkProgressBtn(mkProgressBtnContentInc(canInc), mkBtnOnClick(1))
      hasSp.get() ? mkNextIncCost(nextIncCost, canInc, totalUnitSp) : null
    ]
  }
}

let unitAttrPage = @() {
  key = startIncBtnGlare
  watch = curCategory
  size = FLEX_H
  onAttach = @() setInterval(incBtnAnimRepeat, startIncBtnGlare)
  onDetach = @() clearTimer(startIncBtnGlare)
  children = {
    key = curCategory.get()
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = (curCategory.get()?.attrList ?? []).map(mkAttrRow)
    animations = wndSwitchAnim
  }
}

return { unitAttrPage }
