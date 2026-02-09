from "%globalsDarg/darg_library.nut" import *
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")

let bonusIconSize = hdpxi(30)
let bonusValueWidth = hdpx(80)
let smallGap = hdpx(20)
let marginToAlign = hdpxi(4)
let textColor = 0xFFE0E0E0
let bonusMultText = @(v) $"{v}x"

let decalsSlotImage = @() {
  size = bonusIconSize
  rendObj = ROBJ_BOX
  borderColor = 0xFFA6A6A6
  borderWidth = hdpx(3)
}

let mkBonusIcon = @(icon) {
  size = [bonusIconSize, bonusIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{bonusIconSize}:{bonusIconSize}:P")
  keepAspect = true
}

let stopIcon = {
  size = [bonusIconSize, bonusIconSize]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = max(1, (0.1 * bonusIconSize + 0.5).tointeger())
  color = 0xFFFF6060
  fillColor = 0
  commands = [
    [VECTOR_LINE, 95, 5, 5, 95],
    [VECTOR_ELLIPSE, 50, 50, 65, 65],
  ]
}

let mkBonusCurrencyIcon = @(id) @() mkCurrencyImage(id, bonusIconSize, { vplace = ALIGN_CENTER })

let premiumRowsCfg = [
  {
    name = "dailyGold"
    bonus = @(cfg) $"+{cfg?.dailyGold ?? 0}"
    icon = mkBonusCurrencyIcon("gold")
  }
  {
    name = "bonusPlayerExp"
    bonus = @(cfg) bonusMultText(cfg?.expMul ?? 1.0)
    icon = mkBonusCurrencyIcon("playerExp")
    isBattleAdv = true
  }
  {
    name = "bonusUnitExp"
    bonus = @(cfg) bonusMultText(cfg?.expMul ?? 1.0)
    icon = mkBonusCurrencyIcon("unitExp")
    isBattleAdv = true
  }
  {
    name = "slotExpMul"
    bonus = @(cfg) bonusMultText(cfg?.expMul ?? 1.0)
    icon = mkBonusCurrencyIcon("slotExp")
    isBattleAdv = true
  }
  {
    name = "bonusWp"
    bonus = @(cfg) bonusMultText(cfg?.wpMul ?? 1.0)
    icon = mkBonusCurrencyIcon("wp")
    isBattleAdv = true
  }
  {
    name = "bonusGold"
    bonus = @(cfg) bonusMultText(cfg?.goldMul ?? 1.0)
    icon = mkBonusCurrencyIcon("gold")
    isBattleAdv = true
  }
  {
    name = "decalsSlots"
    bonus = @(_) "+2"
    icon = decalsSlotImage
  }
  {
    name = "maxSavedPreset"
    bonus = @(cfg) $"+{(cfg?.maxSavedPreset ?? 0) - (cfg?.noSub.maxSavedPreset ?? 0)}"
    icon = decalsSlotImage
  }
]

let vipRowsCfg = [
  {
    name = "noAds"
    bonus = @(_) ""
    icon = @() {
      size = [bonusIconSize, bonusIconSize]
      children = [
        mkBonusIcon("watch_ads.svg")
        stopIcon
      ]
    }
  }
  {
    name = "purchasesGold"
    bonus = @(cfg) $"+{cfg?.extPurchaseGold ?? 0}"
    icon = mkBonusCurrencyIcon("gold")
  }
  {
    name = "offerSkip"
    bonus = @(cfg) (cfg?.offerSkips ?? 0).tostring()
    icon = @() mkBonusIcon("icon_repeatable.svg")
  }
]

let mkBonusRow = @(bonus, cfg) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    {
      size = [SIZE_TO_CONTENT, bonusIconSize + marginToAlign]
      margin = [marginToAlign, 0, 0, 0]
      flow = FLOW_HORIZONTAL
      gap = smallGap
      valign = ALIGN_CENTER
      children = [
        {
          size = [bonusValueWidth, SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXT
          color = textColor
          text = bonus.bonus(cfg)
          halign = ALIGN_RIGHT
          valign = ALIGN_CENTER
        }.__update(fontSmall)
        bonus.icon()
      ]
    }
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = textColor
      text = loc($"subscription/advantage/{bonus.name}")
    }.__update(fontSmall)
  ]
}

return {
  bonusValueWidth
  bonusIconSize
  marginToAlign
  smallGap
  textColor

  premiumRowsCfg
  vipRowsCfg
  mkBonusRow
}
