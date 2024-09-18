from "%globalsDarg/darg_library.nut" import *

let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")

let { selAttributes, curCategoryId, getMaxAttrLevelData } = require("%rGui/attributes/attrState.nut")
let { applyAttrRowChange, lastClickTime, boost_cooldown, rowHeight, progressBtnGap,
  mkProgressBtnContentDec, mkRowProgressBar, mkRowLabel, mkRowValue, startIncBtnGlare,
  mkProgressBtnContentInc, mkNextIncCost, mkProgressBtn, incBtnAnimRepeat
} = require("%rGui/attributes/attrBlockComp.nut")
let { getAttrLabelText, getAttrValData } = require("%rGui/attributes/attrValues.nut")
let { slotUnitName, curCategory, slotAttributes, totalSlotSp,
  leftSlotSp } = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { selectedSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { unitMods } = require("%rGui/unitMods/unitModsState.nut")
let buySlotLevelWnd = require("buySlotLevelWnd.nut")


function applyAttrRowChangeOrBoost(catId, attr, tryValue, selLevel, minLevel, maxLevel) {
  if (!applyAttrRowChange(catId, attr.id, tryValue, selLevel, minLevel, maxLevel)) {
    let currTime = get_time_msec()
    if (lastClickTime + boost_cooldown < currTime) { //cooldown check
      let nextIncCost = attr.levelCost?[selLevel.get()] ?? 0 //for max level reach condition
      if (nextIncCost > 0)
        buySlotLevelWnd(selectedSlotIdx.get())
    }
  }
}

function mkAttrRow(attr) {
  let shopCfg = getUnitTagsShop(slotUnitName.get())
  let catId = curCategoryId.get()
  let minLevel = Computed(@() slotAttributes.get()?[catId][attr.id] ?? 0) // Current applied level
  let selLevel = Computed(@() max(selAttributes.get()?[catId][attr.id] ?? minLevel.get(), minLevel.get())) // User selected new level
  let maxLevel = Computed(@() getMaxAttrLevelData(attr, selLevel.get(), leftSlotSp.get()).maxLevel) // Can buy max level
  let totalLevels = attr.levelCost.len() // Total level progress steps
  let nextIncCost = Computed(@() attr.levelCost?[selLevel.get()] ?? 0)
  let canDec = Computed(@() selLevel.get() > minLevel.get())
  let canInc = Computed(@() selLevel.get() < maxLevel.get())
  let attrLocName = getAttrLabelText(curCampaign.get(), attr.id)
  let mkBtnOnClick = @(diff) @() applyAttrRowChangeOrBoost(catId, attr, selLevel.get() + diff, selLevel, minLevel, maxLevel)
  let mkCellOnClick = @(val) @() applyAttrRowChange(catId, attr.id, val, selLevel, minLevel, maxLevel)
  let curValueData = Computed(@() getAttrValData(curCampaign.get(), attr, minLevel.get(), shopCfg, serverConfigs.get(), unitMods.get()))
  let selValueData = Computed(@() selLevel.get() > minLevel.get()
    ? getAttrValData(curCampaign.get(), attr, selLevel.get(), shopCfg, serverConfigs.get(), unitMods.get())
    : [])
  let hasSp = Computed(@() totalSlotSp.get() > 0 )

  return @() {
    watch = hasSp
    size = [flex(), rowHeight]
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
      hasSp.get() ? mkNextIncCost(nextIncCost, canInc, totalSlotSp) : null
    ]
  }
}

let slotAttrPage = @() {
  key = "slotAttributesList" //need for tutorial
  watch = curCategory
  size = [flex(), SIZE_TO_CONTENT]
  onAttach = @() setInterval(incBtnAnimRepeat, startIncBtnGlare)
  onDetach = @() clearTimer(startIncBtnGlare)
  children = {
    key = curCategory.get()
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = (curCategory.get()?.attrList ?? []).map(mkAttrRow)
    animations = wndSwitchAnim
  }
}

return { slotAttrPage }
