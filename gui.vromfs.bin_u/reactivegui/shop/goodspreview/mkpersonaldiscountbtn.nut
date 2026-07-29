from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { openSeasonScene, QUESTS_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { campaignActiveUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { discountsToApply } = require("%rGui/shop/discounts.nut")

let giftBoxAnimDur = 0.2

function mkPersonalDiscountBtn(previewGoods, aTimeHeaderStart) {
  let userstatRewards = Computed(@() serverConfigs.get()?.userstatRewards)
  let personalDiscountsByGoodsId = Computed(@() serverConfigs.get()?.personalDiscounts[previewGoods.get()?.id])
  let availableDiscounts = Computed(@() personalDiscountsByGoodsId.get()?.filter(@(v)
    v.goodsId not in discountsToApply.get() || v.price < discountsToApply.get()[v.goodsId]))

  let availableDiscountRewards = Computed(function() {
    if (availableDiscounts.get() == null || availableDiscounts.get().len() == 0)
      return null

    let res = {}
    foreach (key, rewards in userstatRewards.get())
      if (rewards.findvalue(@(g) g.gType == "discount" && availableDiscounts.get().findindex(@(v) v.id == g.id) != null) != null)
        res[key] <- true

    if (res.len() == 0)
      return null
    return res
  })

  let eventIdByPersonalDiscount = Computed(function() {
    let discountRewards = availableDiscountRewards.get()
    if (!discountRewards)
      return null

    foreach (u in campaignActiveUnlocks.get()) {
      let { event_id = null } = u?.meta
      if (event_id != null && u?.stages.findindex(@(s) s?.rewards.findindex(@(_, id) id in discountRewards) != null) != null)
        return event_id
    }

    return null
  })

  return @() {
    watch = eventIdByPersonalDiscount
    size = hdpx(130)
    pos = [0, -hdpx(30)]
    children = !eventIdByPersonalDiscount.get() ? null
      : {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture("ui/gameuiskin#offer_upgrade_discount_icon.avif:0:P")
          behavior = Behaviors.Button
          onClick = @() openSeasonScene(eventIdByPersonalDiscount.get(), QUESTS_TAB)
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
  }
}

return mkPersonalDiscountBtn
