from "%globalsDarg/darg_library.nut" import *
let { trim, utf8ToUpper } = require("%sqstd/string.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkBgImg, borderBg, numberToTextForWtFont, mkPricePlate, mkGoodsCommonParts, mkSlotBgImg,
  oldAmountStrikeThrough, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimit
} = require("%rGui/shop/goodsView/sharedParts.nut")
let openPremiumDescription = require("%rGui/shop/premiumDescription.nut")
let { infoGreyButton } = require("%rGui/components/infoButton.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")


let mkIconPrem = @() mkBgImg("ui/gameuiskin/premium_active_big.avif:0:P")
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
          oldAmount <= 0 ? null
            : mkGradGlowText(numberToTextForWtFont(oldAmount), fontWtBig, numFontGrad, {
                pos = [pw(-90), ph(-15)]
                hplace = ALIGN_RIGHT
                children = oldAmountStrikeThrough
              })
        ]
      }
      mkGradGlowText(daysText, fontWtBig, daysFontGrad, {
        pos = [ daysOffset, hdpx(173) ]
      })
    ]
  }
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

function mkGoodsPremium(goods, onClick, state, animParams) {
  let { premiumDays, viewBaseValue = 0, isShowDebugOnly = false } = goods
  let premIconAndDaysTitleWrapper = {
    margin = [ sh(1), 0, 0, 0 ]
    size = flex()
    children = [
      mkIconPrem()
      mkPremiumDaysTitle(premiumDays, viewBaseValue)
    ]
  }
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      borderBg
      sf & S_HOVER ? bgHiglight : null
      premIconAndDaysTitleWrapper
      infoBtn
      mkGoodsLimit(goods)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNamePremium
  mkGoodsPremium
}
