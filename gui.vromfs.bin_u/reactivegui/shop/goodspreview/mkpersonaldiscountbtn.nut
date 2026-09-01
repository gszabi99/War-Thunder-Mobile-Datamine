from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/event/eventState.nut" import specialEvents
from "%rGui/quests/questsState.nut" import questsCfg, tabIdToOpen
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, QUESTS_TAB
from "%rGui/shop/discounts.nut" import discountsToApply
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP
from "%rGui/unlocks/unlocks.nut" import campaignActiveUnlocks


const giftBoxAnimDur = 0.2

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
      let { event_id = null, sub_event_of = null } = u?.meta
      if (event_id != null && u?.stages.findindex(@(s) s?.rewards.findindex(@(_, id) id in discountRewards) != null) != null)
        return {sub_event_of, event_id}
    }

    return null
  })

  return @() {
    watch = eventIdByPersonalDiscount
    size = hdpx(130)
    children = !eventIdByPersonalDiscount.get() ? null
      : {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture("ui/gameuiskin#offer_upgrade_discount_icon.avif:0:P")
          behavior = Behaviors.Button
          function onClick() {
            let ids = eventIdByPersonalDiscount.get()
            if (ids == null)
              return
            let { sub_event_of, event_id } = ids
            tabIdToOpen.set(event_id in questsCfg.get() ? event_id
              : specialEvents.get().findindex(@(s) s.eventName == event_id) ?? event_id)
            openSeasonScene(sub_event_of ?? event_id, QUESTS_TAB)
          }
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
