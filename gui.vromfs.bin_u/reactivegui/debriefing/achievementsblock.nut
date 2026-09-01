from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/currenciesState.nut" import WP
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_SMALL
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach
from "%rGui/unlocks/streakPkg.nut" import mkStreakIcon, mkStreakWithMultiplier, prepareStreaksArray, getUnlockLocText,
  getUnlockDescLocText


const gradientWidth = sw(100)
let contentWidth = saSize[0]
const gap = hdpx(20)
const itemSize = hdpx(120)
const hintSideGradWidth = hdpx(300)
const bgColor = 0x60606060

const maxStreaksAnimTimeTotal = 1.0
const streakAnimTime = 0.4
const streakAppearTime = 0.2
const streakBlinkTime = 0.3
const streakBlinkDelayTime = streakAnimTime - streakBlinkTime

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
    size = const [itemSize, itemSize]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
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
  children = [
    {
      size = const [gradientWidth, FLEX]
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
        size = const [FLEX, itemSize]
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
