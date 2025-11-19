from "%globalsDarg/darg_library.nut" import *
let { trim, utf8ToUpper } = require("%sqstd/string.nut")
let { G_PREMIUM } = require("%appGlobals/rewardType.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkBgImg, borderBgGold, numberToTextForWtFont, mkPricePlate, mkGoodsCommonParts, mkSlotBgImg, mkBorderByCurrency,
  oldAmountStrikeThrough, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimitAndEndTime
} = require("%rGui/shop/goodsView/sharedParts.nut")
let openPremiumDescription = require("%rGui/shop/premiumDescription.nut")
let { infoGreyButton } = require("%rGui/components/infoButton.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")


let mkIconPrem = @() mkBgImg("ui/gameuiskin/premium_active_big.avif:0:P")
  .__update({
    vplace = ALIGN_CENTER
    size = const [hdpx(300), hdpx(200)]
  })
let numFontGrad = mkFontGradient(0xFFF2E46B, 0xFFCE733B, 11, 5, 2)
let daysFontGrad = mkFontGradient(0xFFF2E46B, 0xFFCE733B, 11, 6, 2)

let bgHiglight =  {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0134130A
}

let mkPremiumDaysTitle = function(amount, oldAmount) {
  if (amount <= 0)
    return null

  let titleWidth = hdpx(170)
  let fontSize = hdpx(58)
  let daysText = utf8ToUpper(trim(loc("measureUnits/full/days", { n = amount }).replace(amount.tostring(), "")))
  let daysWidth = calc_str_box(daysText, { fontSize })[0]
  let daysOffset = min(0, titleWidth - daysWidth + hdpx(30))

  return {
    size = [ titleWidth, flex() ]
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    children = [
      {
        pos = [ 0, hdpx(38) ]
        children = [
          mkGradGlowText(numberToTextForWtFont(amount), fontWtExtraLarge, numFontGrad)
        ]
      }
      oldAmount <= 0 ? null
        : mkGradGlowText(numberToTextForWtFont(oldAmount), fontWtBig, numFontGrad, {
            pos = [-hdpx(25), hdpx(5)]
            hplace = ALIGN_RIGHT
            children = oldAmountStrikeThrough
          })
      mkGradGlowText(daysText, fontWtBig, daysFontGrad, {
        pos = [ daysOffset, hdpx(173) ]
      })
    ]
  }
}

let getLocNamePremium = @(goods) loc("shop/item/premium/amount",
  { amount = goods?.rewards.findvalue(@(r) r.gType == G_PREMIUM)?.count
      ?? goods?.premiumDays 
      ?? 0
  })
let infoBtn = infoGreyButton(
  openPremiumDescription,
  {
    size = [evenPx(60), evenPx(60)]
    color = 0x50000000
    margin = hdpx(12)
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
  }
)

function mkGoodsPremium(goods, onClick, state, animParams, addChildren) {
  let { rewards = null, viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let premiumDays = rewards?.findvalue(@(r) r.gType == G_PREMIUM)?.count
    ?? goods?.premiumDays 
    ?? 0
  let premIconAndDaysTitleWrapper = {
    size = flex()
    children = [
      mkIconPrem()
      mkPremiumDaysTitle(premiumDays, viewBaseValue)
    ]
  }
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBgGold, isFreeReward, price?.currencyId)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      premIconAndDaysTitleWrapper
      infoBtn
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNamePremium
  mkGoodsPremium
}
