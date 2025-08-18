from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { getUnitLocId, getUnitClassFontIcon, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { mkUnitLevelBlock, levelHolderSize } = require("%rGui/unit/components/unitLevelComp.nut")
let { mkCurrencyImage, mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { mkUnitStatsCompShort, mkUnitStatsCompFull, armorProtectionPercentageColors,
  avgShellPenetrationMmByRank, addedFromSlot } = require("%rGui/unit/unitStats.nut")
let { attrPresets, hasSlotAttrPreset } = require("%rGui/attributes/attrState.nut")
let { mkUnitBonuses, mkUnitDailyLimit, mkBonusTiny, bonusTinySize } = require("%rGui/unit/components/unitInfoComps.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { itemsCfgByCampaignOrdered } = require("%appGlobals/itemsState.nut")
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { TANK } = require("%appGlobals/unitConst.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots } = require("%appGlobals/pServer/slots.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isItemAllowedForUnit } = require("%rGui/unit/unitItemAccess.nut")

let statsWidth = hdpx(495)
let textColor = 0xFFFFFFFF
let progressBgColor = 0xFF606060
let progressFgColor = 0xFFFFFFFF
let progressFgPositiveColor = 0xFF00D427
let progressFgNegativeColor = 0xFFFF0202
let progressBorderW = hdpx(2)
let progressHt = hdpx(5) + 2 * progressBorderW
let statsGap = hdpx(5)
let statsInsideGap = hdpx(2)

let diffAnimDelay = 0.5
let diffAnimTime = 0.5

let scrollHandlerInfoPanel = ScrollHandler()

let mkText = @(override = {}) {
  color = textColor
  rendObj = ROBJ_TEXT
}.__update(fontVeryTinyAccented, override)

let mkTextArea = @(override = {}) {
  size = FLEX_H
  behavior = Behaviors.TextArea
  color = textColor
  rendObj = ROBJ_TEXTAREA
}.__update(fontVeryTinyAccented, override)

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
    maxWidth = isElite ? hdpx(290) : hdpx(400)
    text = getUnitClassFontIcon(unit) == ""
      ? unitNameCtor(unit)
      : "  ".concat(unitNameCtor(unit), getUnitClassFontIcon(unit))
    color = isElite ? premiumTextColor : textColor
    fontFx = FFT_GLOW
    fontFxFactor = 64
    fontFxColor = 0xFF000000
    behavior = Behaviors.Marquee
    speed = hdpx(30)
    delay = defMarqueeDelay
  }.__update(fontSmallAccented, textOverride)
  return !isElite ? title.__update(override)
    : {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          {
            size = const [hdpx(90), hdpx(40)]
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

function setScrollStr(text){
  return{
    maxWidth = hdpx(350)
    text = text
    behavior = Behaviors.Marquee
    speed = hdpx(30)
    delay = defMarqueeDelay
  }
}

function mkStatRow(data, prevProgress) {
  let { header = null, value = null, progress = null,
    progressColor = null, uid = null, isMultiline = false, progressAttr = 0 } = data
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = statsInsideGap
    children = [
      {
        size = FLEX_H
        valign = ALIGN_BOTTOM
        children = [
          isMultiline ? mkTextArea({ text = header }) : mkText(setScrollStr(header))
          mkTextArea({ text = value, halign = ALIGN_RIGHT })
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
                : diffProgress(pw((progress - prevProgress) * 100), pw(prevProgress * 100), 1.0, progressFgPositiveColor),
              {
                size = [pw(progress * 100 * progressAttr), flex()]
                pos = [pw(progress * 100), flex()]
                rendObj = ROBJ_SOLID
                color = addedFromSlot
              }
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
  size = FLEX_H
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
    size = FLEX_H
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
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = statsInsideGap
    children = [
      mkArmorText(needLabels, id)
      !needLabels ? null : {
        size = FLEX_H
        padding = [ 0, progressBorderW ]
        children = cfg.map(@(v) v.labelElem)
      }
      {
        size = FLEX_H
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
  let { isUpgraded = false, isPremium = false, campaign = null, name = null } = unit
  if (campaign not in serverConfigs.get()?.unitTreeNodes
      || name in campMyUnits.get()
      || isUpgraded
      || isPremium)
    return null
  let price = Computed(@() getUnitAnyPrice(unit, false, unitDiscounts.get()))
  return @() price.get()?.price
    ? {
      watch = [serverConfigs, campMyUnits, price]
      size = [statsWidth, SIZE_TO_CONTENT]
      margin = [statsGap, 0, 0, 0]
      flow = FLOW_HORIZONTAL
      children = [
        mkText({ text = loc("unitsTree/purchasePrice"), size = FLEX_H })
        mkCurrencyComp(price.get().price, price.get().currencyId, CS_COMMON.__merge({
          iconSize = bonusTinySize
          fontStyle = fontVeryTinyAccented
          iconGap = hdpx(6)
        }))
      ]
    }
    : { watch = price }
}

let mkConsumableRow = @(id, value) {
  size = FLEX_H
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
    .filter(@(cfg) (cfg?.itemsPerUse != 1) && isItemAllowedForUnit(cfg.name, unit.name))
    .map(@(itemCfg)
      mkConsumableRow(itemCfg.name, (itemCfg?.itemsPerUse ?? 0) > 0 ? itemCfg.itemsPerUse : unit.itemsPerUse))
}

function unitMRankBlock(mRank) {
  if (!mRank || mRank <= 0)
    return null

  return {
    size = [statsWidth, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("attrib_section/mRank")
        size = FLEX_H
      }.__update(fontVeryTinyAccented)
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
      margin = const [ 0, hdpx(10), 0, 0 ]
      rendObj = ROBJ_TEXT
      text = title
      size = FLEX_H
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(50)
    }.__update(fontVeryTinyAccented)
    mkUnitBonuses(unit, {}, mkBonusTiny)
  ]
}

let unitRewardsDailyBlock = @(unit, title, unitsGold) unit?.dailyGoldLimit == 0 ? null : {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  size = [ statsWidth, hdpx(40) ]
  children =  [
    {
      margin = const [ 0, hdpx(10), 0, 0 ]
      rendObj = ROBJ_TEXT
      text =  title
      size = FLEX_H
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(50)
    }.__update(fontVeryTinyAccented)
    mkUnitDailyLimit(unit, unitsGold, {})
  ]
}

let unitHeaderBlock = @(unit, unitTitleCtor) @(){
  watch = campMyUnits
  hplace = ALIGN_RIGHT
  minWidth = statsWidth
  padding = hdpx(10)
  children = [
    {
      margin =[hdpx(5), 0, 0, levelHolderSize]
      pos = [0, -hdpx(20)]
      children = unitTitleCtor(unit)
    }
    mkUnitLevelBlock(unit)
  ]
}

local lastUnitStats = null

let getAttrLevels = @(unit) campConfigs.get()?.campaignCfg?.slotAttrPreset != ""
    ? curCampaignSlots.get()?.slots.findvalue(@(slot) slot.name == unit?.name)?.attrLevels ?? {}
    : unit?.attrLevels ?? {}

let getAttrPreset = @(unit) hasSlotAttrPreset.get()
  ? attrPresets.get()?[campConfigs.get()?.campaignCfg?.slotAttrPreset]
  : attrPresets.get()?[unit?.attrPreset]

let isNumeric = @(v) type(v) == "integer" || type(v) == "float"
let notNumericToZero = @(v) isNumeric(v) ? v : 0

function calcPadding(c) {
  let { padding = 0 } = c
  return isNumeric(padding) ? padding * 2
    : type(padding) == "array" ? notNumericToZero(padding?[1]) + notNumericToZero(padding?[3] ?? padding?[1])
    : 0
}

let unitInfoPanel = @(ovr = {}, headerCtor = mkPlatoonOrUnitTitle, unit = hangarUnit, bg = panelBg)
  function() {
    if (unit.value == null)
      return { watch = unit }

    let prevStats = lastUnitStats
    let unitStats = mkUnitStatsCompShort(unit.get(), getAttrLevels(unit.get()),
      getAttrPreset(unit.get()), unit.get()?.mods)
    lastUnitStats = unitStats

    let children = {
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitHeaderBlock(unit.value, headerCtor)
        { size = const [0, hdpx(15)] }
        unitMRankBlock(unit.value?.mRank)
        unitRewardsBlock(unit.value, loc("attrib_section/battleRewards"))
        unit.get()?.isUpgraded || unit.get()?.isPremium || !unit.get()?.isUpgradeable
          ? null
          : unitRewardsBlock(unit.value.__merge(campConfigs.get()?.gameProfile.upgradeUnitBonus ?? {}
            { isUpgraded = true }), loc("attrib_section/upgradeBattleRewards"))
        unit.get()?.isUpgraded || unit.get()?.isPremium
          ? unitRewardsDailyBlock(unit.get(), loc("attrib_section/battleRewardsDaylyLimit"), servProfile.get()?.unitsGold)
          : null
        unitStatsBlock(unitStats, prevStats)
        unitArmorBlock(unit.value, false)
        unitPriceBlock(unit.get())
      ]
    }

    let res = bg.__merge(
      {
        watch = [unit, attrPresets]
        stopMouse = true
        children = children
      },
      ovr)

    let maxHeight = ovr?.maxHeight ?? bg?.maxHeight
    if (isNumeric(maxHeight)) {
      let height = calc_comp_size(res.__merge({ maxHeight = null }))[1]
      if (height > maxHeight)
        res.children = makeVertScroll(children,
          {
            size = [SIZE_TO_CONTENT, maxHeight - calcPadding(res)],
            isBarOutside = true
          })
    }

    return res
  }

let unitInfoPanelFull = @(unit = hangarUnit, ovr = {}) function() {
  if (unit.value == null)
    return { watch = unit }

  let prevStats = lastUnitStats
  let unitStats = mkUnitStatsCompFull(unit.get(), getAttrLevels(unit.get()),
    getAttrPreset(unit.get()), unit.get()?.mods)
  lastUnitStats = unitStats

  return {
    watch = [ unit, itemsCfgByCampaignOrdered, attrPresets ]
    size = FLEX_V
    children = unit.value == null ? null
      : makeVertScroll(
          {
            flow = FLOW_VERTICAL
            children = [
              unitMRankBlock(unit.value?.mRank)
              unitRewardsBlock(unit.value, loc("attrib_section/battleRewards"))
              unit.get()?.isUpgraded || unit.get()?.isPremium || !unit.get()?.isUpgradeable
                ? null
                : unitRewardsBlock(unit.value.__merge(campConfigs.get()?.gameProfile.upgradeUnitBonus ?? {}
                  { isUpgraded = true }), loc("attrib_section/upgradeBattleRewards"))
              unit.get()?.isUpgraded || unit.get()?.isPremium
                ? unitRewardsDailyBlock(unit.get(), loc("attrib_section/battleRewardsDaylyLimit"), servProfile.get()?.unitsGold)
                : null
              unitStatsBlock(unitStats, prevStats)
              unitArmorBlock(unit.value, false)
              unitConsumablesBlock(unit.get(), itemsCfgByCampaignOrdered.get()?[unit.get()?.campaign] ?? [])
            ]
          },
          { size = FLEX_V, isBarOutside = true })
  }.__update(ovr)
}

return {
  unitInfoPanel
  unitInfoPanelFull
  mkUnitTitle
  mkPlatoonOrUnitTitle
  statsWidth
  scrollHandlerInfoPanel
}
