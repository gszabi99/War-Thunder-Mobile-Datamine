from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { balanceGold } = require("%appGlobals/currenciesState.nut")

let { mkDiscountCorner, pricePlateH, mkBgParticles, mkSlotBgImg } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkDiscountPriceComp, CS_COMMON, CS_NO_BALANCE } = require("%rGui/components/currencyComp.nut")
let { mkGradGlowText, mkGradText } = require("%rGui/components/gradTexts.nut")
let { textButtonPurchase } = require("%rGui/components/textButton.nut")
let { selectColor, textColor } = require("%rGui/style/stdColors.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { spinner } = require("%rGui/components/spinner.nut")


let blockSize = [hdpx(500), hdpx(220)]
let numberSize = hdpx(100)
let textGradient = mkFontGradient(textColor, selectColor, 11, 6, 2)

let numberBox = @(text) {
  size = ph(90)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = ph(71)
      rendObj = ROBJ_BOX
      fillColor = 0xFF33363A
      borderColor = selectColor
      borderWidth = hdpx(5)
      transform = { rotate = 45 }
    }
    mkGradGlowText(text, fontWtLarge, textGradient, {
      pos = [-0.1 * numberSize, 0]
    })
  ]
}

let spIconText = {
  rendObj = ROBJ_TEXT
  text = "⋥"
  color = textColor
  fontFx = FFT_BLUR
  fxFactor = 24
  fontFxColor = 0x40000000
}.__update(fontSmall)

let mkLevelInfo = @(levels, sp) {
  size = blockSize
  rendObj = ROBJ_BOX
  borderColor = textColor
  borderWidth = hdpx(2)
  padding = hdpx(2)
  children = [
    mkSlotBgImg()
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
              fontWtLarge
              textGradient
            )
            sp == 0 ? null
              : {
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_CENTER
                  gap = hdpx(5)
                  children = [
                    spIconText
                    mkGradText(sp, fontWtSmall, textGradient)
                  ]
                }
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
  size = static [flex(), pricePlateH]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = isInProgress.get() != null ? spinner
    : [
        textButtonPurchase(null, @() null, { ovr = { size = flex(), minWidth = 0, behavior = null } })
        mkDiscountPriceComp(fullCostGold, costGold, "gold",
          balanceGold.get() >= costGold ? CS_COMMON : CS_NO_BALANCE)
        mkDiscountCorner(((1.0 - costMul) * 100 + 0.5).tointeger())
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
  let bgParticles = mkBgParticles(blockSize)
  return @() {
    watch = stateFlags
    size = [blockSize[0], SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    gap = -hdpx(2)
    children = [
      {
        size = flex()
        children = bgParticles
      }
      mkLevelInfo(levels, sp)
      mkLevelPrice(fullCostGold, costGold, costMul, isInProgress)
    ]
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

return {
  generateDataDiscount
  mkLevelBlock
}
