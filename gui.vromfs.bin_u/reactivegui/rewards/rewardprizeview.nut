from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *

let { openRewardsPreviewModal, closeRewardsPreviewModal } = require("%rGui/rewards/rewardsPreviewModal.nut")
let { REWARD_STYLE_MEDIUM, getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")


let mkUnitPlateClick = @(r) unitDetailsWnd({ name = r.id, isUpgraded = r.rType == G_UNIT_UPGRADE })
let mkPlateClickByType = {
  [G_BLUEPRINT] = mkUnitPlateClick,
  [G_UNIT] = mkUnitPlateClick,
  [G_UNIT_UPGRADE] = mkUnitPlateClick,
}

function mkRewardPlateBg(r, rStyle) {
  let size = getRewardPlateSize(r.slots, rStyle)
  return {
    size
    rendObj = ROBJ_BOX
    fillColor = 0xFFB9B9B9
    children = {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      rendObj = ROBJ_9RECT
      image = Picture($"ui/gameuiskin#gradient_button.svg")
      padding = hdpx(3)
      color = 0xFFEEEEEE
      children = {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#offer_item_slot_bg.avif")
      }
    }
  }
}

let mkPrizeTicketsContent = @(content, style) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP
  padding = hdpx(60)
  gap = style.boxGap
  children = content
}

function openRewardPrizeView(rewards, rewardCtors) {
  let mkRewardPlateImage = @(r, rStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).image(r, rStyle)
  let mkRewardPlateTexts = @(r, rStyle) (rewardCtors?[r?.rType] ?? rewardCtors.unknown).texts(r, rStyle)

  let mkRewardPlate = @(r, rStyle) {
    transform = {}
    children = [
      mkRewardPlateBg(r, rStyle)
      mkRewardPlateImage(r, rStyle)
      mkRewardPlateTexts(r, rStyle)
    ]
  }

  let content = rewards.map(@(reward) {
    function onClick() {
      mkPlateClickByType?[reward.rType](reward)
      closeRewardsPreviewModal()
    }
    sound = { click = "click" }
    behavior = Behaviors.Button
    children = mkRewardPlate(reward, REWARD_STYLE_MEDIUM)
  })

  openRewardsPreviewModal(mkPrizeTicketsContent(content, REWARD_STYLE_MEDIUM), loc("events/prizesToChoose"))
}

return { openRewardPrizeView }
