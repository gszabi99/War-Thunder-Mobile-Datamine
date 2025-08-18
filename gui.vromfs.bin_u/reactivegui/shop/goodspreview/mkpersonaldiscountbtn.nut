from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { opacityAnims, aTimePackNameFull, ANIM_SKIP_DELAY, ANIM_SKIP } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { specialEventsLootboxesState } = require("%rGui/event/eventState.nut")
let { openQuestsWndOnTab, questsBySection } = require("%rGui/quests/questsState.nut")
let { discountsToApply } = require("%rGui/shop/shopState.nut")

let verticalGap = hdpx(20)
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
    let { withoutLootboxes = {} } = specialEventsLootboxesState.get()
    let discountRewards = availableDiscountRewards.get()
    local res = null

    if (!discountRewards || withoutLootboxes.len() == 0)
      return res

    foreach (eventName, eventState in withoutLootboxes)
      foreach (quest in questsBySection.get()?[eventName] ?? {}) {
        if (quest?.stages.findindex(@(v) v?.rewards.findindex(@(_, id) id in discountRewards) != null) != null) {
          res = eventState.eventId
          break
        }
      }

    return res
  })

  return @() {
    watch = eventIdByPersonalDiscount
    size = hdpx(130)
    pos = [verticalGap, 0]
    children = !eventIdByPersonalDiscount.get() ? null
      : {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = Picture("ui/gameuiskin#offer_upgrade_discount_icon.avif:0:P")
          behavior = Behaviors.Button
          onClick = @() openQuestsWndOnTab(eventIdByPersonalDiscount.get())
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
