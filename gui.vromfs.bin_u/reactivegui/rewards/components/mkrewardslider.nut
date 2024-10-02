from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, simpleVerGrad } = require("%rGui/style/gradients.nut")

let defColor = 0xFFFFFFFF
let secondaryColor = 0xFFC5C5C5
let plateHeight = hdpx(8)
let plateGap = hdpx(8)
let timeToDelay = 5.0
let durationTime = 0.5
let defaultSlots = 2

let triggerStartAnimSlider = "triggerStartAnimSlider"

let mkRewardPlateBlure = @() {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = simpleVerGrad
  color = 0xFF000000
  opacity = 0.9
  transform = {
    scale = [1, 1.1]
  }
}

let mkSliderPlate = @(isActive, size) {
  rendObj = ROBJ_BOX
  size
  fillColor = isActive ? defColor : secondaryColor
}

let mkTitleText = @(text, maxWidth) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth
  halign = ALIGN_CENTER
  text
  color = secondaryColor
}.__update(fontVeryTinyAccented)

function mkRewardSlider(rewards, onClick, rStyle = {}) {
  let activeSlideIdx = Watched(0)
  activeSlideIdx.subscribe(@(idx) idx == 0 ? resetTimeout(timeToDelay, @() anim_start(triggerStartAnimSlider)) : null)

  let slidesCount = rewards.len()
  let size = getRewardPlateSize(defaultSlots, rStyle)
  let containerMask = mkBitmapPictureLazy(size[0], 4, mkGradientCtorDoubleSideX(0, defColor, 0))
  let row = rewards.map(@(rInfo) {
    size
    children = [
      mkRewardPlate(rInfo, rStyle)
      mkRewardPlateBlure()
    ]
  })
  let plateSize = [(size[0] - (slidesCount - 1) * plateGap) / slidesCount, plateHeight]

  function mkAnimations() {
    let animations = []
    local direction = 1
    local currentIdx = 0
    for (local i = 0; i < slidesCount * 2 - 2; i++) {
      local nextIdx = currentIdx + direction
      if(nextIdx >= slidesCount) {
        direction = -1
        nextIdx = currentIdx + direction
      } else if(nextIdx < 0) {
        direction = 1
        nextIdx = currentIdx + direction
      }

      let fromPos = [-size[0] * currentIdx, 0]
      let toPos = [-size[0] * nextIdx, 0]

      animations.append({
        prop = AnimProp.translate
        from = fromPos
        to = fromPos
        duration = timeToDelay
        delay = i * (durationTime + timeToDelay) - timeToDelay
        trigger = triggerStartAnimSlider
      })

      animations.append({
        prop = AnimProp.translate
        from = fromPos
        to = toPos
        duration = durationTime
        delay = i * (durationTime + timeToDelay)
        easing = InQuad
        trigger = triggerStartAnimSlider
        onFinish = @() activeSlideIdx.set(nextIdx)
      })
      currentIdx = nextIdx
    }
    return animations
  }

  return {
    size = [size[0], size[1] + plateHeight + plateGap]
    halign = ALIGN_LEFT
    rendObj = ROBJ_MASK
    image = containerMask()
    clipChildren = true
    behavior = Behaviors.Button
    onAttach = @() anim_start(triggerStartAnimSlider)
    onClick
    sound = { click = "click" }
    children = [
      {
        flow = FLOW_VERTICAL
        gap = hdpx(5)
        children = [
          {
            key = {}
            flow = FLOW_HORIZONTAL
            transform = {}
            animations = mkAnimations()
            children = row
          }
          @() {
            watch = activeSlideIdx
            vplace = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            gap = plateGap
            children = rewards.map(@(_, idx) mkSliderPlate(activeSlideIdx.get() == idx, plateSize))
          }
        ]
      }
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_TOP
        children = mkTitleText(loc("events/choosePrize"), size[0])
      }
    ]
  }
}

return { mkRewardSlider, plateHeight, plateGap, defaultSlots }
