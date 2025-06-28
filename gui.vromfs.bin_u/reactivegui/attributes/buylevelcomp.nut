from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")

let { balanceGold } = require("%appGlobals/currenciesState.nut")

let { mkDiscountPriceComp, CS_COMMON, CS_NO_BALANCE } = require("%rGui/components/currencyComp.nut")
let { discountTag } = require("%rGui/components/discountTag.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { getSpCostText } = require("attrState.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset, mkFontGradient, gradCircularSqCorners
} = require("%rGui/style/gradients.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { priceBgGradDefault } = require("%rGui/shop/goodsView/sharedParts.nut")


let patternImgAR = 0.71
let blockSize = [hdpxi(500), evenPx(200)]
let patternSize = [(patternImgAR * blockSize[1]).tointeger(), blockSize[1]].map(@(v) ceil(0.5 * v).tointeger())
let numberSize = hdpx(100)
let textGradient = mkFontGradient(0xFFFFFFFF, 0xFF12B2E6)
let priceStyle = CS_COMMON
let priceNoBalanceStyle = CS_NO_BALANCE

let patternImage = {
  size = patternSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{patternSize[0]}:{patternSize[1]}")
  keepAspect = KEEP_ASPECT_NONE
  color = 0x23000000
  children2 = {
    rendObj = ROBJ_SOLID, color = 0x80800000
    size = flex()
  }
}

let pattern = {
  size = flex()
  clipChildren = true
  flow = FLOW_HORIZONTAL
  children = array(ceil(blockSize[0].tofloat() / patternSize[0]).tointeger(),
    {
      flow = FLOW_VERTICAL
      children = array(ceil(blockSize[1].tofloat() / patternSize[1]).tointeger(), patternImage)
    })
}

let numberBox = @(text) {
  size = ph(100)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = ph(71)
      rendObj = ROBJ_BOX
      fillColor = 0xFF33363A
      borderColor = 0xFF52C7E4
      borderWidth = hdpx(3)
      transform = { rotate = 45 }
    }
    mkGradGlowText(text, fontWtLarge, textGradient, {
      pos = [-0.1 * numberSize, 0]
    })
  ]
}

let mkSpText = @(sp) {
  rendObj = ROBJ_TEXT
  text = getSpCostText(sp)
  color = 0xFFFFFFFF
  fontFx = FFT_BLUR
  fxFactor = 24
  fontFxColor = 0x40000000
}.__update(fontTiny)

let mkLevelInfo = @(levels, sp, sf) {
  size = blockSize
  rendObj = ROBJ_SOLID,
  color = 0xFF01364A
  children = [
    {
      size = [0.8 * blockSize[0], 1.5 * blockSize[1]]
      pos = [-0.1 * blockSize[0], 0]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = gradCircularSqCorners
      color = 0xFF12B2E6
      opacity = sf & S_HOVER ? 1.0 : 0.5
    }
    {
      size = flex()
      rendObj = ROBJ_9RECT
      image = gradCircularSmallHorCorners
      texOffs = [gradCircCornerOffset, gradCircCornerOffset]
      screenOffs = array(2, blockSize[1] / 2)
      color = 0xFF39A2C8
      brightness = sf & S_HOVER ? 1.3 : 1
    }
    pattern
    {
      size = flex()
      padding = const [hdpx(10), hdpx(20)]
      valign = ALIGN_CENTER
      halign = ALIGN_LEFT
      gap = hdpx(20)
      children = [
        numberBox($"+{levels}")
        {
          flow = FLOW_VERTICAL
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          children = [
            mkGradGlowText(
              utf8ToUpper(loc("purchase/levels", { levels }))
              fontBig
              textGradient
            )
            sp != 0 ? mkSpText(sp) : null
          ]
        }
      ]
    }
  ]
}

function generateDataDiscount(discountConfig, levelsToMax, isForSlot = false) {
  let res = [{ levels = 1, costMul = 1.0 }]
    .extend(discountConfig)
    .filter(@(v) v.levels <= levelsToMax)

  let maxDiscountLevels = res.top().levels
  let targetLevels = isForSlot ? min(maxDiscountLevels * 2, levelsToMax) : levelsToMax

  if (maxDiscountLevels != levelsToMax && targetLevels <= levelsToMax)
    res.append({ levels = targetLevels, costMul = res.top().costMul ?? 1.0 })

  return res
}

let mkLevelPrice = @(fullCostGold, costGold, costMul, isInProgress) @() {
  watch = [isInProgress, balanceGold]
  size = const [flex(), hdpx(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = isInProgress.get() != null ? spinner
    : [
        {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = priceBgGradDefault
        }
        mkDiscountPriceComp(fullCostGold, costGold, "gold",
          balanceGold.get() >= costGold ? priceStyle : priceNoBalanceStyle)
        discountTag(((1.0 - costMul) * 100 + 0.5).tointeger())
      ]
}

function mkLevelBlock(value, costMul, levelParams, isInProgress, handleClick) {
  if (!value)
    return null
  let { levels, levelsSp, maxLevels } = levelParams
  let { level, exp } = value
  let expTotal = maxLevels?[level].exp ?? 1
  let expLeft = expTotal - exp
  local sp = 0
  local fullCostGold = 0
  for (local l = level; l < level + levels; l++) {
    sp += levelsSp?[l] ?? 0
    fullCostGold += maxLevels?[l].costGold ?? 0
    if (l == level && exp > 0)
      fullCostGold = max(1, (min(1.0, expLeft.tofloat() / expTotal) * fullCostGold + 0.5).tointeger())
  }
  let costGold = (costMul * fullCostGold + 0.5).tointeger()
  let stateFlags = Watched(0)
  let onClick = @() handleClick(value.level, value.level + levels, expTotal - exp, costGold, sp)
  return @() {
    watch = stateFlags
    size = [blockSize[0], SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    gap = hdpx(40)
    children = [
      mkLevelInfo(levels, sp, stateFlags.get())
      mkLevelPrice(fullCostGold, costGold, costMul, isInProgress)
    ]

    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

return {
  generateDataDiscount
  priceNoBalanceStyle
  patternImgAR
  mkLevelBlock
  mkLevelInfo
  priceStyle
  blockSize
}
