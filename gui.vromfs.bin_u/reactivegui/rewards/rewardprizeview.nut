from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *

let { REWARD_STYLE_MEDIUM, getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgMessage, bgHeader, bgShaded } = require("%rGui/style/backgrounds.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let PRIZE_TICKETS_WND_UID = "prizeTicketsWndUid"

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
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{size[0]}:{size[1]}:P")
  }
}

let mkPrizeTicketsContent = @(content)
  bgMessage.__merge({
    minWidth = hdpx(800)
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    stopMouse = true
    children = [
      bgHeader.__merge({
        size = [flex(), SIZE_TO_CONTENT]
        padding = hdpx(20)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          text = loc("events/prizesToChoose")
        }.__update(fontSmallAccented)
      })
      {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        padding = hdpx(60)
        gap = hdpx(20)
        children = content
      }
    ]
  })

function openRewardPrizeView(rewards, rewardCtors) {
  removeModalWindow(PRIZE_TICKETS_WND_UID)

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
      removeModalWindow(PRIZE_TICKETS_WND_UID)
    }
    sound = { click = "click" }
    behavior = Behaviors.Button
    children = mkRewardPlate(reward, REWARD_STYLE_MEDIUM)
  })

  addModalWindow(bgShaded.__merge({
    key = PRIZE_TICKETS_WND_UID
    animations = wndSwitchAnim
    sound = { click = "click" }
    size = [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      key = {}
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children = mkPrizeTicketsContent(content)
    }
  }))
}

return { openRewardPrizeView }
