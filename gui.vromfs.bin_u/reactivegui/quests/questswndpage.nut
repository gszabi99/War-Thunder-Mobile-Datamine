from "%globalsDarg/darg_library.nut" import *
let {eventbus_subscribe} = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let { adBudgetInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { questsBySection, seenQuests, saveSeenQuestsForSection, sectionsCfg, questsCfg, mkHasReceivedAllRewards,
  inactiveEventUnlocks, hasUnseenQuestsBySection, progressUnlockByTab, progressUnlockBySection,
  getQuestCurrenciesInTab, curTabParams, tutorialSectionId, isSameTutorialSectionId, tutorialSectionIdWithReward
} = require("%rGui/quests/questsState.nut")
let { textButtonSecondary, textButtonInactive, textButtonPricePurchase, iconButtonCommon, iconButtonInactive
} = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { receiveUnlockRewards, unlockInProgress, unlockTables, unlockProgress,
  getUnlockPrice, buyUnlock, buyUnlockReroll } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { newMark, mkSectionBtn, sectionBtnHeight, sectionBtnMaxWidth, sectionBtnGap, mkTimeUntil,
  allQuestsCompleted, mkAdsBtn, btnSize, headerLineGap, linkToEventWidth, mkQuestText
} = require("%rGui/quests/questsPkg.nut")
let { mkRewardsPreview, questItemsGap, statusIconSize, mkLockedIcon, progressBarRewardSize, mkRewardsPreviewFull,
  getRewardsPreviewInfo, getEventCurrencyReward, REWARDS_PREVIEW_SLOTS
} = require("%rGui/quests/rewardsComps.nut")
let { mkQuestBar, mkQuestListProgressBar } = require("%rGui/quests/questBar.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize } = require("%rGui/options/mkOptionsScene.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { userstatStatsTables } = require("%rGui/unlocks/userstat.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { defer } = require("dagor.workcycle")
let { sendBqQuestsTask } = require("%rGui/quests/bqQuests.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, PURCH_SRC_OPERATION_PASS, PURCH_TYPE_QUEST_REROLL,
  mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkChainProgress } = require("%rGui/quests/questChain.nut")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { G_UNIT } = require("%appGlobals/rewardType.nut")
let { REWARD_STYLE_VERY_TINY } = require("%rGui/rewards/rewardStyles.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles


let bgColor = 0x80000000
let unseenMarkMargin = hdpx(20)
let pageBlocksGap = hdpx(30)
let lockedOpacity = 0.5
let gradientHeightBottom = saBorders[1]

let childOvr = (saRatio < 2 ? fontTinyAccentedShadedBold : {})
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

function mkAchievementText(item, ovr = {}) {
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
  }.__update(ovr)
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
          children = mkRewardsPreviewFull(rewardsPreview, item?.isFinished, REWARD_STYLE_VERY_TINY)
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

let rerollQuestMsgBox = @(unlockName, price, currencyId)
  openMsgBoxPurchase({
    text = loc("quests/needMoneyQuestion_reroll"),
    price = { price, currencyId },
    purchase = @() buyUnlockReroll(unlockName, price, currencyId)
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_OPERATION_PASS, PURCH_TYPE_QUEST_REROLL, unlockName)
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

function mkQuestBtn(item, currencyReward, rewardsPreview, hasReceivedAllRewards) {
  let { name, progressCorrectionStep = 0 } = item
  let hasAds = !item?.hasReward && !hasReceivedAllRewards && progressCorrectionStep > 0
  let isRewardInProgress = hasAds ? Computed(@() name in unlockInProgress.get() || adBudgetInProgress.get())
    : Computed(@() name in unlockInProgress.get())
  let price = getUnlockPrice(item)

  let questBtn = item?.hasReward
      ? textButtonSecondary(
          utf8ToUpper(loc("btn/receive")),
          @() receiveReward(item, currencyReward),
          btnStyleSound)
    : hasReceivedAllRewards
      ? {
          size = btnSize
          rendObj = ROBJ_TEXT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          text = utf8ToUpper(loc("ui/received"))
          behavior = Behaviors.Button 
        }.__update(fontTinyAccentedShaded)
    : progressCorrectionStep > 0 ? mkAdsBtn(item)
    : (price.price ?? 0) > 0
      ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_complete")),
          mkCurrencyComp(price.price, price.currency).__merge({size = [SIZE_TO_CONTENT, CS_COMMON.iconSize]}),
          @() buyRewardMsgBox(item, rewardsPreview, price.price , price.currency, currencyReward),
          btnStyle)
    : textButtonInactive(
        utf8ToUpper(loc("btn/receive")),
        @() anim_start($"unfilledBarEffect_{name}"),
        btnStyle)
  return {
    key = $"quest_reward_receive_btn_{name}" 
    size = btnSize
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = mkSpinnerHideBlock(isRewardInProgress, questBtn)
  }
}

function mkItemTimerUntilReroll(statsTable) {
  let timeText = Computed(function() {
    if (!statsTable.get()?.rerollPrice)
      return ""
    let timeLeft = (statsTable.get()?["$endsAt"] ?? 0) - serverTime.get()
    return timeLeft > 0 ? secondsToHoursLoc(timeLeft) : ""
  })

  return @() {
    watch = timeText
    size = FLEX_H
    children = timeText.get() == "" ? null
      : {
          size = FLEX_H
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          padding = hdpx(48)
          children = mkTimeUntil(timeText.get(), "quests/newTaskIn", fontMedium)
        }
  }
}

let mkRerollBtn = @(item, rerollPrice, hasReceivedAllRewards) @() {
  watch = hasReceivedAllRewards
  vplace = ALIGN_TOP
  children = mkSpinnerHideBlock(Computed(@() item.name in unlockInProgress.get()),
    item.hasReward || hasReceivedAllRewards.get()
      ? iconButtonInactive($"ui/gameuiskin#icon_repeatable.svg",
          @() null
          { ovr = { size = [btnSize[1], btnSize[1]], minWidth = 0 } })
      : iconButtonCommon($"ui/gameuiskin#icon_repeatable.svg",
          @() rerollQuestMsgBox(item.name, rerollPrice.get().price, rerollPrice.get().currency),
          { ovr = { size = [btnSize[1], btnSize[1]], minWidth = 0 } }))
}

let getSectionTableUnlock = @(sectionUnlocks) sectionUnlocks.findvalue(@(u) (u?.requirement ?? "") == "")
  ?? sectionUnlocks.findvalue(@(_) true)

function mkItem(item, textCtor, sectionId) {
  let isCompletedPrevQuest = Computed(@()
    item.meta?.chain_quest == null
      || (item.meta?.chain_quest && item.requirement == "")
      || (unlockProgress.get()?[item.requirement].isCompleted ?? false)
  )
  let imgLockSize = hdpxi(60)
  let isUnseen = Computed(@() !item.hasReward
    && item.name not in seenQuests.get()
    && item.name not in inactiveEventUnlocks.get())

  let rewardsPreview = Computed(@() getRewardsPreviewInfo(item, serverConfigs.get()))
  let filteredRewardsPreview = Computed(function() {
    let { allUnits = {} } = serverConfigs.get()
    return rewardsPreview.get().filter(@(v) v.rType != G_UNIT || campaignsList.get().contains(allUnits?[v.id].campaign))
  })
  let eventCurrencyReward = Computed(@() getEventCurrencyReward(filteredRewardsPreview.get()))
  let hasReceivedAllRewards = mkHasReceivedAllRewards(Watched(item), rewardsPreview)

  let statsTable = Computed(@()
    userstatStatsTables.get()?.stats[getSectionTableUnlock(questsBySection.get()?[sectionId] ?? [])?.table])
  let rerollPrice = Computed(@() statsTable.get()?.rerollPrice)

  let hasRerollBtn = Computed(@() rerollPrice.get() != null)
  let isHiddenForReroll = Computed(@() hasRerollBtn.get() && hasReceivedAllRewards.get())

  let leftBlockMinHeight = Computed(@() hasRerollBtn.get()
    ? 2 * btnSize[1] + questItemsGap
    : btnSize[1])
  let headerPadding = item.hasReward ? Watched(unseenMarkMargin * 2)
    : Computed(@()isUnseen.get() ? newMarkSize[0] : 0)

  return {
    rendObj = ROBJ_SOLID
    color = bgColor
    size = FLEX_H
    xmbNode = {}
    children = [
      @() {
        watch = isUnseen
        size = FLEX_H
        children = item.hasReward
            ? {
                margin = unseenMarkMargin
                children = priorityUnseenMark
              }
          : isUnseen.get() ? newMark
          : null
      }

      @() {
        watch = isHiddenForReroll
        size = FLEX_H
        children = isHiddenForReroll.get() ? mkItemTimerUntilReroll(statsTable)
          : {
              size = FLEX_H
              padding = const [hdpx(10), hdpx(30), hdpx(15), hdpx(30)]
              flow = FLOW_HORIZONTAL
              gap = questItemsGap
              valign = ALIGN_BOTTOM
              children = [
                @() {
                  watch = [isCompletedPrevQuest, headerPadding, leftBlockMinHeight]
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  minHeight = leftBlockMinHeight.get()
                  gap = hdpx(8)
                  children = isCompletedPrevQuest.get()
                    ? [
                        !item?.chainQuests ? null : mkChainProgress(item, {padding = [0, 0, 0, headerPadding.get()]})
                        textCtor(item, {padding = [0, 0, 0, headerPadding.get()] })
                        { size = flex() }
                        mkQuestBar(item)
                      ].filter(@(v) v != null)
                    : {
                        rendObj = ROBJ_TEXT
                        size = const [flex(), hdpx(90)]
                        flow = FLOW_HORIZONTAL
                        halign = ALIGN_LEFT
                        valign = ALIGN_CENTER
                        text = loc("quests/requiredCompletePreviousQuest")
                      }.__update(fontTinyAccented)
                }

                @() {
                  watch = hasRerollBtn
                  flow = FLOW_VERTICAL
                  gap = questItemsGap
                  halign = ALIGN_RIGHT
                  children = [
                    !hasRerollBtn.get() ? null : mkRerollBtn(item, rerollPrice, hasReceivedAllRewards)
                    {
                      vplace = ALIGN_BOTTOM
                      flow = FLOW_HORIZONTAL
                      gap = questItemsGap
                      children = [
                        @() {
                          watch = filteredRewardsPreview
                          flow = FLOW_HORIZONTAL
                          gap = questItemsGap
                          halign = ALIGN_RIGHT
                          children = filteredRewardsPreview.get().len() > 0
                            ? mkRewardsPreview(filteredRewardsPreview.get(), item?.isFinished, REWARDS_PREVIEW_SLOTS, REWARD_STYLE_VERY_TINY)
                            : null
                        }

                        @() {
                          watch = [isCompletedPrevQuest, eventCurrencyReward, rewardsPreview, hasReceivedAllRewards]
                          children = isCompletedPrevQuest.get() ? mkQuestBtn(item, eventCurrencyReward.get(), rewardsPreview.get(), hasReceivedAllRewards.get())
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
                  ].filter(@(v) v != null)
                }
              ]
            }
      }

      @() {
        watch = isCompletedPrevQuest
        size = FLEX_H
        children = isCompletedPrevQuest.get() ? null
          : {
              rendObj = ROBJ_SOLID
              size = flex()
              color = bgColor
            }
      }
    ]
  }
}

let sectionPart = 0.97

let isSectionUnlockActive = @(u, unlockTablesV) u?.type == "INDEPENDENT" || (unlockTablesV?[u?.table] ?? false)

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
    gap = hdpx(8)
    children = sections.map(function(id) {
      let isUnlocked = Computed(@()
        isSectionUnlockActive(getSectionTableUnlock(questsBySection.get()?[id] ?? []), unlockTables.get()))
      return mkSectionBtn(@() onSectionChange(id),
        Computed(@() curSectionId.get() == id),
        Computed(@() !!hasUnseenQuestsBySection.get()?[id]
          || !!progressUnlockBySection.get()?[id].hasReward),
        @() {
          watch = [isUnlocked, sectionsFont, sectionsCfg]
          flow = FLOW_HORIZONTAL
          gap = sectionBtnGap
          valign = ALIGN_CENTER
          children = [
            isUnlocked.get() ? null : mkLockedIcon({ opacity = lockedOpacity })
            @() {
              watch = [sectionsCfg, sectionsFont]
              rendObj = ROBJ_TEXT
              opacity = isUnlocked.get() ? 1.0 : lockedOpacity
              text = sectionsCfg.get()?[id]
            }.__update(sectionsFont.get())
          ]
       }).__update({ key = $"sectionId_{id}" }) 
    })
  }
}

function questTimerUntilStart(sectionTable) {
  let startedAt = Computed(@() userstatStatsTables.get()?.inactiveTables[sectionTable.get()?.table]["$startsAt"] ?? 0)
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
  || "chainQuests" in b <=> "chainQuests" in a
  || a.name in seenQuests.get() <=> b.name in seenQuests.get()
  || a.name <=> b.name

let pQuestsSortByDifficult = @(a, b) (a?.personal ?? "") <=> (b?.personal ?? "")
let pQuestsSort = @(a, b) (a?.pOrder ?? 0) <=> (b?.pOrder ?? 0)

function mergeQuestChains(quests, tabId, sectionId) {
  let res = {}
  local chains = {}

  foreach (name, q in quests) {
    let qExt = q.__merge({ tabId, sectionId })
    if (q?.requirement in quests && q.requirement not in chains)
      chains[q.requirement] <- [qExt]
    else
      res[name] <- qExt
  }

  local hasChanges = true
  while (hasChanges) {
    let newChains = clone chains
    foreach (req, c in chains) {
      let name = c.top().name
      if (name not in newChains || req not in newChains)
        continue
      c.extend(newChains[name])
      newChains.$rawdelete(name)
    }

    hasChanges = chains.len() != newChains.len()
    chains = newChains
  }

  foreach (name, c in chains) {
    let q = res[name]
    c.insert(0, q)
    let actualQuestIdx = c.findindex(@(quest) (!quest.isFinished && (quest.requirement == "" || unlockProgress.get()[quest.requirement].isFinished))
      || (quest.isFinished && c[c.len() - 1].name == quest.name)) ?? 0
    if (actualQuestIdx == 0)
      res[name] <- q.__merge({ chainQuests = c, pos = actualQuestIdx })
    else {
      res.$rawdelete(name)
      res[c[actualQuestIdx].name] <- c[actualQuestIdx].__merge({ chainQuests = c, pos = actualQuestIdx })
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
  ].filter(@(v) v != null)
}

function questsWndPage(sections, itemCtor, tabId, headerChildCtor = null, headerChildWidth = null, hasHeader = null) {
  let selSectionId = mkWatched(persist, $"selSectionId_{tabId}", null)
  let personalQuestsOrder = mkWatched(persist, $"personalQuestsOrdera_{tabId}", {})
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

  let questsSortedByPersonal = Computed(function() {
    let sectionId = curSectionId.get()
    let list = clone (questsBySection.get()?[sectionId] ?? {})
    if (progressUnlockName.get() in list)
      list.$rawdelete(progressUnlockName.get())
    let mergedList = mergeQuestChains(list, tabId, sectionId).values()

    return {
      personal = mergedList.filter(@(v) v.personal != "").sort(pQuestsSortByDifficult)
      common = mergedList.filter(@(v) v.personal == "").sort(questsSort)
    }
  })
  let questsCount = Computed(@() questsSortedByPersonal.get().common.len() + questsSortedByPersonal.get().personal.len())
  let questsSorted = Computed(function() {
    let { personal, common } = questsSortedByPersonal.get()
    let personalOrder = personalQuestsOrder.get()
    return [].extend(
      common
      personal.map(@(v) v.__merge({ pOrder = personalOrder?[v.name] })).sort(pQuestsSort)
    )
  })

  let sectionTableUnlock = Computed(@() getSectionTableUnlock(questsBySection.get()?[curSectionId.get()] ?? []))
  let isCurSectionActive = Computed(@() isSectionUnlockActive(sectionTableUnlock.get(), unlockTables.get()))

  function onSectionChange(id) {
    saveSeenQuestsForSection(curSectionId.get())
    selSectionId.set(id)
  }

  let hasProgressUnlock = Computed(@() progressUnlock.get() != null)
  let isProgressBySection = Computed(@() tabProgressUnlock.get() == null)

  hasHeader = hasHeader ?? Watched(headerChildCtor != null)
  let blocksOnTop = Computed(function() {
    local n = 0
    if (progressUnlock.get() || hasHeader.get())
      n++
    if (sections.get().len() > 1)
      n++
    return n
  })

  let tabCurrencies = Computed(@() getQuestCurrenciesInTab(tabId, questsCfg.get(), questsBySection.get(),
    progressUnlockBySection.get(), progressUnlockByTab.get(), userstatStatsTables.get(), serverConfigs.get()))

  let scrollHandler = ScrollHandler()

  let isSectionsEmpty = Computed(@() sections.get().findindex(@(s) questsBySection.get()[s].len() > 0) == null)
  headerChildWidth = headerChildWidth ?? Computed(@() hasHeader.get() ? linkToEventWidth : 0)
  function header() {
    let progressBlock = !hasProgressUnlock.get() ? null
      : !hasHeader.get() ? mkQuestListProgressBar(progressUnlock, tabId, curSectionId, headerChildWidth)
      : headerLine(headerChildCtor, mkQuestListProgressBar(progressUnlock, tabId, curSectionId, headerChildWidth))

    let sectionsComp = isSectionsEmpty.get() ? allQuestsCompleted
      : sections.get().len() > 1
        ? {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              mkSectionTabs(sections.get(), curSectionId, onSectionChange)
              {
                size = [flex(), hdpx(4)]
                rendObj = ROBJ_SOLID
                color = selectColor
              }
            ]
          }
      : null

    let sectionsBlock = !progressBlock && hasHeader.get()
      ? headerLine(headerChildCtor, sectionsComp)
      : sectionsComp

    if (!sectionsBlock && !progressBlock)
      return { watch = [isProgressBySection, sections, isSectionsEmpty, hasProgressUnlock, hasHeader] }

    return {
      watch = [isProgressBySection, sections, isSectionsEmpty, hasProgressUnlock, hasHeader]
      size = FLEX_H
      gap = pageBlocksGap
      flow = FLOW_VERTICAL
      children = !isProgressBySection.get()
        ? [progressBlock, sectionsBlock].filter(@(v) v != null)
        : [sectionsBlock, progressBlock?.__update({ rendObj = ROBJ_SOLID, color = 0x990C1113 })].filter(@(v) v != null)
    }
  }

  let tutorSectionSubscription = @(v) isSameTutorialSectionId.set(v == curSectionId.get())
  function curSectionSubscription(v) {
    isSameTutorialSectionId.set(v == tutorialSectionIdWithReward.get())
    scrollHandler.scrollToY(0)
  }
  function personalQuestsSubcription(quests) {
    let { personal } = quests
    let order = personalQuestsOrder.get()
    if (personal.len() == 0) {
      if (order.len() != 0)
        personalQuestsOrder.set({})
      return
    }
    else if (order.len() == 0) {
      personalQuestsOrder.set(personal.reduce(@(res, q, idx) res.$rawset(q.name, idx), {}))
      return
    }

    let resOrder = array(personal.len())
    foreach (name, idx in order) {
      let quest = personal.findvalue(@(q) q.name == name)
      if (quest != null)
        resOrder[idx] = name
    }

    foreach (q in personal)
      if (!resOrder.contains(q.name)) {
        let newIdx = resOrder.findindex(@(v) v == null)
        if (newIdx != null)
          resOrder[newIdx] = q.name
      }

    personalQuestsOrder.set(resOrder.reduce(@(res, name, idx) res.$rawset(name, idx), {}))
  }

  return @() {
    watch = tabCurrencies
    key = sections
    size = flex()
    function onAttach() {
      tutorialSectionIdWithReward.subscribe(tutorSectionSubscription)
      curSectionId.subscribe(curSectionSubscription)
      personalQuestsSubcription(questsSortedByPersonal.get())
      questsSortedByPersonal.subscribe(personalQuestsSubcription)
      curTabParams.set({ tabId, currencies = tabCurrencies.get() })
      addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    }
    function onDetach() {
      tutorialSectionIdWithReward.unsubscribe(tutorSectionSubscription)
      curSectionId.unsubscribe(curSectionSubscription)
      questsSortedByPersonal.unsubscribe(personalQuestsSubcription)
      personalQuestsOrder.set({})
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
              ? questTimerUntilStart(sectionTableUnlock)
            : @() {
                watch = [isCurSectionActive, blocksOnTop]
                size = flex()
                children = !isCurSectionActive.get() ? null
                  : [
                      pannableCtors[blocksOnTop.get()](
                        @() {
                          watch = questsCount
                          size = FLEX_H
                          flow = FLOW_VERTICAL
                          gap = hdpx(20)
                          children = array(questsCount.get())
                            .map(function(_, i) {
                              let q = Computed(@(prev) prevIfEqual(prev, questsSorted.get()?[i]))
                              return @() {
                                watch = [q, curSectionId]
                                size = FLEX_H
                                children = q.get() == null ? null : itemCtor(q.get(), curSectionId.get())
                              }
                            })
                          onDetach = @() saveSeenQuestsForSection(curSectionId.get())
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
  mkQuest = @(item, sectionId) mkItem(item, mkQuestText, sectionId)
  mkQuestBtn
  exploreRewardMsgBox
  mkAchievement = @(item, sectionId) mkItem(item, mkAchievementText, sectionId)

  unseenMarkMargin
}
