from "%globalsDarg/darg_library.nut" import *
let { openQuestsWndOnTab } = require("%rGui/quests/questsState.nut")
let { opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP } = require("goodsPreviewPkg.nut")

let verticalGap = hdpx(20)
let giftBoxAnimDur = 0.2

let mkPersonalDiscountBtn = @(eventId, aTimeHeaderStart) {
  size = hdpx(130)
  pos = [verticalGap, 0]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#offer_upgrade_discount_icon.avif:0:P")
  behavior = Behaviors.Button
  onClick = @() openQuestsWndOnTab(eventId)
  transform = {}
  animations = opacityAnims(0.5 * aTimePackNameFull, aTimeHeaderStart).append(
    { prop = AnimProp.translate, from = [-hdpx(100), 0.0], to = [0.0, 0.0], easing = InQuad, play = true,
      duration = 0.5 * aTimePackNameFull, delay = aTimeHeaderStart, trigger = ANIM_SKIP }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.5, 1.5], easing = Linear, play = true,
      duration = giftBoxAnimDur, delay = aTimeHeaderStart + 0.5, trigger = ANIM_SKIP_DELAY }
    { prop = AnimProp.scale, from = [1.5, 1.5], to = [1, 1], easing = Linear, play = true,
      duration = giftBoxAnimDur, delay = giftBoxAnimDur + aTimeHeaderStart + 0.5, trigger = ANIM_SKIP_DELAY }
  )
}

return mkPersonalDiscountBtn
