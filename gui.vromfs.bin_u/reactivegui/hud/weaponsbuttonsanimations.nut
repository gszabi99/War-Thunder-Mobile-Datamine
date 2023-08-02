from "%globalsDarg/darg_library.nut" import *
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { spendItemsQueue, removeSpendItem } = require("%rGui/hud/spendItems.nut")

let btnGlareSize = (1.62 * touchButtonSize).tointeger()
let actionGlareSize = (1.15 * touchButtonSize).tointeger()

let consumableIconSize = hdpx(50)
let consumableAnimationBottom = hdpx(80)
let consumableAnimationTop = hdpx(130)
let FADE = 0.2
let SHOW = 0.8

let mkBtnGlare = @(trigger) {
  key = trigger
  size = [btnGlareSize, btnGlareSize]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_MASK
  image = Picture($"ui/gameuiskin#hud_bg_rhombus_glare_mask.svg:{btnGlareSize}:{btnGlareSize}:P")
  clipChildren = true
  children = {
    size = [0.4 * btnGlareSize, 2 * btnGlareSize]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = gradTranspDoubleSideX
    color = 0x00A0A0A0
    transform = { rotate = 25, translate = [-btnGlareSize, -btnGlareSize] }
    animations = [{
      prop = AnimProp.translate, duration = 0.4, delay = 0.05, trigger
      from = [-btnGlareSize, -btnGlareSize], to = [0.5 * btnGlareSize, 0.5 * btnGlareSize]
    }]
  }

  transform = { scale = [0.0, 0.0] } //zero size mask will not render. So just optimization
  animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.0, 1.0], duration = 0.5, trigger }]
}

let function mkActionGlare(actionItem) {
  let trigger = $"action_cd_finish_{actionItem?.id}"
  return {
    size = [actionGlareSize, actionGlareSize]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin#hud_bg_square_glare_mask.svg:{actionGlareSize}:{actionGlareSize}:P")
    clipChildren = true
    children = {
      size = [0.4 * actionGlareSize, 2 * actionGlareSize]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0x00A0A0A0
      transform = { rotate = 25, translate = [-actionGlareSize, -actionGlareSize] }
      animations = [{
        prop = AnimProp.translate, duration = 0.4, delay = 0.05, trigger
        from = [-actionGlareSize, -actionGlareSize], to = [0.5 * actionGlareSize, 0.5 * actionGlareSize]
      }]
    }

    transform = { scale = [0.0, 0.0] } //zero size mask will not render. So just optimization
    animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.0, 1.0], duration = 0.5, trigger }]
  }
}

let function mkConsumableAnimation(nextAnimation) {
  return {
    key = nextAnimation
    valign = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    opacity = 0
    transform = {}
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_LEFT
        text = - nextAnimation.count
      }.__update(fontTiny)
      mkCurrencyImage(nextAnimation.itemId, consumableIconSize, { halign = ALIGN_LEFT })
    ]
    animations = [
      { prop = AnimProp.opacity, from = 0.1, to = 1, duration = FADE,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 1, to = 1, duration = SHOW,
        easing = InOutCubic, delay = FADE, play = true }
      { prop = AnimProp.opacity, from = 1, to = 0.1, duration = FADE,
        easing = InOutCubic, delay = FADE + SHOW, play = true }

      { prop = AnimProp.translate, from = [0, - consumableAnimationBottom], to = [0, - consumableAnimationTop],
        duration = FADE * 2 + SHOW, play = true, onFinish = @() removeSpendItem(nextAnimation) }
    ]
  }
}

let function mkConsumableSpend(itemId) {
  if (!itemId)
    return null
  let nextAnimation = Computed(@() spendItemsQueue.value.findvalue(@(i) i.itemId == itemId))

  return {
    hplace = ALIGN_LEFT
    children = @() {
      watch = nextAnimation
      children = nextAnimation.value == null ? null : mkConsumableAnimation(nextAnimation.value)
    }
  }
}

return {
  mkBtnGlare
  mkActionGlare
  mkConsumableSpend
}
