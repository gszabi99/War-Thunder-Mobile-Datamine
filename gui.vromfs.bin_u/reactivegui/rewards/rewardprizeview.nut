from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import *
from "%rGui/components/modalWindows.nut" import removeModalWindow
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, getRewardPlateSize
from "%rGui/rewards/rewardsPreviewModal.nut" import openRewardsPreviewModal
from "%rGui/rewards/rewardViewInfo.nut" import isRewardEmpty
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd


const WND_UID = "rewardPrizeView"


let mkUnitPlateClick = @(r) openUnitDetailsWnd({ name = r.id, isUpgraded = r.rType == G_UNIT_UPGRADE })
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
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      rendObj = ROBJ_9RECT
      image = Picture($"ui/gameuiskin#gradient_button.svg")
      padding = hdpx(3)
      color = 0xFFEEEEEE
      children = {
        size = FLEX
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

function mkRewardReceivedMark(rStyle) {
  let iconSize = 2 * (rStyle.boxSize * 0.3 + 0.5).tointeger()
  return {
    size = FLEX
    rendObj = ROBJ_SOLID
    color = 0x80000000
    children = {
      size = [iconSize, iconSize]
      pos = const [hdpx(10), -hdpx(10)]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#daily_mark_claimed.avif:{iconSize}:{iconSize}")
      keepAspect = true
    }
  }
}

function mkRewardPlate(r, rStyle, rewardCtors) {
  let isPurchased = Computed(@() isRewardEmpty([{ gType = r.rType }.__merge(r)], servProfile.get()))
  return @() {
    watch = isPurchased
    transform = {}
    children = [
      mkRewardPlateBg(r, rStyle),
      (rewardCtors?[r?.rType] ?? rewardCtors.unknown).image(r, rStyle),
      (rewardCtors?[r?.rType] ?? rewardCtors.unknown).texts(r, rStyle),
      isPurchased.get() ? mkRewardReceivedMark(rStyle) : null,
    ]
  }
}

function openRewardPrizeView(rewards, rewardCtors) {
  let content = rewards.map(@(reward) {
    function onClick() {
      mkPlateClickByType?[reward.rType](reward)
      removeModalWindow(WND_UID)
    }
    sound = { click = "click" }
    behavior = Behaviors.Button
    children = mkRewardPlate(reward, REWARD_STYLE_MEDIUM, rewardCtors)
  })

  openRewardsPreviewModal(WND_UID, mkPrizeTicketsContent(content, REWARD_STYLE_MEDIUM), loc("events/prizesToChoose"))
}

return { openRewardPrizeView }
