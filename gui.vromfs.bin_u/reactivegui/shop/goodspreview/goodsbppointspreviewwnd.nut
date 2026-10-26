from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow
from "%rGui/shop/goodsPreviewState.nut" import previewGoods, GPT_BP_POINTS, closeGoodsPreview, previewType
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/style/stdColors.nut" import commonTextColor


let cardsStyle = REWARD_STYLE_MEDIUM
const WND_UID = "goods_preview_bp_points"
const infoPadding = hdpx(80)

let isOpened = keepref(Computed(@() previewType.get() == GPT_BP_POINTS))

let msg = @(text) {
  size = [hdpx(900), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = commonTextColor
  text
  halign = ALIGN_CENTER
  ...fontSmall
}

function rewardInfo() {
  if (previewGoods.get() == null)
    return { watch = previewGoods }

  let { boxGap } = cardsStyle
  let vInfo = getRewardsViewInfo(previewGoods.get().rewards).sort(sortRewardsViewInfo)
  return {
    watch = previewGoods
    flow = FLOW_VERTICAL
    gap = boxGap
    halign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = boxGap
        children = vInfo.map(@(vi) mkRewardPlate(vi, cardsStyle))
      }
      msg(loc("shop/item/bpPoints"))
    ]
  }
}

let openImpl = @() addModalWindowWithHeader(WND_UID,
  loc("goods/contains"),
  {
    padding = infoPadding
    flow = FLOW_VERTICAL
    gap = infoPadding
    halign = ALIGN_CENTER
    children = [
      rewardInfo
      msg(loc("shop/item/bpPoints/containsDesc"))
    ]
  },
  closeGoodsPreview)


if (isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
