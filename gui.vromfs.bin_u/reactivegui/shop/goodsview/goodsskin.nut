from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { getUnitPresentation, getUnitClassFontIcon, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getGoodsAsOfferIcon } = require("%appGlobals/config/goodsPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { mkGoodsWrap, borderBg, mkPricePlate, mkGoodsCommonParts,
  goodsSmallSize, goodsBgH, underConstructionBg, mkEndTime,
  limitFontGrad, mkBorderByCurrency, mkBgImg
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkGradRank, mkGradGlowMultiLine } = require("%rGui/components/gradTexts.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { ALL_PURCHASED } = require("%rGui/shop/goodsStates.nut")


let skinSize =  (0.5 * goodsBgH).tointeger()
let skinBorderRadius = round(skinSize * 0.2).tointeger()
let skinBorderWidth = hdpxi(3)
let headerPadding = const [hdpx(15), hdpx(34), 0, hdpx(34)]
let headerWidth = goodsSmallSize[0] - headerPadding[1] - headerPadding[3]
let lockIconSize = const [hdpxi(37),hdpxi(48)]

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let getLocNameSkin = @(goods) comma.join(
  goods.skins
    .keys()
    .map(@(unitName) loc("reward/skin_for", { unitName = loc(getUnitLocId(unitName)) })))


function mkImgs(skinName, unitName, hasUnit, unitImg) {
  let { image } = getSkinPresentation(unitName, skinName)
  let size = [goodsSmallSize[0], goodsBgH]
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"{unitImg}:{size[0]}:{size[1]}:P")
    keepAspect = KEEP_ASPECT_FIT
    imageHalign = ALIGN_LEFT
    imageValign = ALIGN_BOTTOM
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    children = {
      size = skinSize + 2 * skinBorderWidth
      margin = hdpx(20)
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      rendObj = ROBJ_BOX
      fillColor = 0x80000000
      borderRadius = skinBorderRadius + skinBorderWidth

      children = @() {
        watch = hasUnit
        size = skinSize
        rendObj = ROBJ_BOX
        fillColor = 0xFFFFFFFF
        borderRadius = skinBorderRadius
        image = Picture($"ui/gameuiskin#{image}:{skinSize}:{skinSize}:P")
        children = hasUnit.get() ? null
          : {
              size = lockIconSize
              margin = const [hdpx(10), hdpx(10)]
              vplace = ALIGN_BOTTOM
              rendObj = ROBJ_IMAGE
              image = Picture($"ui/gameuiskin#lock_icon.svg:{lockIconSize[0]}:{lockIconSize[1]}:P")
              keepAspect = true
            }
      }
    }
  }
}

let mkMRank = @(mRank) @() {
  watch = mRank
  padding = const [hdpx(10), hdpx(15)]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = mkGradRank(mRank.get())
}

let mkBg = @(unit) @() {
  watch = unit
  size = flex()
  children = unit.get() == null ? null
    : [
        mkBgImg($"!ui/unitskin#flag_{unit.get().country}.avif")
        mkBgImg($"!ui/unitskin#bg_ground_{unit.get().unitType}.avif")
      ]
}

let mkHeader = @(unit) @() {
  watch = unit
  size = flex()
  flow = FLOW_VERTICAL
  padding = headerPadding
  halign = ALIGN_RIGHT
  children = unit.get() == null ? null
    : [
        loc("reward/skin_for", { unitName = loc(getUnitLocId(unit.get().name)).replace(" ", nbsp) })
        getUnitClassFontIcon(unit.get())
      ]
        .map(@(t) mkGradGlowMultiLine(t, fontWtMedium, limitFontGrad, headerWidth, { halign = ALIGN_RIGHT }))
}

function mkGoodsSkin(goods, onClick, state, animParams, addChildren) {
  let { isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  let unitName = goods.skins.findindex(@(_) true) ?? ""
  let skinName = goods.skins?[unitName] ?? ""
  let unit = Computed(@() serverConfigs.get()?.allUnits[unitName])
  let hasUnit = Computed(@() unitName in servProfile.get()?.units)
  let isPurchased = Computed(@() servProfile.get()?.skins[unitName][skinName] ?? false)
  let ovrState = Computed(@() state.get() | (isPurchased.get() ? ALL_PURCHASED : 0))

  let images = mkImgs(skinName, unitName, hasUnit,
    getGoodsAsOfferIcon(goods.id) ?? getUnitPresentation(unitName).image)
  let bg = mkBg(unit)
  let header = mkHeader(unit)
  let mRankText = mkMRank(Computed(@() serverConfigs.get()?.allUnits[unitName].mRank ?? 1))
  let endTimeText = mkEndTime(goods, { pos = [hdpx(-50), 0] })
  return mkGoodsWrap(
    goods,
    @() isPurchased.get() ? null
      : hasUnit.get() ? onClick()
      : openMsgBox({ text = loc("msg/needUnitToBuySkin") }),
    unitName == "" ? null
      : @(sf, _) [
          bg
          isShowDebugOnly ? underConstructionBg : null
          border
          sf & S_HOVER ? bgHiglight : null
          images
          header
          mRankText
          endTimeText
        ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, ovrState, animParams),
    { size = goodsSmallSize })
}

return {
  mkGoodsSkin
  getLocNameSkin
}