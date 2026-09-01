from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import schRewardInProgress
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP
from "%rGui/shop/schRewardsState.nut" import onSchRewardReceive


function mkGiftSchRewardBtn(giftSchReward, aTimeHeaderStart, skipAnimsOnce = null) {
  if (!giftSchReward?.isReady)
    return null
  const giftBoxAnimDur = 0.2
  let giftBoxAnimDelay = aTimeHeaderStart + 0.5
  let isPurchasing = Computed(@() giftSchReward.id in schRewardInProgress.get())
  return {
    size = hdpx(130)
    rendObj = ROBJ_IMAGE
    image = Picture("ui/gameuiskin#offer_gift_icon.avif:0:P")
    behavior = Behaviors.Button
    function onClick() {
      if (isPurchasing.get())
        return
      onSchRewardReceive(giftSchReward)
      skipAnimsOnce?.set(true)
    }
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
