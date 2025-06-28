from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkCurrencyAmountTitle, mkPricePlate, mkGoodsCommonParts,
  mkSlotBgImg, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimitAndEndTime,
  titleFontGradConsumables, mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")

let icons = {
  ship_tool_kit = "ui/gameuiskin/shop_consumables_repair.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin/shop_consumables_smoke.avif"
  tank_tool_kit_expendable = "ui/gameuiskin/shop_consumables_tank_repair.avif"
  tank_medical_kit = "ui/gameuiskin/shop_consumables_tank_medical_kit.avif"
  tank_extinguisher = "ui/gameuiskin/shop_consumables_tank_extinguisher.avif"
  spare = "ui/gameuiskin/shop_consumables_tank_cards.avif"
  ircm_kit = "ui/gameuiskin/shop_consumables_ircm.avif"
}

let imgSize = hdpx(500)
let slotNameBG = {
  hplace = ALIGN_RIGHT
  color = 0x80000000
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = [0, 0, hdpx(200), hdpx(200)]
  texOffs = gradCircCornerOffset
  margin = const [ hdpx(4), hdpx(10)]
}

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let itemImageOptionsStack = [
  [{ size = imgSize, pos = [0, -hdpx(91)] }],
  [
    { size = hdpx(400), pos = [0, -hdpx(15)] sortOrder = 2}
    { size = hdpx(400), pos = [hdpx(100), -hdpx(35)] sortOrder = 1}
  ],
  [
    { size = hdpx(350), pos = [hdpx(0), hdpx(10)] sortOrder = 2}
    { size = hdpx(350), pos = [hdpx(100), -hdpx(35)] sortOrder = 1}
    { size = hdpx(350), pos = [hdpx(250), hdpx(10)] sortOrder = 3}
  ]
]

let mkImg = @(id, size, pos, sortOrder = null) id not in icons ? null : {
  key = sortOrder
  size
  pos
  sortOrder
  rendObj = ROBJ_IMAGE
  image = Picture($"{icons[id]}:{size}:{size}:P")
  keepAspect = true
}

let mkImgs = @(ids, imageOptions) {
  size = flex()
  sortChildren = true
  children = imageOptions.map(@(cfg, idx) idx not in ids ? null : mkImg(ids[idx], cfg.size, cfg.pos, cfg?.sortOrder))
}

function getConsumablesInfo(goods) {
  let { items } = goods
  let data = []

  foreach (id, count in items) {
    data.append({ id, amount = count })
  }

  return data.sort(@(a, b) (orderByItems?[a.id] ?? 0) <=> (orderByItems?[b.id] ?? 0))
}

function getLocNameConsumables(goods) {
  let data = getConsumablesInfo(goods)
  let amount = data?[0].amount ?? 0

  return data.len() != 1
    ? loc($"goods/{goods.id}")
    : loc($"consumable/amount/{data[0].id}", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsConsumables(goods, onClick, state, animParams, addChildren) {
  let data = getConsumablesInfo(goods)
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let nameConsumable = data.len() != 1 ? loc($"goods/{goods.id}") : loc($"item/{data[0].id}")
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      sf & S_HOVER ? bgHiglight : null
      mkImgs(data.map(@(item) item.id), itemImageOptionsStack?[data.len() - 1] ?? itemImageOptionsStack.top())
      border
      slotNameBG.__merge({
        size = [hdpx(270), viewBaseValue > 0 ? hdpx(175) : hdpx(135)]
        padding = const [hdpx(20), 0]
        children = mkCurrencyAmountTitle(data.map(@(item) item.amount), viewBaseValue, titleFontGradConsumables, nameConsumable)
      })
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNameConsumables
  mkGoodsConsumables
}
