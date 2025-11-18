from "%globalsDarg/darg_library.nut" import *
let { G_ITEM } = require("%appGlobals/rewardType.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
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
  firework_kit = "ui/gameuiskin/icon_fireworks.avif"
}

let imgCustomCfg = {
  firework_kit = {
    scale = 0.4
    ovr = {
      pos = [0, 0]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
    }
  }
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

function mkImg(id, baseSize, pos, sortOrder = null) {
  if (id not in icons)
    return null
  let { scale = 1, ovr = {} } = imgCustomCfg?[id]
  let size = (baseSize * scale).tointeger()
  return {
    key = sortOrder
    size
    pos
    sortOrder
    rendObj = ROBJ_IMAGE
    image = Picture($"{icons[id]}:{size}:{size}:P")
    keepAspect = true
  }.__update(ovr)
}

let mkImgs = @(ids, imageOptions) {
  size = flex()
  sortChildren = true
  children = imageOptions.map(@(cfg, idx) idx not in ids ? null : mkImg(ids[idx], cfg.size, cfg.pos, cfg?.sortOrder))
}

function getConsumablesInfo(goods) {
  let { rewards = null, items = {} } = goods
  let data = rewards?.filter(@(r) r.gType == G_ITEM) ?? []
  if (rewards == null) 
    foreach (id, count in items)
      data.append({ id, count })
  return data.sort(@(a, b) (orderByItems?[a.id] ?? 0) <=> (orderByItems?[b.id] ?? 0))
}

function getLocNameConsumables(goods) {
  let { id = "", count = 0 } = getConsumablesInfo(goods)?[0]
  return id == "" ? loc($"goods/{goods.id}")
    : loc($"consumable/amount/{id}", { amountTxt = decimalFormat(count), amount = count })
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
        children = mkCurrencyAmountTitle(data.map(@(item) item.count), viewBaseValue, titleFontGradConsumables, nameConsumable)
      })
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

return {
  getLocNameConsumables
  mkGoodsConsumables
}
