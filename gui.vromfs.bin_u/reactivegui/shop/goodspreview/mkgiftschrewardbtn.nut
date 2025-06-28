from "%globalsDarg/darg_library.nut" import *
let { onSchRewardReceive } = require("%rGui/shop/schRewardsState.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { schRewardInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP } = require("goodsPreviewPkg.nut")

let verticalGap = hdpx(20)

function mkGiftSchRewardBtn(giftSchReward, aTimeHeaderStart, skipAnimsOnce = null) {
  let giftBoxAnimDur = 0.2
  let giftBoxAnimDelay = aTimeHeaderStart + 0.5
  local { isReady = false } = giftSchReward
  function schRewardAndSkipAnim(){
    onSchRewardReceive(giftSchReward)
    skipAnimsOnce?.set(true)
  }
  if (!isReady)
    return null
  local isPurchasing = Computed(@() giftSchReward.id in schRewardInProgress.get())
  return {
    size = hdpx(130)
    pos = [verticalGap,0]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/gameuiskin#offer_gift_icon.avif:0:P")
    behavior = Behaviors.Button
    onClick = schRewardAndSkipAnim
    children = [
      {
        hplace = ALIGN_RIGHT
        margin = const [hdpx(10), hdpx(10), 0, 0]
        children = priorityUnseenMark
      }
      @() {
        watch = isPurchasing
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = isPurchasing.get() ? spinner : null
      }
    ]
    transform = {}
    animations = opacityAnims(0.5 * aTimePackNameFull, aTimeHeaderStart).append(
      { prop = AnimProp.translate, from = [-hdpx(100), 0.0], to = [0.0, 0.0], easing = InQuad, play = true,
        duration = 0.5 * aTimePackNameFull, delay = aTimeHeaderStart, trigger = ANIM_SKIP }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.5, 1.5], easing = Linear, play = true,
        duration = giftBoxAnimDur, delay = giftBoxAnimDelay, trigger = ANIM_SKIP_DELAY }
      { prop = AnimProp.scale, from = [1.5, 1.5], to = [1, 1], easing = Linear, play = true,
        duration = giftBoxAnimDur, delay = giftBoxAnimDur + giftBoxAnimDelay, trigger = ANIM_SKIP_DELAY }
    )
  }
}

return mkGiftSchRewardBtn
