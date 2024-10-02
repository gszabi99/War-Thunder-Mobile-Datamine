from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { mkRewardSlider, plateHeight, plateGap, defaultSlots } = require("%rGui/rewards/components/mkRewardSlider.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgMessage, bgHeader, bgShaded } = require("%rGui/style/backgrounds.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let PRIZE_TICKETS_WND_UID = "prizeTicketsWndUid"

let mkUnitPlateClick = @(r) unitDetailsWnd({ name = r.id, isUpgraded = r.rType == G_UNIT_UPGRADE })
let mkPlateClickByType = {
  [G_BLUEPRINT] = mkUnitPlateClick,
  [G_UNIT] = mkUnitPlateClick,
  [G_UNIT_UPGRADE] = mkUnitPlateClick,
}

let mkPrizeTicketsContent = @(rewards, rStyle)
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
        children = rewards.map(@(reward) {
          function onClick() {
            mkPlateClickByType?[reward.rType](reward)
            removeModalWindow(PRIZE_TICKETS_WND_UID)
          }
          sound = { click = "click" }
          behavior = Behaviors.Button
          children = mkRewardPlate(reward, rStyle)
        })
      }
    ]
  })

function mkPrizeTicket(id, rStyle) {
  let { prizeTicketsCfg = {} } = serverConfigs.get()

  if (!id || id not in prizeTicketsCfg)
    return null

  let rewards = []
  foreach(value in (prizeTicketsCfg?[id].variants ?? []))
    foreach(reward in value)
      rewards.append(reward.__update({ slots = defaultSlots, rType = reward.gType }))

  function onClick() {
    removeModalWindow(PRIZE_TICKETS_WND_UID)
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
        children = mkPrizeTicketsContent(rewards, REWARD_STYLE_MEDIUM)
      }
    }))
  }

  return mkRewardSlider(rewards, onClick, rStyle)
}

let rewardPrizePlateCtors = {
  prizeTicket = {
    ctor = mkPrizeTicket
    extraSize = plateHeight + plateGap
  }
}

let isPrizeTicket = @(r) r.rType in rewardPrizePlateCtors

return {
  rewardPrizePlateCtors
  isPrizeTicket
}
