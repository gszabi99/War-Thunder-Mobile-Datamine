from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { getRewardPlateSize, rewardTicketDefaultSlots } = require("%rGui/rewards/rewardStyles.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX } = require("%rGui/style/gradients.nut")

let defColor = 0xFFFFFFFF
let secondaryColor = 0xFFC5C5C5
let pointSize = hdpx(11)
let timeToDelay = 5.0
let durationTime = 0.5

let triggerStartAnimSlider = "triggerStartAnimSlider"

let mkSliderPoint = @(isActive) {
  rendObj = ROBJ_IMAGE
  size = [pointSize, pointSize]
  image = Picture($"ui/gameuiskin#circle.svg:{pointSize}:{pointSize}:P")
  color = isActive ? defColor : secondaryColor
}

let mkRewardPlateBg = @(size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/offer_item_slot_bg.avif:{size[0]}:{size[1]}:P")
}

function mkRewardSlider(rewards, rewardCtors, onClick, rStyle = {}) {
  let activeSlideIdx = Watched(0)
  activeSlideIdx.subscribe(@(idx) idx == 0 ? resetTimeout(timeToDelay, @() anim_start(triggerStartAnimSlider)) : null)

  let slidesCount = rewards.len()
  let size = getRewardPlateSize(rewardTicketDefaultSlots, rStyle)
  let containerMask = mkBitmapPictureLazy(size[0], 4, mkGradientCtorDoubleSideX(0, defColor, 0))

  let mkRewardPlateImage = @(r, rewardStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).image(r, rewardStyle)
  let mkRewardPlateTexts = @(r, rewardStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).texts(r, rewardStyle)

  let mkRewardPlate = @(r, rewardStyle) {
    transform = {}
    children = [
      mkRewardPlateBg(size)
      mkRewardPlateImage(r, rewardStyle)
      mkRewardPlateTexts(r, rewardStyle)
    ]
  }

  let row = rewards.map(@(rInfo) {
    size
    children = mkRewardPlate(rInfo, rStyle)
  })

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
    size
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
        key = {}
        flow = FLOW_HORIZONTAL
        transform = {}
        animations = mkAnimations()
        children = row
      }
      @() {
        watch = activeSlideIdx
        size = flex()
        valign = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(8)
        padding = hdpx(5)
        children = rewards.map(@(_, idx) mkSliderPoint(activeSlideIdx.get() == idx))
      }
    ]
  }
}

return { mkRewardSlider }
