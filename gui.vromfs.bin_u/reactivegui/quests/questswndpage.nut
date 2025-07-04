from "%globalsDarg/darg_library.nut" import *
let {eventbus_subscribe} = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let { questsBySection, seenQuests, saveSeenQuestsForSection, sectionsCfg, questsCfg,
  inactiveEventUnlocks, hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection,
  getQuestCurrenciesInTab, curTabParams, tutorialSectionId, isSameTutorialSectionId, tutorialSectionIdWithReward
} = require("questsState.nut")
let { textButtonSecondary, textButtonCommon, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { receiveUnlockRewards, unlockInProgress, unlockTables, unlockProgress,
  getUnlockPrice, buyUnlock } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { newMark, mkSectionBtn, sectionBtnHeight, sectionBtnMaxWidth, sectionBtnGap, mkTimeUntil,
  allQuestsCompleted, mkAdsBtn, btnSize, headerLineGap, linkToEventWidth
} = require("questsPkg.nut")
let { mkRewardsPreview, questItemsGap, statusIconSize, mkLockedIcon, progressBarRewardSize, mkRewardsPreviewFull,
  getRewardsPreviewInfo, getEventCurrencyReward
} = require("rewardsComps.nut")
let { mkQuestBar, mkQuestListProgressBar } = require("questBar.nut")
let { isSingleViewInfoRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize } = require("%rGui/options/mkOptionsScene.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { defer } = require("dagor.workcycle")
let { sendBqQuestsTask } = require("bqQuests.nut")
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

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

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
    size = FLEX_H
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
    size = FLEX_H
    children = {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = pw(100)
      vplace = ALIGN_CENTER
      text
    }.__update(fontTinyAccented)
  }
}

let purchaseContentCtor = @(textLoc, costLoc) @(rewardsPreview, item) {
  flow = FLOW_VERTICAL
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    msgBoxText(textLoc, { size = SIZE_TO_CONTENT })
    rewardsPreview.len() != 0
      ? {
          flow = FLOW_HORIZONTAL
          gap = hdpx(10)
          children = mkRewardsPreviewFull(rewardsPreview, item?.isFinished)
        }
      : msgBoxText(
          colorize(0xFFE4CB88, loc(item?.meta.lang_id ?? $"treeEvent/subPreset/order/desc/{item?.meta.event_id}")),
          { size = SIZE_TO_CONTENT })
    msgBoxText(costLoc, { size = SIZE_TO_CONTENT })
  ]
}

let buyPurchaseContent = purchaseContentCtor(loc("shop/orderQuestion"), loc("shop/cost"))
let explorePurchaseContent = purchaseContentCtor(loc("shop/orderQuestion/explore"), loc("shop/cost/explore"))

eventbus_subscribe("quests.buyUnlock", function(data) {
  receiveReward(data.item, data.currencyReward)
})

let buyRewardMsgBox = @(item, rewardsPreview, price, currencyId, currencyReward)
  openMsgBoxPurchase({
    text = buyPurchaseContent(rewardsPreview, item),
    price = { price, currencyId },
    purchase = @() buyUnlock(item.name, 1, currencyId, price,
        { onSuccessCb = { id = "quests.buyUnlock", item, currencyReward }})
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, item.name)
  })

let exploreRewardMsgBox = @(item, rewardsPreview, price, currencyId, currencyReward)
  openMsgBoxPurchase({
    text = explorePurchaseContent(rewardsPreview, item),
    price = { price, currencyId },
    purchase = @() buyUnlock(item.name, 1, currencyId, price,
        { onSuccessCb = { id = "quests.buyUnlock", item, currencyReward }})
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, item.name)
    purchaseLocId = "msgbox/btn_explore"
  })

function mkQuestBtn(item, currencyReward, rewardsPreview, sProfile) {
  let { name, progressCorrectionStep = 0 } = item
  let isRewardInProgress = Computed(@() name in unlockInProgress.value)
  let price = getUnlockPrice(item)

  local size = btnSize
  local children = []

  local countReceivedR = 0
  foreach(r in rewardsPreview)
    countReceivedR += isSingleViewInfoRewardEmpty(r, sProfile) ?  1 : 0
  if (item?.hasReward)
    children = textButtonSecondary(
      utf8ToUpper(loc("btn/receive")),
      @() receiveReward(item, currencyReward),
      btnStyleSound)
  else if (countReceivedR == rewardsPreview.len() || item?.isFinished)
    children = {
      size = btnSize
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      text = utf8ToUpper(loc("ui/received"))
      behavior = Behaviors.Button 
    }.__update(fontSmallAccentedShaded)
  else if (progressCorrectionStep > 0)
    children = mkAdsBtn(item)
  else if ((price.price ?? 0) > 0 ) {
    size = [btnSize[0], btnSize[1]*2]
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children =[
        textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_complete")),
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
    key = $"quest_reward_receive_btn_{name}" 
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkSpinnerHideBlock(isRewardInProgress, children)
  }
}

function mkItem(item, textCtor) {
  let isCompletedPrevQuest = Computed(@()
    item.meta?.chain_quest == null
      || (item.meta?.chain_quest && item.requirement == "")
      || (unlockProgress.get()?[item.requirement].isCompleted ?? false)
  )
  let imgLockSize = hdpxi(60)
  let isUnseen = Computed(@() !item.hasReward
    && item.name not in seenQuests.value
    && item.name not in inactiveEventUnlocks.value)

  let rewardsPreview = Computed(@() getRewardsPreviewInfo(item, serverConfigs.get()))
  let eventCurrencyReward = Computed(@() getEventCurrencyReward(rewardsPreview.get()))

  let headerPadding = Computed(@() item.hasReward ? unseenMarkMargin * 2
    : isUnseen.value ? newMarkSize[0]
    : 0)

  return {
    rendObj = ROBJ_SOLID
    color = bgColor
    size = FLEX_H
    xmbNode = {}
    children = [
      @() {
        watch = [isUnseen, isCompletedPrevQuest]
        size = FLEX_H
        children = item.hasReward
            ? {
                margin = unseenMarkMargin
                children = priorityUnseenMark
              }
          : isUnseen.value ? newMark
          : null
      }

      {
        size = FLEX_H
        padding = const [hdpx(10), hdpx(30), hdpx(15), hdpx(30)]
        flow = FLOW_HORIZONTAL
        gap = questItemsGap
        vplace = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          @() {
            watch = headerPadding
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = hdpx(8)
            children = isCompletedPrevQuest.get() ? [
              textCtor(item).__update({padding = [0, 0, 0, headerPadding.value] })
              mkQuestBar(item)
            ] : [
              {
                rendObj = ROBJ_TEXT
                size = const [flex(), hdpx(90)]
                flow = FLOW_HORIZONTAL
                halign = ALIGN_LEFT
                valign = ALIGN_CENTER
                text = loc("quests/requiredCompletePreviousQuest")
              }.__update(fontSmall)
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
            children = isCompletedPrevQuest.get() ? mkQuestBtn(item, eventCurrencyReward.get(), rewardsPreview.get(), servProfile.get())
              : {
                size = btnSize
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = {
                  rendObj = ROBJ_IMAGE
                  size = [imgLockSize, imgLockSize]
                  image = Picture($"ui/gameuiskin#lock_icon.svg:{imgLockSize}:{imgLockSize}:P")
                  keepAspect = true
                }
              }
          }
        ]
      }
      !isCompletedPrevQuest.get() ? {
        rendObj = ROBJ_SOLID
        size = flex()
        color = bgColor
      } : null
    ]
  }
}

let sectionPart = 0.97
let gapPart = 1 - sectionPart

let getSectionTableUnlock = @(sectionUnlocks) sectionUnlocks.findvalue(@(u) (u?.requirement ?? "") == "")
  ?? sectionUnlocks.findvalue(@(_) true)

function isSectionActive(sectionId, questsBySectionV, unlockTablesV) {
  let u = getSectionTableUnlock(questsBySectionV?[sectionId] ?? [])
  return u?.type == "INDEPENDENT" || (unlockTablesV?[u?.table] ?? false)
}

function mkSectionTabs(sections, curSectionId, onSectionChange) {
  let sLen = sections.len()
  let btnWidth = min(sectionBtnMaxWidth, contentWidth / sLen * sectionPart)

  let sectionsFont = Computed(function() {
    foreach (id in sections)
      if (calc_str_box(sectionsCfg.get()?[id] ?? "", fontSmallShaded)[0] > btnWidth - statusIconSize - sectionBtnGap * 2)
        return fontTinyShaded
    return fontSmallShaded
  })

  return {
    size = FLEX_H
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
              text = sectionsCfg.get()?[id]
            }.__update(sectionsFont.value)
          ]
       }).__update({ key = $"sectionId_{id}" }) 
    })
  }
}

function questTimerUntilStart(curSectionId) {
  let sectionTable = Computed(@() getSectionTableUnlock(questsBySection.get()?[curSectionId.get()] ?? [])?.table)
  let startedAt = Computed(@() userstatStats.get()?.inactiveTables[sectionTable.get()]["$startsAt"] ?? 0)
  let timeText = Computed(function() {
    let timeLeft = startedAt.get() - serverTime.get()
    return timeLeft > 0 ? secondsToHoursLoc(timeLeft) : ""
  })

  return @() {
    watch = timeText
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = timeText.get() == "" ? null
      : mkTimeUntil(timeText.get(), "quests/untilTheStart", fontMedium)
  }
}

let questsSort = @(a, b) b.hasReward <=> a.hasReward
  || a.isFinished <=> b.isFinished
  || a.name in seenQuests.value <=> b.name in seenQuests.value
  || a.chainPos <=> b.chainPos
  || a.name <=> b.name

function calcQuestChainPositions(quests) {
  let res = {}
  local hasChanges = true
  while (hasChanges) {
    hasChanges = false
    foreach (name, q in quests)
      if (name in res)
        continue
      else if ((q?.requirement ?? "") == "") {
        res[name] <- 0
        hasChanges = true
      }
      else if (q.requirement in res) {
        res[name] <- res[q.requirement] + 1
        hasChanges = true
      }
  }
  return res
}

let headerLine = @(headerChildCtor, child) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = headerLineGap
  valign = ALIGN_CENTER
  children = [
    headerChildCtor
    child
  ]
}

function questsWndPage(sections, itemCtor, tabId, headerChildCtor = null, headerChildWidth = null) {
  let selSectionId = mkWatched(persist, $"selSectionId_{tabId}", null)
  let curSectionId = Computed(function() {
    let bySection = questsBySection.get()
    let sectionsList = questsCfg.get()?[tabId] ?? []
    local curId = tutorialSectionId.get() ?? selSectionId.get()
    if (!sectionsList.contains(curId))
      curId = null
    if ((bySection?[curId].len() ?? 0) > 0)
      return curId

    foreach(sectionId in sectionsList)
      if ((bySection?[sectionId].len() ?? 0) > 0)
        return sectionId
    return curId ?? sectionsList?[0] ?? sections.get()?[0]
  })

  let tabProgressUnlock = Computed(@() progressUnlockByTab.get()?[tabId])
  let progressUnlock = Computed(@() tabProgressUnlock.get() ?? progressUnlockBySection.get()?[curSectionId.get()])
  let progressUnlockName = Computed(@() progressUnlock.get()?.name)

  let questsSorted = Computed(function() {
    let sectionId = curSectionId.get()
    let list = clone (questsBySection.get()?[sectionId] ?? {})
    if (progressUnlockName.get() in list)
      list.$rawdelete(progressUnlockName.get())

    let chainPos = calcQuestChainPositions(list)
    return list
      .map(@(q, name) q.__merge({
        tabId, sectionId,
        chainPos = chainPos?[name] ?? 0
      }))
      .values()
      .sort(questsSort)
  })
  let questsCount = Computed(@() questsSorted.get().len())

  let isCurSectionActive = Computed(@()
    isSectionActive(curSectionId.get(), questsBySection.get(), unlockTables.get()))

  function onSectionChange(id) {
    saveSeenQuestsForSection(curSectionId.value)
    selSectionId(id)
  }

  let hasProgressUnlock = Computed(@() progressUnlock.get() != null)
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

  let isSectionsEmpty = Computed(@() sections.get().findindex(@(s) questsBySection.get()[s].len() > 0) == null)
  headerChildWidth = headerChildWidth ?? Watched(headerChildCtor == null ? 0 : linkToEventWidth)
  function header() {
    let progressBlock = !hasProgressUnlock.get() ? null
      : headerLine(headerChildCtor, mkQuestListProgressBar(progressUnlock, tabId, curSectionId, headerChildWidth))

    let sectionsComp = isSectionsEmpty.get() ? allQuestsCompleted
      : sections.value.len() > 1 ? mkSectionTabs(sections.value, curSectionId, onSectionChange)
      : null

    let sectionsBlock = !progressBlock
      ? headerLine(headerChildCtor, sectionsComp)
      : sectionsComp

    return {
      watch = [isProgressBySection, sections, isSectionsEmpty, hasProgressUnlock]
      size = FLEX_H
      gap = pageBlocksGap
      flow = FLOW_VERTICAL
      children = isProgressBySection.get() ? [sectionsBlock, progressBlock] : [progressBlock, sectionsBlock]
    }
  }

  let tutorSectionSubscription = @(v) isSameTutorialSectionId.set(v == curSectionId.get())
  function curSectionSubscription(v) {
    isSameTutorialSectionId.set(v == tutorialSectionIdWithReward.get())
    scrollHandler.scrollToY(0)
  }

  return @() {
    watch = tabCurrencies
    key = sections
    size = flex()
    function onAttach() {
      tutorialSectionIdWithReward.subscribe(tutorSectionSubscription)
      curSectionId.subscribe(curSectionSubscription)
      curTabParams.set({ tabId, currencies = tabCurrencies.get() })
      addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    }
    function onDetach() {
      tutorialSectionIdWithReward.unsubscribe(tutorSectionSubscription)
      curSectionId.unsubscribe(curSectionSubscription)
      curTabParams.set({})
      removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    }
    children = [
      @() {
        watch = isCurSectionActive
        size = flex()
        flow = FLOW_VERTICAL
        gap = pageBlocksGap
        children = [
          header

          !isCurSectionActive.get()
              ? questTimerUntilStart(curSectionId)
            : @() {
                watch = [isCurSectionActive, blocksOnTop]
                size = flex()
                children = !isCurSectionActive.value ? null
                  : [
                      pannableCtors[blocksOnTop.value](
                        @() {
                          watch = questsCount
                          size = FLEX_H
                          flow = FLOW_VERTICAL
                          gap = hdpx(20)
                          children = array(questsCount.get())
                            .map(function(_, i) {
                              let q = Computed(@(prev) prevIfEqual(prev, questsSorted.get()?[i]))
                              return @() {
                                watch = q
                                size = FLEX_H
                                children = q.get() == null ? null : itemCtor(q.get())
                              }
                            })
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
  mkQuestBtn
  exploreRewardMsgBox
  mkAchievement = @(item) mkItem(item, mkAchievementText)

  unseenMarkMargin
}
