from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *

let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { resetTimeout } = require("dagor.workcycle")

let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { rewardInProgress, lootboxInProgress, apply_prize_tickets,
  registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let { mkRewardPlate, mkRewardDisabledBkg, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { unseenPurchasesExt, isShowUnseenDelayed } = require("%rGui/shop/unseenPurchasesState.nut")
let { unitInfoPanel, mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { REWARD_STYLE_MEDIUM, getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { rouletteOpenId, nextOpenId } = require("%rGui/shop/lootboxOpenRouletteState.nut")
let { getRewardsViewInfo, isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { hasJustUnlockedUnitsAnimation } = require("%rGui/unit/justUnlockedUnits.nut")
let { revealAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { bgMessage, bgHeader, bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkUnitFlag } = require("%rGui/unit/components/unitPlateComp.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let PRIZE_TICKETS_SELECT_WND_UID = "prizeTicketsSelectWndUid"

let selBorderColor = 0xFFFFFFFF
let hoverBorderColor = 0x40404040
let borderHeight = hdpx(8)

let isModalAttached = Watched(false)
let selIndexes = Watched([])
let prizeTicketsProfile = Computed(@() servProfile.get()?.prizeTickets ?? {})
let canSelectTicket = Computed(@() !isInBattle.get() && !lootboxInProgress.get() && !rewardInProgress.get())

let prizeTicketId = Computed(@() !canSelectTicket.get() ? null
  : prizeTicketsProfile.get().findindex(@(v, id) v > 0 && id in serverConfigs.get()?.prizeTicketsCfg))

let ticketToShow = Computed(@() prizeTicketId.get() != null
  ? serverConfigs.get().prizeTicketsCfg[prizeTicketId.get()]
  : null)

let canShowWithoutWindows = Computed(@() canSelectTicket.get()
  && isLoggedIn.get()
  && unseenPurchasesExt.get().len() == 0
  && isInMenuNoModals.get()
  && !isShowUnseenDelayed.get()
  && !isTutorialActive.get()
  && !hasJustUnlockedUnitsAnimation.get())

let needShowPrizeTickets = keepref(Computed(@() !rouletteOpenId.get()
  && !nextOpenId.get()
  && ticketToShow.get() != null
  && canShowWithoutWindows.get()))

let currentVariants = Computed(function() {
  let res = []
  if (!isModalAttached.get() || ticketToShow.get() == null)
    return res
  foreach(value in (ticketToShow.get()?.variants ?? []))
    foreach(variant in value)
      res.append(variant)
  return res
})

let currentTicketCounts = Computed(function(){
  if (!isModalAttached.get() || prizeTicketId.get() == null)
    return { lastReward = 0, availableVariants = 0 }

  let count = prizeTicketsProfile.get()[prizeTicketId.get()]

  local availableVariantsCount = 0
  foreach(variant in currentVariants.get())
    if (!isRewardEmpty([variant], servProfile.get()))
      availableVariantsCount += 1

  return {
    lastReward = count <= availableVariantsCount ? 0 : count - availableVariantsCount,
    availableVariants = count <= availableVariantsCount ? count : availableVariantsCount
  }
})
let hasLastReward = Computed(@() currentTicketCounts.get().lastReward > 0)
let lastReward = Computed(@() hasLastReward.get() ? ticketToShow.get()?.lastReward : null)

currentTicketCounts.subscribe(@(v) v.lastReward == 0 && v.availableVariants == 0
  ? removeModalWindow(PRIZE_TICKETS_SELECT_WND_UID) : null)

let mkUnitPlateTooltip = @(unit) unitInfoPanel({}, mkPlatoonOrUnitTitle, unit)
let mkPlateTooltipByType = {
  [G_BLUEPRINT] = mkUnitPlateTooltip,
  [G_UNIT] = mkUnitPlateTooltip,
  [G_UNIT_UPGRADE] = mkUnitPlateTooltip,
}

function selectSlot(selectedIdx) {
  selIndexes.mutate(function(v) {
    let index = v.findindex(@(idx) idx == selectedIdx)
    if (index != null)
      v.remove(index)
    else if (v.len() < currentTicketCounts.get().availableVariants)
      v.append(selectedIdx)
  })
}

registerHandler("onPrizeTicketsApplied", function(_) {
  selIndexes.set([])
  removeModalWindow(PRIZE_TICKETS_SELECT_WND_UID)
})

function applyPrizeTickets() {
  local indexes = selIndexes.get()

  if (hasLastReward.get())
    indexes.extend(array(currentTicketCounts.get().lastReward, -1))

  apply_prize_tickets(prizeTicketId.get(), indexes, "onPrizeTicketsApplied")
}

let highlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 25, 22, 31,-22))

let mkHightlightPlate = @(isSelected) {
  size = flex()
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      flipY = true
      image = highlight()
      animations = revealAnimation(0)
      transform = { rotate = 180 }
      opacity = 0.2
    }
    {
      size = [flex(), borderHeight]
      pos = [0, -borderHeight]
      rendObj = ROBJ_BOX
      hplace = ALIGN_TOP
      fillColor = isSelected ? selBorderColor : hoverBorderColor
    }
  ]
}

let mkDisableBkgWithTooltip = @(isPurchased, rStyle) isPurchased
  ? mkRewardReceivedMark(rStyle)
  : mkRewardDisabledBkg

let mkPrizeTicketsContent = @(content, title)
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
          text = title
        }.__update(fontSmallAccented)
      })
      {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        padding = [0, hdpx(30)]
        gap = hdpx(20)
        children = content
      }
      @() {
        watch = [selIndexes, currentTicketCounts]
        size = [flex(), hdpx(50)]
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        rendObj = ROBJ_TEXT
        text = currentTicketCounts.get().availableVariants <= 1 ? null
          : loc("events/countPrizesChoosen", {
              maxCount = currentTicketCounts.get().availableVariants,
              count = selIndexes.get().len()
            })
      }.__update(fontTinyAccented)
    ]
  })

function mkSlot(slotIdx, reward, rStyle) {
  let size = getRewardPlateSize(reward.slots, rStyle)
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selIndexes.get().indexof(slotIdx) != null)
  let needShowTooltipUnit = reward.rType in mkPlateTooltipByType
  let unit = Computed(@() needShowTooltipUnit ? serverConfigs.get()?.allUnits?[reward.id] : null)
  let isPurchased = Computed(@() isRewardEmpty([{ gType = reward.rType }.__merge(reward)], servProfile.get()))
  let isDisabled = Computed(@()
    (selIndexes.get().len() == currentTicketCounts.get().availableVariants && !isSelected.get()) || isPurchased.get())

  let key = {}
  return @() {
    watch = [isSelected, stateFlags, unit, isDisabled, isPurchased]
    key
    size
    behavior = Behaviors.Button
    onElemState = withTooltip(stateFlags, key, @() !isSelected.get() && unit.get() ? null
      : {
          content = mkPlateTooltipByType[reward.rType](unit),
          flow = FLOW_HORIZONTAL
        })
    onDetach = tooltipDetach(stateFlags)
    onClick = @() !isPurchased.get() ? selectSlot(slotIdx) : null
    sound = { click  = "click" }
    children = [
      mkRewardPlate(reward, rStyle)
      unit.get() ? mkUnitFlag(unit.get(), rStyle) : null
      isPurchased.get() || (!isSelected.get() && !(stateFlags.get() & S_HOVER)) ? null
        : mkHightlightPlate(isSelected.get())
      isDisabled.get() ? mkDisableBkgWithTooltip(isPurchased.get(), rStyle) : null
    ]
  }
}

let mkContentChoose = @(rewards, lReward) @() {
  watch = [rewards, lReward, currentTicketCounts]
  flow = FLOW_VERTICAL
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  padding = hdpx(30)
  gap = hdpx(30)
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = getRewardsViewInfo(rewards.get()).map(@(reward, idx) mkSlot(idx, reward, REWARD_STYLE_MEDIUM))
    }
    !lReward.get() ? null
      : {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        padding = hdpx(30)
        gap = hdpx(20)
        children = getRewardsViewInfo(lReward.get(), currentTicketCounts.get().lastReward)
          .map(@(reward) mkRewardPlate(reward, REWARD_STYLE_MEDIUM))
      }
    @() {
      watch = [selIndexes, currentTicketCounts]
      children = ((currentTicketCounts.get().availableVariants > 0 && selIndexes.get().len() == currentTicketCounts.get().availableVariants)
        || (currentTicketCounts.get().availableVariants == 0 && currentTicketCounts.get().lastReward > 0))
          ? mkSpinnerHideBlock(rewardInProgress, textButtonPrimary(loc("msgbox/btn_choose"), applyPrizeTickets))
          : textButtonCommon(loc("msgbox/btn_choose"), @() openMsgBox({
              text = loc("events/warningSelectPrize")
              buttons = [{ id = "ok", isCancel = true }]
            }))
    }
  ]
}

function openRewardPrizeSelect() {
  removeModalWindow(PRIZE_TICKETS_SELECT_WND_UID)
  if (!needShowPrizeTickets.get())
    return null

  addModalWindow(bgShaded.__merge({
    key = PRIZE_TICKETS_SELECT_WND_UID
    animations = wndSwitchAnim
    sound = { click = "click" }
    size = [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = @() isModalAttached.set(true)
    onDetach = @() isModalAttached.set(false)
    onClick = @() null
    children = {
      key = {}
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children = mkPrizeTicketsContent(mkContentChoose(currentVariants, lastReward),
        loc("events/selectPrizeToReceive"))
    }
  }))
}

let showPrizeSelectDelayed = @() resetTimeout(0.5, @() needShowPrizeTickets.get() ? openRewardPrizeSelect() : null)
needShowPrizeTickets.subscribe(@(v) v? showPrizeSelectDelayed() : null)

return { showPrizeSelectDelayed, ticketToShow }
