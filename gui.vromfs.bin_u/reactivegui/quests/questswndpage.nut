from "%globalsDarg/darg_library.nut" import *
let {eventbus_subscribe} = require("eventbus")
let { questsBySection, seenQuests, saveSeenQuestsForSection, sectionsCfg, questsCfg,
  inactiveEventUnlocks, hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection,
  getQuestCurrenciesInTab, curTabParams
} = require("questsState.nut")
let { textButtonSecondary, textButtonCommon, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { receiveUnlockRewards, unlockInProgress, unlockTables, unlockProgress,
  getUnlockPrice, buyUnlock } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { newMark, mkSectionBtn, sectionBtnHeight, sectionBtnMaxWidth, sectionBtnGap, mkTimeUntil,
  allQuestsCompleted, mkAdsBtn, btnSize } = require("questsPkg.nut")
let { mkRewardsPreview, questItemsGap, statusIconSize, mkLockedIcon, progressBarRewardSize
} = require("rewardsComps.nut")
let { mkQuestBar, mkProgressBar } = require("questBar.nut")
let { getUnlockRewardsViewInfo, sortRewardsViewInfo, isSingleRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize } = require("%rGui/options/mkOptionsScene.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { defer } = require("dagor.workcycle")
let { sendBqQuestsTask } = require("bqQuests.nut")
let { WARBOND, NYBOND } = require("%appGlobals/currenciesState.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")

let bgColor = 0x80000000
let unseenMarkMargin = hdpx(20)
let pageBlocksGap = hdpx(30)
let lockedOpacity = 0.5
let gradientHeightBottom = saBorders[1]

let childOvr = saRatio < 2 ? fontSmallShaded : null
let btnStyle = { ovr = { size = btnSize, minWidth = 0 }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, sound = { click  = "meta_get_unlock" } }, childOvr }
let contentWidth = saSize[0] - tabW - minContentOffset

let isPurchNoNeedResultWindow = @(purch) purch?.source == "userstatReward"
  && null == purch.goods.findvalue(@(g) g.id != "warbond" || (g.id == "warbond" && g.count >= 100))
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

let mkVerticalPannableAreaNoBlocks = verticalPannableAreaCtor(
  sh(100) - topAreaSize + pageBlocksGap,
  [pageBlocksGap, gradientHeightBottom])
let mkVerticalPannableAreaOneBlock = verticalPannableAreaCtor(
  sh(100) - topAreaSize - progressBarRewardSize,
  [pageBlocksGap, gradientHeightBottom])
let mkVerticalPannableAreaTwoBlocks = verticalPannableAreaCtor(
  sh(100) - topAreaSize - pageBlocksGap - progressBarRewardSize - sectionBtnHeight,
  [pageBlocksGap, gradientHeightBottom])
let pannableCtors = [mkVerticalPannableAreaNoBlocks, mkVerticalPannableAreaOneBlock, mkVerticalPannableAreaTwoBlocks]

let newMarkSize = calc_comp_size(newMark)

function receiveReward(item, currencyReward) {
  receiveUnlockRewards(item.name, 1, { stage = 1 })
  sendBqQuestsTask(item, currencyReward?.count ?? 0, currencyReward?.id)
}

function mkQuestText(item) {
  let locId = item.meta?.lang_id ?? item.name
  let header = loc(locId)
  let text = loc($"{locId}/desc")
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      {
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        speed = hdpx(30)
        delay = defMarqueeDelay
        maxWidth = pw(100)
        text = header
      }.__update(fontSmall)

      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = pw(100)
        text
      }.__update(fontTiny)
    ]
  }
}

function mkAchievementText(item) {
  let locId = item.meta?.lang_id ?? item.name
  let text = loc($"{locId}/desc")
  return {
    minHeight = hdpx(80)
    size = [flex(), SIZE_TO_CONTENT]
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = pw(100)
      vplace = ALIGN_CENTER
      text
    }.__update(fontTinyAccented)
  }
}

let purchaseContent = @(rewardsPreview, item){
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    msgBoxText(loc("shop/orderQuestion"), { size = SIZE_TO_CONTENT })
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = mkRewardsPreview(rewardsPreview, item?.isFinished)
    }
    msgBoxText(loc("shop/cost"), { size = SIZE_TO_CONTENT })
  ]
}

eventbus_subscribe("quests.buyUnlock", function(data) {
  receiveReward(data.item, data.currencyReward)
})

let buyRewardMsgBox = @(item, rewardsPreview, price, currency, currencyReward) openMsgBoxPurchase(
  purchaseContent(rewardsPreview, item),
  { price
    currencyId = currency},
  function(){
    buyUnlock(item.name, 1, currency, price,
      { onSuccessCb = { id = "quests.buyUnlock", item, currencyReward }})
  }
  mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, item.name))

function mkBtn(item, currencyReward, rewardsPreview, sProfile) {
  let { name, progressCorrectionStep = 0 } = item
  let isRewardInProgress = Computed(@() name in unlockInProgress.value)
  let price = getUnlockPrice(item)

  local size = btnSize
  local children = []

  local countReceivedR = 0
  foreach(r in rewardsPreview)
    countReceivedR += isSingleRewardEmpty(r, sProfile) ?  1 : 0
  if(countReceivedR == rewardsPreview.len() || item?.isFinished)
    children = {
      size = btnSize
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      text = utf8ToUpper(loc("ui/received"))
      behavior = Behaviors.Button //for gamepad navigation only
    }.__update(fontSmallAccentedShaded)
  else if (item?.hasReward)
    children = textButtonSecondary(
      utf8ToUpper(loc("btn/receive")),
      @() receiveReward(item, currencyReward),
      btnStyleSound)
  else if (progressCorrectionStep > 0)
    children = mkAdsBtn(item)
  else if ((price.price ?? 0) > 0 ) {
    size = [btnSize[0], btnSize[1]*2]
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children =[
        textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
          mkCurrencyComp(price.price , price.currency),
          @() buyRewardMsgBox(item, rewardsPreview, price.price , price.currency, currencyReward),
          btnStyle)
        textButtonCommon(
          utf8ToUpper(loc("btn/receive")),
          @() anim_start($"unfilledBarEffect_{name}"),
          btnStyle)
        ]
    }
  }
  else {
    children = textButtonCommon(
      utf8ToUpper(loc("btn/receive")),
      @() anim_start($"unfilledBarEffect_{name}"),
      btnStyle)
  }
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkSpinnerHideBlock(isRewardInProgress, children)
  }
}

function mkItem(item, textCtor) {
  let isUnseen = Computed(@() !item.hasReward
    && item.name not in seenQuests.value
    && item.name not in inactiveEventUnlocks.value)

  let rewardsPreview = Computed(@() getUnlockRewardsViewInfo(item?.stages[0], serverConfigs.value)
    .sort(sortRewardsViewInfo))

  let eventCurrencyReward = Computed(@() rewardsPreview.value.findvalue(@(r) r.id == WARBOND || r.id == NYBOND))

  let headerPadding = Computed(@() item.hasReward ? unseenMarkMargin * 2
  : isUnseen.value ? newMarkSize[0]
  : 0)

  return {
    rendObj = ROBJ_SOLID
    color = bgColor
    size = [flex(), SIZE_TO_CONTENT]
    xmbNode = {}
    children = [
      @() {
        watch = isUnseen
        size = [flex(), SIZE_TO_CONTENT]
        children = item.hasReward
            ? {
                margin = unseenMarkMargin
                children = priorityUnseenMark
              }
          : isUnseen.value ? newMark
          : null
      }

      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(10), hdpx(30), hdpx(15), hdpx(30)]
        flow = FLOW_HORIZONTAL
        gap = questItemsGap
        vplace = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          @() {
            watch = headerPadding
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = hdpx(8)
            children = [
              textCtor(item).__update({padding = [0, 0, 0, headerPadding.value] })
              mkQuestBar(item)
            ]
          }

          @() {
            watch = rewardsPreview
            flow = FLOW_HORIZONTAL
            gap = questItemsGap
            halign = ALIGN_RIGHT
            children = rewardsPreview.value.len() > 0 ? mkRewardsPreview(rewardsPreview.value, item?.isFinished) : null
          }

          @() {
            watch = [eventCurrencyReward, rewardsPreview, servProfile]
            children = mkBtn(item, eventCurrencyReward.get(), rewardsPreview.get(), servProfile.get())
          }
        ]
      }
    ]
  }
}

let sectionPart = 0.9
let gapPart = 1 - sectionPart

function isSectionActive(sectionId, questsBySectionV, unlockTablesV) {
  let u = questsBySectionV?[sectionId].findvalue(@(_) true)
  return u?.type == "INDEPENDENT" || (unlockTablesV?[u?.table] ?? false)
}

function mkSectionTabs(sections, curSectionId, onSectionChange) {
  let sLen = sections.len()
  let btnWidth = min(sectionBtnMaxWidth, contentWidth / sLen * sectionPart)

  let sectionsFont = Computed(function() {
    foreach (id in sections)
      if (calc_str_box(sectionsCfg.value?[id].text ?? "", fontSmallShaded)[0] > btnWidth - statusIconSize - sectionBtnGap * 2)
        return fontTinyShaded
    return fontSmallShaded
  })

  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = contentWidth * gapPart / (sLen - 1)
    children = sections.map(function(id) {
      let isUnlocked = Computed(@() isSectionActive(id, questsBySection.get(), unlockTables.get()))
      return mkSectionBtn(@() onSectionChange(id),
        Computed(@() curSectionId.value == id),
        Computed(@() !!hasUnseenQuestsBySection.value?[id]
          || !!progressUnlockBySection.get()?[id].hasReward),
        @() {
          watch = [isUnlocked, sectionsFont, sectionsCfg]
          flow = FLOW_HORIZONTAL
          gap = sectionBtnGap
          valign = ALIGN_CENTER
          children = [
            isUnlocked.value ? null : mkLockedIcon({ opacity = lockedOpacity })
            @() {
              watch = [sectionsCfg, sectionsFont]
              rendObj = ROBJ_TEXT
              opacity = isUnlocked.value ? 1.0 : lockedOpacity
              text = sectionsCfg.value?[id].text
            }.__update(sectionsFont.value)
          ]
       })
    })
  }
}

let questTimerUntilStart = @(curSectionId) function() {
  let firstDayStartedAt = userstatStats.value?.stats.day1["$startedAt"]
  let curSectionDay = inactiveEventUnlocks.value
    .findvalue(@(u) u.table == curSectionId.value)?.meta.event_day
    .tointeger()

  local relativeStartTime = null
  if (curSectionDay != null && firstDayStartedAt != null) {
    local firstDayStartTime = firstDayStartedAt - serverTime.value
    relativeStartTime = firstDayStartTime + (curSectionDay - 1) * TIME_DAY_IN_SECONDS
  }

  return {
    watch = [serverTime, curSectionId, userstatStats, inactiveEventUnlocks]
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = relativeStartTime <= 0 ? null
      : mkTimeUntil(secondsToHoursLoc(relativeStartTime), "quests/untilTheStart", fontMedium)
  }
}

function questsWndPage(sections, itemCtor, tabId, headerChildCtor = null) {
  let itemsSort = @(a, b) b.hasReward <=> a.hasReward
    || a.isFinished <=> b.isFinished
    || a.name in seenQuests.value <=> b.name in seenQuests.value
    || a.name <=> b.name

  let selSectionId = mkWatched(persist, $"selSectionId_{tabId}", null)
  let curSectionId = Computed(function() {
    let bySection = questsBySection.get()
    let sectionsList = questsCfg.get()?[tabId] ?? []
    local curId = selSectionId.get()
    if (!sectionsList.contains(curId))
      curId = null
    if ((bySection?[curId].len() ?? 0) > 0)
      return curId

    foreach(sectionId in sectionsList)
      if ((bySection?[sectionId].len() ?? 0) > 0)
        return sectionId
    return curId ?? sectionsList?[0]
  })

  let isCurSectionActive = Computed(@()
    isSectionActive(curSectionId.get(), questsBySection.get(), unlockTables.get()))

  function onSectionChange(id) {
    saveSeenQuestsForSection(curSectionId.value)
    selSectionId(id)
  }

  let tabProgressUnlock = Computed(@() progressUnlockByTab.get()?[tabId])
  let progressUnlock = Computed(@() tabProgressUnlock.get() ?? progressUnlockBySection.get()?[curSectionId.get()])
  let isProgressBySection = Computed(@() tabProgressUnlock.get() == null)

  let blocksOnTop = Computed(function() {
    local n = 0
    if (progressUnlock.value || headerChildCtor != null)
      n++
    if (sections.value.len() > 1)
      n++
    return n
  })

  let tabCurrencies = Computed(@() getQuestCurrenciesInTab(tabId, questsCfg.value, questsBySection.value,
    progressUnlockBySection.value, progressUnlockByTab.value, serverConfigs.value))

  let scrollHandler = ScrollHandler()
  curSectionId.subscribe(@(_) scrollHandler.scrollToY(0))

  let progressBlock = @() !progressUnlock.get() && headerChildCtor == null ? { watch = progressUnlock }
    : {
        watch = [progressUnlock, curSectionId]
        size = [flex(), progressBarRewardSize]
        flow = FLOW_HORIZONTAL
        gap = isWidescreen ? hdpx(20) : hdpx(5)
        valign = ALIGN_CENTER
        children = [
          headerChildCtor?()
          progressUnlock.get() == null ? null
            : mkProgressBar(progressUnlock.get().__merge({ tabId, sectionId = curSectionId.get() }))
        ]
      }

  return @() {
    watch = tabCurrencies
    key = sections
    size = flex()
    function onAttach() {
      curTabParams.set({ tabId, currencies = tabCurrencies.get() })
      addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    }
    function onDetach() {
      curTabParams.set({})
      removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    }
    children = [
      @() {
        watch = [sections, questsBySection, isProgressBySection, isCurSectionActive]
        size = flex()
        flow = FLOW_VERTICAL
        gap = pageBlocksGap
        children = [
          isProgressBySection.get() ? null : progressBlock

          sections.value.findindex(@(s) questsBySection.value[s].len() > 0) == null ? allQuestsCompleted : null

          sections.value.len() <= 1 ? null
            : mkSectionTabs(sections.value, curSectionId, onSectionChange)

          isProgressBySection.get() ? progressBlock : null

          !isCurSectionActive.get() ? questTimerUntilStart(curSectionId)
            : @() {
                watch = [isCurSectionActive, blocksOnTop]
                size = flex()
                children = !isCurSectionActive.value ? null
                  : [
                      pannableCtors[blocksOnTop.value](
                        @() {
                          watch = [curSectionId, seenQuests, questsBySection, unlockProgress]
                          size = [flex(), SIZE_TO_CONTENT]
                          flow = FLOW_VERTICAL
                          gap = hdpx(20)
                          children = questsBySection.value?[curSectionId.value ?? sections.value?[0]]
                            .values()
                            .filter(@(item) !item?.meta.chain_quest || unlockProgress.get()?[item.requirement].isCompleted)
                            .sort(itemsSort)
                            .map(@(item) itemCtor(item.__merge({ tabId, sectionId = curSectionId.get() })))
                          onDetach = @() saveSeenQuestsForSection(curSectionId.value)
                        },
                        {},
                        { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                      mkScrollArrow(scrollHandler, MR_B)
                    ]
              }
        ]
      }
    ]
  }
}

return {
  questsWndPage
  mkQuest = @(item) mkItem(item, mkQuestText)
  mkAchievement = @(item) mkItem(item, mkAchievementText)

  unseenMarkMargin
}
