from "%globalsDarg/darg_library.nut" import *
let { mkStreakIcon, mkStreakWithMultiplier, prepareStreaksArray, getUnlockLocText, getUnlockDescLocText } = require("%rGui/unlocks/streakPkg.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { WP } = require("%appGlobals/currenciesState.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")

let gradientWidth = sw(100)
let contentWidth = saSize[0]
let gap = hdpx(20)
let itemSize = hdpx(120)
let hintSideGradWidth = hdpx(300)
let bgColor = 0x60606060

let maxStreaksAnimTimeTotal = 1.0
let streakAnimTime = 0.4
let streakAppearTime = 0.2
let streakBlinkTime = 0.3
let streakBlinkDelayTime = streakAnimTime - streakBlinkTime

let mkText = @(text) {
  size = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text
}.__update(fontTinyShaded)

let mkTextArea = @(text) {
  halign = ALIGN_CENTER
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  text
  maxWidth = hdpx(600)
}.__update(fontTinyShaded)

function mkAppearAnim(children, idx, startTime, delayPerItem, offset) {
  let appearDelay = startTime + idx * delayPerItem
  let blinkDelay = appearDelay + streakBlinkDelayTime
  return {
    key = {}
    transform = { translate = [idx * offset, 0] }
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = appearDelay, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, delay = appearDelay, duration = streakAppearTime,
        easing = OutQuad, play = true }
      { prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3], delay = blinkDelay, duration = streakBlinkTime,
        easing = Blink, play = true }
    ]
    children
  }
}


function mkInfoButton(val) {
  let { id, wp = 0, completed = 1 } = val
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    watch = stateFlags
    key
    behavior = Behaviors.Button
    size = [itemSize, itemSize]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    children = mkStreakWithMultiplier(id, completed, itemSize, val?.stage)
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() {
      content = {
        flow = FLOW_VERTICAL
        sound = { attach = "click" }
        gap
        halign = ALIGN_CENTER
        valign =  ALIGN_CENTER
        children = [
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            gap
            children = [
              mkStreakIcon(id, itemSize, val?.stage)
              mkText(getUnlockLocText(id, val?.stage ?? completed))
            ]
          }
          mkTextArea(getUnlockDescLocText(id, val?.stage ?? completed))
          mkCurrencyComp(wp, WP, CS_SMALL).__update({hplace = ALIGN_CENTER})
        ]
      }
      flow = FLOW_HORIZONTAL
    })
  }
}


let mkAchievementsComp = @(streaksArr, startAnimTime, delayPerItem, offset) streaksArr.len() == 0 ? null : {
  size = FLEX_H
  margin = const [0, 0, hdpx(30), 0]
  children = [
    {
      size = [gradientWidth, flex()]
      hplace = ALIGN_CENTER
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      texOffs = [0,  gradDoubleTexOffset]
      screenOffs = [0, hintSideGradWidth]
      color = bgColor
    }
    {
      size = [streaksArr.len() * offset, SIZE_TO_CONTENT]
      margin = hdpx(20)
      hplace = ALIGN_CENTER
      children = {
        size = [flex(), itemSize]
        children = streaksArr.map(@(val, idx) mkAppearAnim(mkInfoButton(val), idx, startAnimTime, delayPerItem, offset))
      }
    }
  ]
}

let sortStreaks = @(a, b) (b?.wp ?? 0) <=> (a?.wp ?? 0)
  || (b?.completed ?? 0) <=> (a?.completed ?? 0)
  || a.id <=> b.id

return function achievementsBlock(debrData, startAnimTime) {
  let { streaks = {} } = debrData
  let streaksArr = prepareStreaksArray(streaks).sort(sortStreaks)
  let streaksArrSize = streaksArr.len()
  let delayPerItem = min(streakAppearTime, (maxStreaksAnimTimeTotal - streakAnimTime) / max(1, streaksArrSize - 1))
  local offset = itemSize + gap
  if ((itemSize + gap) * streaksArrSize > contentWidth)
    offset = contentWidth / streaksArrSize;
  return {
    achievementsAnimTime = streaksArrSize > 0
      ? ((streaksArrSize - 1) * delayPerItem) + streakAppearTime
      : 0
    achievementsComp = streaksArrSize > 0
      ? mkAchievementsComp(streaksArr, startAnimTime, delayPerItem, offset)
      : null
  }
}
