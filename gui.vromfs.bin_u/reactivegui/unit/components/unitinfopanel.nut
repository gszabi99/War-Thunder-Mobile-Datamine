from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { getUnitLocId, getUnitClassFontIcon, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { mkUnitLevelBlock, levelHolderSize } = require("%rGui/unit/components/unitLevelComp.nut")
let { mkCurrencyImage, mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { mkUnitStatsCompShort, mkUnitStatsCompFull, armorProtectionPercentageColors,
  avgShellPenetrationMmByRank } = require("%rGui/unit/unitStats.nut")
let { attrPresets } = require("%rGui/unitAttr/unitAttrState.nut")
let { mkUnitBonuses, mkBonusTiny, bonusTinySize } = require("unitInfoComps.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { itemsCfgOrdered } = require("%appGlobals/itemsState.nut")
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { TANK } = require("%appGlobals/unitConst.nut")
let { unitMods } = require("%rGui/unitMods/unitModsState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { getUnitBlkDetails } = require("%rGui/unitDetails/unitBlkDetails.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { blueprintsInfo } = require("%rGui/blueprints/bluePrintsComp.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { canBuyUnits } = require("%appGlobals/unitsState.nut")

let statsWidth = hdpx(500)
let textColor = 0xFFFFFFFF
let progressBgColor = 0xFF606060
let progressFgColor = 0xFF10AFE2
let progressFgPositiveColor = 0xFF18FFFF
let progressFgNegativeColor = 0xFFDE83FF
let progressBorderW = hdpx(2)
let progressHt = hdpx(5) + 2 * progressBorderW
let statsGap = hdpx(5)
let statsInsideGap = hdpx(2)
let unitInfoPanelDefPos = [ saBorders[0], hdpx(100) ]

let diffAnimDelay = 0.5
let diffAnimTime = 0.5

let canUseItemByUnit = {
  ship_smoke_screen_system_mod = @(unitName) getUnitBlkDetails(unitName).hasShipSmokeScreen
}

let mkText = @(override = {}) {
  color = textColor
  rendObj = ROBJ_TEXT
}.__update(fontTiny, override)

let inlineIconSize = hdpxi(40)
let mkInlineCurrencyIcon = @(currencyId) {
  size = [ inlineIconSize, flex() ]
  valign = ALIGN_CENTER
  children = mkCurrencyImage(currencyId, inlineIconSize, {pos = [ -hdpx(15), ph(8) ]})
}

let mkUnitTitleCtor = @(unitNameCtor) function(unit, override = {}, textOverride = {}, imgOverride = {}) {
  let { isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let title = {
    rendObj = ROBJ_TEXT
    size = SIZE_TO_CONTENT
    text = getUnitClassFontIcon(unit) == ""
      ? unitNameCtor(unit)
      : "  ".concat(unitNameCtor(unit), getUnitClassFontIcon(unit))
    color = isElite ? premiumTextColor : textColor
    fontFx = FFT_GLOW
    fontFxFactor = 64
    fontFxColor = 0xFF000000
  }.__update(fontSmallAccented, textOverride)
  return !isElite ? title.__update(override)
    : {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          {
            size = [hdpx(90), hdpx(40)]
            rendObj = ROBJ_IMAGE
            keepAspect = KEEP_ASPECT_FIT
            vplace = ALIGN_BOTTOM
            image = Picture("ui/gameuiskin#icon_premium.svg")
          }.__update(imgOverride)
          title
        ]
      }.__update(override)
}

let mkUnitTitle = mkUnitTitleCtor(@(unit) loc(getUnitLocId(unit)))
let mkPlatoonOrUnitTitle = mkUnitTitleCtor(@(unit)
  (unit?.platoonUnits.len() ?? 0) > 0 ? getPlatoonName(unit.name, loc) : loc(getUnitLocId(unit)))

let diffProgress = @(width, posX, pivotX, color) {
  size = [width, flex()]
  pos = [posX, flex()]
  rendObj = ROBJ_SOLID
  color = 0
  transform = { pivot = [pivotX, 0] }
  animations = [
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [0.0, 1.0],
      delay = diffAnimDelay, duration = diffAnimTime, easing = InOutQuad, play = true }
    { prop = AnimProp.color, from = color, to = color,
      duration = diffAnimDelay + diffAnimTime, play = true }
  ]
}

function mkStatRow(data, prevProgress) {
  let { header = null, value = null, progress = null,
    progressColor = null, uid = null } = data
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = statsInsideGap
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_BOTTOM
        children = [
          mkText({ text = header })
          mkText({ text = value, hplace = ALIGN_RIGHT })
        ]
      }
      progress == null ? null
        : {
            key = $"{uid}{progress}"
            size = [flex(), progressHt]
            padding = progressBorderW
            rendObj = ROBJ_BOX
            fillColor = progressBgColor
            borderColor = 0xFF000000
            borderWidth = progressBorderW
            children = [
              {
                size = [pw(progress * 100), flex()]
                rendObj = ROBJ_SOLID
                color = progressColor ?? progressFgColor
              },
              (prevProgress ?? progress) == progress ? null
                : prevProgress > progress
                  ? diffProgress(pw((prevProgress - progress) * 100), pw(progress * 100), 0.0, progressFgNegativeColor)
                : diffProgress(pw((progress - prevProgress) * 100), pw(prevProgress * 100), 1.0, progressFgPositiveColor)
            ]
          }
    ].filter(@(v) v != null)
  }
}

let unitStatsBlock = @(unitStats, prevStats) function() {
  let prev = (prevStats ?? {}).reduce(function(res, s) {
    res[s.uid] <- s.progress
    return res
  }, {})
  return {
    size = [statsWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = statsGap
    children = unitStats.map(@(s) mkStatRow(s, prev?[s.uid]))
  }
}

let armorIconSize = hdpxi(23)
let armorIconView = @(image) {
  size = [armorIconSize, armorIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{image}.svg:{armorIconSize}:{armorIconSize}:P")
}
let iconsView = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_BOX
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  children = [
    armorIconView("stats_icon_shield")
    armorIconView("stats_icon_arrow")
    armorIconView("stats_icon_shield_broken")
  ]
}

let mkArmorText = @(needLabels, id) {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_LEFT
    children = [
      mkText({ text = needLabels
        ? "".concat(loc($"stats/{id}"), loc("ui/comma"), loc("measureUnits/mm"))
        : loc($"stats/{id}") })
      iconsView
    ]
  }

function mkArmorRow(id, percentValsP3, avgShellPenetration, width) {
  if (percentValsP3 == null)
    return null
  let { x, y, z } = percentValsP3
  let percentsList = [ x, y, z ]
  let needLabels = avgShellPenetration != null

  let cfg = percentsList.map(@(v, idx) v == 0 ? null : {
    value = v
    barElem = {
      size = [ pw(v * 100), progressHt - 2 * progressBorderW ]
      rendObj = ROBJ_SOLID
      color = armorProtectionPercentageColors[idx]
    }
    labelElem = !needLabels ? null : mkText({
      text = avgShellPenetration?[idx]
      color = textColor
    })
  }).filter(@(v) v != null)

  if (needLabels) {
    let totalBars = cfg.len()
    let totalW = width - 2 * progressBorderW
    let minGap = hdpx(10)
    foreach (idx, v in cfg) {
      let barW = round(v.value * totalW)
      let barX = cfg.reduce(@(sum, vv, i) (i < idx) ? (sum + vv.barW) : sum, 0)
      let labelW = calc_comp_size(v.labelElem)[0]
      let labelX = barX + (barW - labelW) / 2
      v.__update({ barW, barX, labelW, labelX })
    }
    foreach (idx in [ totalBars - 1, 0 ]) {
      let v = cfg?[idx]
      if (v == null)
        continue
      let { barW, labelW } = v
      if (labelW > barW)
        v.labelX = idx == 0 ? 0 : (totalW - labelW)
    }
    for (local idx = 1; idx < totalBars - 1; idx++) {
      let v = cfg[idx]
      let { labelW, labelX } = v
      let prev = cfg[idx - 1]
      let next = cfg[idx + 1]
      let minX = prev.labelX + prev.labelW + minGap
      let maxX = next.labelX - minGap - labelW
      if (minX <= maxX)
        v.labelX = clamp(labelX, minX, maxX)
    }
    foreach (v in cfg)
      v.labelElem.pos <- [ v.labelX, 0 ]
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = statsInsideGap
    children = [
      mkArmorText(needLabels, id)
      !needLabels ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [ 0, progressBorderW ]
        children = cfg.map(@(v) v.labelElem)
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = progressBorderW
        rendObj = ROBJ_BOX
        fillColor = progressBgColor
        borderColor = 0xFF000000
        borderWidth = progressBorderW
        flow = FLOW_HORIZONTAL
        children = cfg.map(@(v) v.barElem)
      }
    ]
  }
}

function unitArmorBlock(unit, needLabels) {
  if (unit.unitType != TANK)
    return null
  let shopCfg = getUnitTagsShop(unit.name)
  let avgShellPenetration = needLabels
    ? avgShellPenetrationMmByRank?[unit.mRank - 1]
    : null
  return {
    size = [statsWidth, SIZE_TO_CONTENT]
    margin = [ statsGap, 0, 0, 0 ]
    gap = statsGap
    flow = FLOW_VERTICAL
    children = [ "armorThicknessFront", "armorThicknessSide" ]
      .map(@(id) mkArmorRow(id, shopCfg?[id], avgShellPenetration, statsWidth))
  }
}

function unitPriceBlock(unit) {
  if (unit.campaign not in serverConfigs.get()?.unitTreeNodes
      || unit.isPremium
      || unit.name in myUnits.get()
      || unit.name in canBuyUnits.get())
    return null
  let price = Computed(@() getUnitAnyPrice(unit, false, unitDiscounts.get()))
  return @() {
    watch = [serverConfigs, myUnits, canBuyUnits, price]
    size = [statsWidth, SIZE_TO_CONTENT]
    margin = [statsGap, 0, 0, 0]
    flow = FLOW_HORIZONTAL
    children = [
      mkText({ text = loc("unitsTree/purchasePrice"), size = [ flex(), SIZE_TO_CONTENT ] })
      mkCurrencyComp(price.get().price, price.get().currencyId, CS_COMMON.__merge({
        iconSize = bonusTinySize
        fontStyle = fontTiny
        iconGap = hdpx(6)
      }))
    ]
  }
}

let mkConsumableRow = @(id, value) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    mkText({ text = loc($"consumable/cost/{id}") })
    {
      size = SIZE_TO_CONTENT
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = [
        mkInlineCurrencyIcon(id)
        mkText({ text = value })
      ]
    }
  ]
}

let unitConsumablesBlock = @(unit, itemsList) {
  size = [statsWidth, SIZE_TO_CONTENT]
  margin = [ statsGap, 0, 0, 0 ]
  gap = statsGap + statsInsideGap + progressHt
  flow = FLOW_VERTICAL
  children = itemsList
    .filter(@(cfg) canUseItemByUnit?[cfg.name](unit.name) ?? true)
    .map(@(itemCfg)
      mkConsumableRow(itemCfg.name, (itemCfg?.itemsPerUse ?? 0) > 0 ? itemCfg.itemsPerUse : unit.itemsPerUse))
}

function unitMRankBlock(mRank) {
  if (!mRank || mRank <= 0)
    return null

  return {
    size = [statsWidth, SIZE_TO_CONTENT]
    margin = [hdpx(15), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("attrib_section/mRank")
        size = [flex(), SIZE_TO_CONTENT]
      }.__update(fontTiny)
      mkGradRank(mRank)
    ]
  }
}

let unitRewardsBlock = @(unit, title) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  size = [ statsWidth, hdpx(40) ]
  children = [
    {
      margin = [ 0, hdpx(10), 0, 0 ]
      rendObj = ROBJ_TEXT
      text = title
      size = [ flex(), SIZE_TO_CONTENT ]
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(50)
    }.__update(fontTiny)
    mkUnitBonuses(unit, {}, mkBonusTiny)
  ]
}

let unitHeaderBlock = @(unit, unitTitleCtor) @(){
  watch = myUnits
  hplace = ALIGN_RIGHT
  minWidth = statsWidth
  padding = hdpx(10)
  children = [
    {
      margin =[hdpx(5), 0, 0, levelHolderSize]
      pos = [0, -hdpx(20)]
      children = unitTitleCtor(unit)
    }
    unit.name in myUnits.value
      ? mkUnitLevelBlock(unit)
      : null
  ]
}

local lastUnitStats = null

let unitInfoPanel = @(override = {}, headerCtor = mkPlatoonOrUnitTitle, unit = hangarUnit, ovr = {}) function() {
  if (unit.value == null)
    return { watch = unit }

  let prevStats = lastUnitStats
  let unitStats = mkUnitStatsCompShort(unit.value, unit.value?.attrLevels,
    attrPresets.value?[unit.value?.attrPreset], unitMods.value)
  lastUnitStats = unitStats

  return panelBg.__merge({
    watch = [unit, unitMods, attrPresets]
    children = {
      minWidth = statsWidth
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitHeaderBlock(unit.value, headerCtor)
        unitMRankBlock(unit.value?.mRank)
        unitRewardsBlock(unit.value, loc("attrib_section/battleRewards"))
        unit.value?.isUpgraded || unit.value?.isPremium
          ? null
          : unitRewardsBlock(unit.value.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}
            { isUpgraded = true }), loc("attrib_section/upgradeBattleRewards"))
        unitStatsBlock(unitStats, prevStats)
        unitArmorBlock(unit.value, false)
        unitPriceBlock(unit.get())
        blueprintsInfo(unit.value)
      ]
    }.__update(ovr)
  }, override)
}

let unitInfoPanelFull = @(override = {}, unit = hangarUnit) function() {
  if (unit.value == null)
    return { watch = unit }

  let prevStats = lastUnitStats
  let unitStats = mkUnitStatsCompFull(unit.value, unit.value?.attrLevels,
    attrPresets.value?[unit.value?.attrPreset], unitMods.value)
  lastUnitStats = unitStats

  return panelBg.__merge({
    watch = [ unit, itemsCfgOrdered, unitMods, attrPresets ]
    children = unit.value == null ? null
      : [
          unitMRankBlock(unit.value?.mRank)
          unitRewardsBlock(unit.value, loc("attrib_section/battleRewards"))
          unit.value?.isUpgraded || unit.value?.isPremium
            ? null
            : unitRewardsBlock(unit.value.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}
              { isUpgraded = true }), loc("attrib_section/upgradeBattleRewards"))
          unitStatsBlock(unitStats, prevStats)
          unitArmorBlock(unit.value, false)
          unitConsumablesBlock(unit.value, itemsCfgOrdered.value)
        ]
  }, override)
}

return {
  unitInfoPanel
  unitInfoPanelFull
  mkUnitTitle
  mkPlatoonOrUnitTitle
  statsWidth
  unitInfoPanelDefPos
}
