from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_level, unitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { getSpCostText } = require("%rGui/unitAttr/unitAttrState.nut")
let { balanceGold, GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset, mkFontGradient, gradCircularSqCorners,
  mkColoredGradientY
} = require("%rGui/style/gradients.nut")
let { mkDiscountPriceComp, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { discountTag } = require("%rGui/components/discountTag.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkGradGlowText } = require("%rGui/components/gradTexts.nut")


let WND_UID = "buyUnitLevelWnd" //we no need several such messages at all.
let patternImgAR = 0.71
let blockSize = [hdpxi(500), evenPx(200)]
let patternSize = [(patternImgAR * blockSize[1]).tointeger(), blockSize[1]].map(@(v) ceil(0.5 * v).tointeger())
let numberSize = hdpx(100)
let textGradient = mkFontGradient(0xFFFFFFFF, 0xFF12B2E6)
let priceBgGradient = mkColoredGradientY(0xFF00AAF8, 0xFF007683, 12)
let priceBgBorder = 0x7F003570  //0xB2004A9D//0xFF006AE1
let priceStyle = CS_COMMON
let priceNoBalanceStyle = CS_COMMON.__merge({ textColor = 0xFFF03535 })

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() myUnits.value?[unitName.value])
let levelsToMax = Computed(@() (unit.value?.levels.len() ?? 0) - (unit.value?.level ?? 0))
let needShowWnd = keepref(Computed(@() levelsToMax.value > 0))

let close = @() unitName(null)

registerHandler("closeBuyUnitLevelWnd", @(_) close())

let function onClickPurchase(unitNameV, curLevel, tgtLevel, nextLevelExp, costGold) {
  if (unitInProgress.value != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, $"{unitNameV} {curLevel} +{tgtLevel - curLevel}")
  if (!showNoBalanceMsgIfNeed(costGold, GOLD, bqPurchaseInfo, close))
    buy_unit_level(unitNameV, curLevel, tgtLevel, nextLevelExp, costGold, "closeBuyUnitLevelWnd")
}

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
  size = [ph(100), ph(100)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = [ph(71), ph(71)]
      rendObj = ROBJ_BOX
      fillColor = 0xFF33363A
      borderColor = 0xFF52C7E4
      borderWidth = hdpx(3)
      transform = { rotate = 45 }
    }
    mkGradGlowText(text, fontWtVeryLarge, textGradient, {
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
      flow = FLOW_HORIZONTAL
      padding = [hdpx(10), hdpx(20)]
      valign = ALIGN_CENTER
      gap = hdpx(20)
      children = [
        numberBox($"+{levels}")
        {
          pos = [0, hdpx(12)]
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            mkGradGlowText(
              utf8ToUpper(loc("purchase/levels", { levels }))
              fontWtLarge
              textGradient
            )
            mkSpText(sp)
          ]
        }
      ]
    }
  ]
}

let mkLevelPrice = @(fullCostGold, costGold, costMul) @() {
  watch = [unitInProgress, balanceGold]
  size = [flex(), hdpx(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = unitInProgress.value != null ? spinner
    : [
        {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = priceBgGradient
        }
        {
          size = flex()
          rendObj = ROBJ_BOX
          fillColor = 0
          borderColor = priceBgBorder
          borderWidth = hdpx(3)
        }
        mkDiscountPriceComp(fullCostGold, costGold, "gold",
          balanceGold.value >= costGold ? priceStyle : priceNoBalanceStyle)
        discountTag(((1.0 - costMul) * 100 + 0.5).tointeger())
      ]
}

let function mkLevelBlock(levels, costMul, unitV, levelsSp) {
  let { level, exp } = unitV
  let expTotal = unitV.levels?[level].exp ?? 1
  let expLeft = expTotal - exp
  local sp = 0
  local fullCostGold = 0
  for (local l = level; l < level + levels; l++) {
    sp += levelsSp?[l] ?? 0
    fullCostGold += unitV.levels?[l].costGold ?? 0
    if (l == level && exp > 0)
      fullCostGold = max(1, (min(1.0, expLeft.tofloat() / expTotal) * fullCostGold + 0.5).tointeger())
  }
  let costGold = (costMul * fullCostGold + 0.5).tointeger()
  let stateFlags = Watched(0)
  let onClick = @() onClickPurchase(unitV.name, unitV.level, unitV.level + levels, expTotal - exp, costGold)
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
      mkLevelInfo(levels, sp, stateFlags.value)
      mkLevelPrice(fullCostGold, costGold, costMul)
    ]

    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let function wndContent() {
  let res = { watch = [unit, levelsToMax, campConfigs] }
  let levelsSp = campConfigs.value?.unitLevelsSp?[unit.value?.attrPreset].levels
  if (levelsSp == null)
    return res
  return res.__update({
    flow = FLOW_HORIZONTAL
    padding = buttonsHGap
    gap = buttonsHGap
    children = [{ levels = 1, costMul = 1.0 }]
      .extend(campConfigs.value?.unitLevelsDiscount ?? [])
      .filter(@(v) v.levels <= levelsToMax.value)
      .map(@(v) mkLevelBlock(v.levels, v.costMul, unit.value, levelsSp))
  })
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = @() msgBoxBg.__merge({
    watch = unitName
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      msgBoxHeaderWithClose(loc("header/unitLevelBoost", { unitName = loc(getUnitLocId(unitName.value)) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      wndContent
    ]
  })
  animations = wndSwitchAnim
}))

if (needShowWnd.value)
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @(uName) unitName(uName)