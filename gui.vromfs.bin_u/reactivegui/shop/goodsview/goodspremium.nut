from "%globalsDarg/darg_library.nut" import *
let { trim, utf8ToUpper } = require("%sqstd/string.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkBgImg, borderBg, mkGradText, numberToTextForWtFont, mkPricePlate, mkGoodsCommonParts, bgImg,
  oldAmountStrikeThrough, goodsSmallSize, goodsBgH, mkBgParticles
} = require("%rGui/shop/goodsView/sharedParts.nut")
let openPremiumDescription = require("%rGui/shop/premiumDescription.nut")
let { infoGreyButton } = require("%rGui/components/infoButton.nut")


let iconPrem = mkBgImg("ui/gameuiskin/premium_active_big.avif")
  .__update({
    vplace = ALIGN_CENTER
    size = [hdpx(300), hdpx(200)]
  })
let priceBgGrad = mkColoredGradientY(0xFFE26C16, 0xFF7E1C03, 12)
let numFontGrad = mkFontGradient(0xFFF2E46B, 0xFFCE733B, 11, 5, 2)
let daysFontGrad = mkFontGradient(0xFFF2E46B, 0xFFCE733B, 11, 6, 2)

let bgHiglight =  {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0134130A
}

let mkPremiumDaysTitle = @(amount, oldAmount) amount <= 0 ? null : {
  size = [ hdpx(170), flex() ]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  children = [
    mkGradText(numberToTextForWtFont(amount), hdpx(150), numFontGrad).__update({
      pos = [ 0, hdpx(38) ]
      children = oldAmount <= 0 ? null
        : mkGradText(numberToTextForWtFont(oldAmount), hdpx(58), numFontGrad)
            .__update({
              pos = [pw(-90), ph(-15)]
              hplace = ALIGN_RIGHT
              children = oldAmountStrikeThrough
            })
    })
    mkGradText(utf8ToUpper(trim(loc("measureUnits/full/days", { n = amount })
        .replace(amount.tostring(), ""))), hdpx(58), daysFontGrad).__update({
      pos = [ 0, hdpx(173) ]
    })
  ]
}

let getLocNamePremium = @(goods) loc("shop/item/premium/amount", { amount = goods.premiumDays })
let infoBtn = infoGreyButton(
  openPremiumDescription,
  {
    size = [evenPx(60), evenPx(60)]
    margin = [hdpx(12), hdpx(16)]
    hplace = ALIGN_RIGHT
  }
)

let function mkGoodsPremium(goods, onClick, state, animParams) {
  let { premiumDays, viewBaseValue = 0 } = goods
  let premIconAndDaysTitleWrapper = {
    margin = [ sh(1), 0, 0, 0 ]
    size = flex()
    children = [
      iconPrem
      mkPremiumDaysTitle(premiumDays, viewBaseValue)
    ]
  }
  return mkGoodsWrap(onClick,
    @(sf) [
      bgImg
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      premIconAndDaysTitleWrapper
      infoBtn
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNamePremium
  mkGoodsPremium
}
