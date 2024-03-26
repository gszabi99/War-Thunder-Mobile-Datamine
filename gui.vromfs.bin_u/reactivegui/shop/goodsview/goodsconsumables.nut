from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { mkColoredGradientY, mkFontGradient,
  gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, txt,borderBg, mkCurrencyAmountTitle, mkPricePlate, mkGoodsCommonParts,
  mkSlotBgImg, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg
} = require("%rGui/shop/goodsView/sharedParts.nut")

let icons = {
  ship_tool_kit = "ui/gameuiskin#shop_consumables_repair.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin#shop_consumables_smoke.avif"
  tank_tool_kit_expendable = "ui/gameuiskin#shop_consumables_tank_repair.avif"
  tank_extinguisher = "ui/gameuiskin#shop_consumables_tank_extinguisher.avif"
  spare = "ui/gameuiskin#shop_consumables_tank_cards.avif"
  ircm_kit = "ui/gameuiskin#shop_consumables_ircm.avif"
}

let priceBgGrad = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGrad = mkFontGradient(0xFFffFFFF, 0xFF8bdeea, 11, 6, 2)
let imgSize = hdpx(500)
let slotNameBG = {
  hplace = ALIGN_RIGHT
  color = 0x80000000
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = [0, 0, hdpx(200), hdpx(200)]
  texOffs = gradCircCornerOffset
  margin = [ hdpx(4), hdpx(10)]
}

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let mkImg = @(itemId) {
  size = [ imgSize, imgSize ]
  pos = [ 0, -hdpx(91) ]
  rendObj = ROBJ_IMAGE
  image = Picture(icons?[itemId] ?? "")
  keepAspect = KEEP_ASPECT_FIT
}

function getConsumablesInfo(goods) {
  let { items } = goods
  let itemId = orderByItems.findindex(@(_, id) items?[id] != null)  ?? items.findindex(@(_) true) ?? ""
  let amount = items?[itemId] ?? 0
  return { itemId, amount }
}

function getLocNameConsumables(goods) {
  let { itemId, amount } = getConsumablesInfo(goods)
  return itemId != ""
    ? loc($"consumable/amount/{itemId}", { amountTxt = decimalFormat(amount), amount })
    : goods.id
}

function mkGoodsConsumables(goods, onClick, state, animParams) {
  let { itemId, amount } = getConsumablesInfo(goods)
  let { viewBaseValue = 0, isShowDebugOnly = false } = goods
  let nameConsumable =  loc($"item/{itemId}")
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      mkImg(itemId)
      slotNameBG.__merge({
        size = [hdpx(270), viewBaseValue > 0 ? hdpx(175) : hdpx(135)]
        padding = [hdpx(20), 0]
        children = amount > 0
          ? mkCurrencyAmountTitle(amount, viewBaseValue, titleFontGrad, nameConsumable)
          : txt({ hplace = ALIGN_RIGHT, text = goods.id, margin = [ hdpx(25), hdpx(35), 0, 0 ] })
      })
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNameConsumables
  mkGoodsConsumables
}
