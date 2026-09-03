from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import G_BLUEPRINT, G_UNIT, G_UNIT_UPGRADE, oneTimeRewardTypes
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout, clearTimer, setInterval
from "%sqstd/string.nut" import utf8ToUpper
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import rewardInProgress, lootboxInProgress, apply_prize_tickets,
  registerHandler
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardDisabledBkg, mkRewardReceivedMark,
  mkRewardUnitFlag
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, getRewardPlateSize
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, isRewardEmpty
from "%rGui/shop/lootboxOpenRouletteState.nut" import rouletteOpenId, nextOpenId
from "%rGui/shop/unseenPurchasesState.nut" import unseenPurchasesExt, isShowUnseenDelayed
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkGradientCtorRadial, gradTexSize
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import isTutorialActive
from "%rGui/unit/components/unitInfoPanel.nut" import unitInfoPanel, mkUnitTitle
from "%rGui/unit/components/unitUnlockAnimation.nut" import revealAnimation


const PRIZE_TICKETS_SELECT_WND_UID = "prizeTicketsSelectWndUid"
const TIME_TO_DELAYED_RETRY = 30.0
const MAX_COUNT_TO_TRY = 3

const selBorderColor = 0xFFFFFFFF
const hoverBorderColor = 0x40404040
const borderHeight = hdpx(8)

let notAppliedTickets = mkWatched(persist, "notAppliedTickets", {})
let isModalAttached = Watched(false)
let selIndexes = Watched([])
let prizeTicketsProfile = Computed(@() servProfile.get()?.prizeTickets ?? {})
let canSelectTicket = Computed(@() !isInBattle.get() && !lootboxInProgress.get() && !rewardInProgress.get())

let prizeTicketId = Computed(@() !canSelectTicket.get() ? null
  : prizeTicketsProfile.get()
    .findindex(@(v, id) v > 0
      && id in serverConfigs.get()?.prizeTicketsCfg
      && id not in notAppliedTickets.get()))

let ticketToShow = Computed(@() prizeTicketId.get() != null
  ? serverConfigs.get()?.prizeTicketsCfg[prizeTicketId.get()]
  : null)

let canShowWithoutWindows = Computed(@() canSelectTicket.get()
  && isLoggedIn.get()
  && unseenPurchasesExt.get().len() == 0
  && !isShowUnseenDelayed.get()
  && !isTutorialActive.get())

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

let isRepeatableTicket = Computed(@() currentVariants.get().findvalue(@(v) v?.gType not in oneTimeRewardTypes) != null)

let currentTicketCounts = Computed(function(){
  if (!isModalAttached.get() || prizeTicketId.get() == null)
    return { lastReward = 0, availableVariants = 0 }

  let count = prizeTicketsProfile.get()[prizeTicketId.get()]

  local availableVariantsCount = 0
  foreach(variant in currentVariants.get())
    if (!isRewardEmpty([variant], servProfile.get()))
      availableVariantsCount += 1

  if (isRepeatableTicket.get())
    return {
      lastReward = availableVariantsCount > 0 ? 0 : 1,
      availableVariants = availableVariantsCount > 0 ? 1 : 0
    }
  return {
    lastReward = count <= availableVariantsCount ? 0 : count - availableVariantsCount,
    availableVariants = count <= availableVariantsCount ? count : availableVariantsCount
  }
})
let hasLastReward = Computed(@() currentTicketCounts.get().lastReward > 0)
let lastReward = Computed(@() hasLastReward.get() ? ticketToShow.get()?.lastReward : null)
let ticketsRemaining = Computed(function() {
  if (prizeTicketId.get() == null)
    return 0
  let count = prizeTicketsProfile.get()?[prizeTicketId.get()] ?? 0
  return count > 1 ? count - 1 : 0
})

let closeModalWnd = @() removeModalWindow(PRIZE_TICKETS_SELECT_WND_UID)

let mkUnitPlateTooltip = @(unit) unitInfoPanel({}, mkUnitTitle, unit)
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
    else {
      v.append(selectedIdx)
      if (v.len() > currentTicketCounts.get().availableVariants)
        v.remove(0)
    }
  })
}

function retryRequestWithDelay() {
  if (notAppliedTickets.get().len() == 0 || !isLoggedIn.get())
    return

  let currentTime = get_time_msec()

  foreach(ticketId, ticketData in notAppliedTickets.get()) {
    let { indexes, lastTime, countTries } = ticketData

    if (countTries >= MAX_COUNT_TO_TRY)
      continue
    else if (currentTime - lastTime > TIME_TO_DELAYED_RETRY * countTries * 1000)
      apply_prize_tickets(ticketId, indexes, {
        id = "onPrizeTicketsAppliedByRetry",
        ticketId,
      })
  }
}

function onTicketNotApplied(context) {
  let { ticketId, indexes } = context
  notAppliedTickets.mutate(@(v) v[ticketId] <- { indexes, lastTime = get_time_msec(), countTries = 1 })

  setInterval(TIME_TO_DELAYED_RETRY, retryRequestWithDelay)
}

notAppliedTickets.subscribe(@(v) v.len() == 0 ? clearTimer(retryRequestWithDelay) : null)
isLoggedIn.subscribe(function(v) {
  if (!v && notAppliedTickets.get().len() > 0) {
    notAppliedTickets.set({})
    clearTimer(retryRequestWithDelay)
  }
})

if (notAppliedTickets.get().len() > 0 && isLoggedIn.get())
  setInterval(TIME_TO_DELAYED_RETRY, retryRequestWithDelay)

let needSkipError = @(errorMessage) errorMessage.startswith("Dont have enough prize tickets")

registerHandler("onPrizeTicketsAppliedByRetry", function(res, context) {
  let errorMessage = res?.error.message
  let { ticketId } = context

  if (!isLoggedIn.get() || ticketId not in notAppliedTickets.get())
    return

  let currentCountTries = notAppliedTickets.get()[ticketId].countTries

  if (errorMessage != null && !needSkipError(errorMessage) && currentCountTries < MAX_COUNT_TO_TRY)
    return notAppliedTickets.mutate(function(v) {
      v[ticketId].lastTime = get_time_msec()
      v[ticketId].countTries += 1
    })

  notAppliedTickets.mutate(@(v) v.$rawdelete(ticketId))
})

registerHandler("onPrizeTicketsApplied", function(res, context) {
  let errorMessage = res?.error.message

  if (errorMessage != null && isLoggedIn.get() && !needSkipError(errorMessage))
    onTicketNotApplied(context)

  selIndexes.set([])
  if (prizeTicketId.get() == null)
    closeModalWnd()
})

function applyPrizeTickets() {
  let indexes = clone selIndexes.get()
  if (hasLastReward.get())
    indexes.extend(array(currentTicketCounts.get().lastReward, -1))

  apply_prize_tickets(prizeTicketId.get(), indexes, {
    id = "onPrizeTicketsApplied",
    ticketId = prizeTicketId.get(),
    indexes
  })
}

let highlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 25, 22, 31,-22))

let mkHightlightPlate = @(isSelected) {
  size = FLEX
  children = [
    {
      size = FLEX
      rendObj = ROBJ_IMAGE
      flipY = true
      image = highlight()
      animations = revealAnimation(0)
      transform = { rotate = 180 }
      opacity = 0.2
    }
    {
      size = const [FLEX, borderHeight]
      pos = const [0, -borderHeight]
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
  modalWndBg.__merge({
    minWidth = hdpx(800)
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    children = [
      modalWndHeader(title)
      {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        padding = const [0, hdpx(30)]
        gap = hdpx(20)
        children = content
      }
      @() {
        watch = [isRepeatableTicket, ticketsRemaining, selIndexes, currentTicketCounts]
        size = const [FLEX, hdpx(50)]
        halign = ALIGN_CENTER
        valign = ALIGN_TOP
        rendObj = ROBJ_TEXT
        text = isRepeatableTicket.get()
          ? (ticketsRemaining.get() > 0
              ? loc("events/prizesToChooseCount", { count = ticketsRemaining.get() })
              : null)
          : (currentTicketCounts.get().availableVariants <= 1
              ? null
              : loc("events/countPrizesChoosen", {
                  maxCount = currentTicketCounts.get().availableVariants,
                  count = selIndexes.get().len()
                }))
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
      unit.get() ? mkRewardUnitFlag(unit.get(), rStyle) : null
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
          ? mkSpinnerHideBlock(rewardInProgress, textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), applyPrizeTickets))
          : textButtonCommon(utf8ToUpper(loc("msgbox/btn_choose")), @() openMsgBox({
              text = loc("events/warningSelectPrize")
              buttons = [{ id = "ok", isCancel = true }]
            }))
    }
  ]
}

function openRewardPrizeSelect() {
  closeModalWnd()
  if (!needShowPrizeTickets.get())
    return null

  addModalWindow(bgShaded.__merge({
    key = PRIZE_TICKETS_SELECT_WND_UID
    animations = wndSwitchAnim
    sound = { click = "click" }
    size = const [sw(100), sh(100)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = @() isModalAttached.set(true)
    onDetach = @() isModalAttached.set(false)
    onClick = @() null
    children = mkPrizeTicketsContent(mkContentChoose(currentVariants, lastReward), loc("events/selectPrizeToReceive"))
  }))
}

let showPrizeSelectDelayed = @() resetTimeout(0.5, @() !isModalAttached.get() && needShowPrizeTickets.get()
  ? openRewardPrizeSelect() : null)
needShowPrizeTickets.subscribe(@(v) v? showPrizeSelectDelayed() : null)
prizeTicketId.subscribe(@(v) v == null ? closeModalWnd() : null)

return { showPrizeSelectDelayed, ticketToShow }
