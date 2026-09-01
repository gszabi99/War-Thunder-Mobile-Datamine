from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/ads/adsState.nut" import isAdsVisible
from "%rGui/components/pannableArea.nut" import horizontalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/mainMenu/balanceAnimations.nut" import mkBalanceDiffAnims
from "%rGui/options/optionsStyle.nut" import minContentOffset, tabW
from "%rGui/quests/bqQuests.nut" import sendBqQuestsStage
from "%rGui/quests/questsState.nut" import getStarsTotalNonUpdatable
from "%rGui/quests/rewardsComps.nut" import progressBarRewardSize, questItemsGap, rewardProgressBarCtor, statsAnimation
from "%rGui/rewards/rewardViewInfo.nut" import getUnlockRewardsViewInfo, sortRewardsViewInfo
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsView/sharedParts.nut" import tagRedColor
from "%rGui/shop/offerByGoodsState.nut" import activeOffersByGoods
from "%rGui/shop/shopState.nut" import allShopGoods, isDisabledGoods
from "%rGui/unlocks/unlocks.nut" import batchReceiveRewards, unlockInProgress, unlockProgress
from "%rGui/unlocks/userstat.nut" import isUserstatMissingData


const questBarHeight = hdpx(28)
const progressBarHeight = hdpx(30)
const starIconSize = hdpxi(60)
const starIconOffset = hdpx(44)
const borderWidth = hdpx(3)
const bgColor = 0x80000000
const questBarColor = 0xFF2EC181
const completedBarColor = 0xFF505050
const progressBarColor = 0xFF5AA0E9
const progressBarColorLight = 0xFFDEECFA
const barBorderColor = 0xFF606060
const subtleRedColor = 0xC8800000
const BAR_COLOR_SHOW = 0.4
const BAR_COLOR_BLINK = 1.0

const fadeWidth = hdpx(10)
const minStageProgressWidth = hdpx(122)
let progressBarWidthFull = sw(100) - saBorders[0] * 2 - tabW - minContentOffset
let progressBarWidthNoTabs = saSize[0]
const firstProgressWider = starIconOffset

let visibleProgress = hardPersistWatched("unlocks.visibleProgress", {})
let changeOrders = hardPersistWatched("unlocks.changeOrders", {})
isLoggedIn.subscribe(function(_) {
  visibleProgress.set({})
  changeOrders.set({})
})

let onStageRewardClickByType = {
  function discount(reward) {
    let goodsIdByPersonalDisc = serverConfigs.get()?.personalDiscounts
      .findindex(@(list) list.findindex(@(v) v.id == reward.id) != null)
    let needShowAsOffer = allShopGoods.get()?[goodsIdByPersonalDisc].meta.showAsOffer

    if (needShowAsOffer && goodsIdByPersonalDisc in activeOffersByGoods.get())
      openGoodsPreview(goodsIdByPersonalDisc)
  }
}

let initProgress = @(name) name in visibleProgress.get() ? null
  : visibleProgress.mutate(@(v) v[name] <- unlockProgress.get()?[name].current)

function applyChanges(changes) {
  if (changes.len() != 0)
    changeOrders.mutate(function(list) {
      foreach (id, info in changes) {
        let idList = id in list ? clone list[id] : []
        idList.append(info)
        list[id] <- idList
      }
    })
}

local prevUP = {}
function recalcPrevUp() {
  prevUP = visibleProgress.get().map(@(_, name) unlockProgress.get()?[name].current)
}
recalcPrevUp()

unlockProgress.subscribe(function(up) {
  if (isUserstatMissingData.get())
    return
  let changes = {}
  let visProgressApply = {}
  foreach (name, val in visibleProgress.get()) {
    let cur = up?[name].current
    if (val == null || cur == null) {
      if (cur != null)
        visProgressApply[name] <- cur
      continue
    }
    let diff = cur - (prevUP?[name] ?? 0)
    if (diff != 0)
      changes[name] <- { cur, diff }
  }
  recalcPrevUp()
  applyChanges(changes)
  if (visProgressApply.len() > 0)
    visibleProgress.set(visibleProgress.get().__merge(visProgressApply))
})

function onChangeAnimFinish(name, change) {
  if (change != changeOrders.get()?[name][0] || name not in visibleProgress.get())
    return
  visibleProgress.mutate(@(v) v[name] = change.cur)
  changeOrders.mutate(function(v) {
    let list = clone v[name]
    list.remove(0)
    v[name] = list
  })
  anim_start($"quest_progress_{name}")
}

let animHighlight = @(name) [
  { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2],
    duration = 0.6, easing = CosineFull, trigger = $"quest_progress_{name}" }
]

let bgGradient = {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#gradient_button.svg:0:P")
  color = 0x00505050
}

function mkQuestBar(quest, triggerPostfix = null) {
  let current = quest?.current ?? 0
  let required = quest?.required ?? 1
  let questCompletion = current.tofloat() / required
  let trigger = $"unfilledBarEffect_{triggerPostfix ?? quest.name}"

  return {
    key = quest.name
    rendObj = ROBJ_BOX
    size = const [FLEX, questBarHeight]
    fillColor = bgColor
    borderWidth
    borderColor = barBorderColor
    animations = [
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_SHOW,
        easing = InOutQuad, from = bgColor, to = tagRedColor, trigger
      }
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_BLINK, delay = BAR_COLOR_SHOW,
        easing = CosineFull, from = tagRedColor, to = subtleRedColor, trigger
      }
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_SHOW, delay = BAR_COLOR_SHOW + BAR_COLOR_BLINK,
        easing = InOutQuad, from = tagRedColor, to = bgColor, trigger
      }
    ]
    children = [
      {
        rendObj = ROBJ_BOX
        size = [pw(100 * questCompletion), questBarHeight]
        fillColor = quest?.isFinished
          ? completedBarColor
          : questBarColor
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = quest?.isFinished ? loc("ui/received") : $"{current}/{required}"
        padding = const [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let scrollHandler = ScrollHandler()
let pannableArea = horizontalPannableAreaCtor(progressBarWidthFull, [fadeWidth, fadeWidth])
let pannableAreaNoTabs = horizontalPannableAreaCtor(progressBarWidthNoTabs, [fadeWidth, fadeWidth])

function getCurStageIdx(unlock) {
  let { stages = [], current = 0 } = unlock
  return stages.findindex(@(s) s.progress > current ) ?? stages.reduce(
    @(res, s, idx) s.progress >= res.progress ? { idx, progress = s.progress } : res,
    { idx = null, progress = 0 }).idx
}

function calcStageCompletion(stages, idx, current) {
  let prevProgress = stages?[idx - 1].progress ?? 0
  return clamp((current.tofloat() - prevProgress) / (stages[idx].progress - prevProgress), 0.0, 1.0)
}

let mkChangeView = @(name, change) {
  key = change
  zOrder = Layers.Upper
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        size = const [starIconSize, starIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#quest_experience_icon.avif:{starIconSize}:{starIconSize}:P")
      }
      {
        rendObj = ROBJ_TEXT
        text = change.diff < 0 ? change.diff : $"+{change.diff}"
      }.__update(fontVeryTinyShaded)
    ]
  }
  transform = {}
  animations = mkBalanceDiffAnims(@() onChangeAnimFinish(name, change))
  sound = { attach = "meta_coins_income" }
}

let questBarProgressValue = @(name, required, visProgress, nextChange) @() {
  watch = visProgress
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  text = $"{visProgress.get()}/{required}"
  children = @() {
    watch = nextChange
    size = 0 
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = nextChange.get() == null ? null : mkChangeView(name, nextChange.get())
  }
  transform = {}
  animations = animHighlight(name)
}.__update(fontVeryTinyShaded, isWidescreen ? {} : { fontSize = fontVeryTinyShaded.fontSize * 0.85 })

let multiRewardProgressBarCtor = @(rewards, isUnlocked, onRewardClick, canClaimReward, isRewardInProgress) {
  flow = FLOW_HORIZONTAL
  gap = questItemsGap
  children = rewards.map(@(reward) {
    children = rewardProgressBarCtor(reward, isUnlocked, onRewardClick, canClaimReward, isRewardInProgress)
  })
}

function mkStages(progressUnlock, progressWidth, tabId, curSectionId) {
  let curStageIdx = getCurStageIdx(progressUnlock)
  let { hasReward = false, stage, stages, name } = progressUnlock
  let required = stages?[curStageIdx].progress
  let isRewardInProgress = Computed(@() name in unlockInProgress.get())
  let visProgress = Computed(@() visibleProgress.get()?[name] ?? unlockProgress.get()?[name].current ?? 0)
  let nextChange = Computed(@() isAdsVisible.get() ? null : changeOrders.get()?[name][0])
  return {
    key = name
    size = [SIZE_TO_CONTENT, progressBarRewardSize]
    onAttach = @() initProgress(name)
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = array(stages.len()).map(function(_, idx) {
      let stageCompletion = Computed(@() calcStageCompletion(stages, idx, visProgress.get()))
      let isUnlocked = Computed(@() stageCompletion.get() >= 1.0)
      let canClaimReward = Computed(@() isUnlocked.get() && hasReward && (idx + 1) >= stage)

      let rewardPreview = Computed(@()
        getUnlockRewardsViewInfo(stages[idx], serverConfigs.get())
          .filter(@(reward) !isDisabledGoods(reward, allShopGoods.get(), serverConfigs.get()))
          .sort(sortRewardsViewInfo))

      function onRewardClick() {
        if (isRewardInProgress.get())
          return
        if (canClaimReward.get()) {
          batchReceiveRewards([{ unlock = name, up_to_stage = idx + 1 }])
          let unlock = progressUnlock.__merge({ tabId, sectionId = curSectionId.get() })
          let { count = null, id = null } = rewardPreview.get()[0]
          sendBqQuestsStage(unlock, getStarsTotalNonUpdatable(unlock), count, id)
          return
        }
        let reward = rewardPreview.get()?[0]
        if (reward?.rType in onStageRewardClickByType)
          return onStageRewardClickByType[reward.rType](reward)
        if (stageCompletion.get() < 1.0)
          return anim_start("eventProgressStats")
      }

      return {
        size = FLEX_V
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [progressWidth + (idx == 0 ? firstProgressWider : 0), FLEX]
            valign = ALIGN_CENTER
            children = [
              @() {
                watch = stageCompletion
                size = const [FLEX, progressBarHeight]
                children = [
                  {
                    rendObj = ROBJ_BOX
                    size = FLEX
                    fillColor = bgColor
                    borderWidth = const [borderWidth, 0]
                    borderColor = barBorderColor
                  }
                  {
                    key = name
                    rendObj = ROBJ_SOLID
                    size = FLEX
                    color = progressBarColorLight
                    transform = {
                      scale = [stageCompletion.get(), 1.0]
                      pivot = [0, 0]
                    }
                    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
                  }
                  {
                    key = name
                    rendObj = ROBJ_SOLID
                    size = FLEX
                    color = progressBarColor
                    transform = {
                      scale = [stageCompletion.get(), 1.0]
                      pivot = [0, 0]
                    }
                    transitions = [{ prop = AnimProp.scale, duration = 1.0, easing = InOutQuad }]
                    children = bgGradient
                  }
                ]
              }
              idx != curStageIdx ? null : questBarProgressValue(name, required, visProgress, nextChange)
            ]
          }
          @() {
            watch = [rewardPreview, isRewardInProgress, isUnlocked, canClaimReward]
            key = $"quest_bar_stage_{idx}" 
            children = (rewardPreview.get()?.len() ?? 0) == 0 ? null
              : multiRewardProgressBarCtor(rewardPreview.get(), isUnlocked.get(), onRewardClick,
                  canClaimReward.get(), isRewardInProgress.get())
          }
        ]
      }
    })
  }
}

function rewardWidth(r, allGoods, servConfigs) {
  let { slots = 1 } = r
  return isDisabledGoods(r, allGoods, servConfigs) ? 0
    : progressBarRewardSize * slots + questItemsGap * (slots - 1)
}

function stageRewardsWidth(rewardsArray, allGoods, servConfigs) {
  return rewardsArray.reduce(@(total, r) total + rewardWidth(r, allGoods, servConfigs), 0)
    + (rewardsArray.len() > 0 ? (rewardsArray.len() - 1) * questItemsGap : 0)
}

function mkQuestListProgressBar(progressUnlock, tabId, curSectionId, isFullScreenWidth) {
  let barWidthFull = Computed(@() isFullScreenWidth.get() ? progressBarWidthNoTabs : progressBarWidthFull)
  let progressBarWidth = Computed(@() barWidthFull.get() - starIconOffset)
  let stageRewards = Computed(@() (progressUnlock.get()?.stages ?? [])
    .map(@(s) getUnlockRewardsViewInfo(s, serverConfigs.get()).sort(sortRewardsViewInfo)))
  let rewardsFullWidth = Computed(@() stageRewards.get()
    .reduce(@(res, r) res + stageRewardsWidth(r, allShopGoods.get(), serverConfigs.get()), 0))
  let minWidth = Computed(@() rewardsFullWidth.get() + stageRewards.get().len() * minStageProgressWidth + firstProgressWider)
  let hasScroll = Computed(@() progressBarWidth.get() < minWidth.get())
  return @() progressUnlock.get() == null ? { watch = progressUnlock }
    : {
        watch = [progressUnlock, hasScroll, progressBarWidth, minWidth, rewardsFullWidth, isFullScreenWidth]
        hplace = ALIGN_LEFT
        padding = const [0, 0, 0, starIconOffset]
        children = [
          !hasScroll.get()
            ? mkStages(progressUnlock.get(), minStageProgressWidth, tabId, curSectionId)
            : {
                key = hasScroll
                size = [progressBarWidth.get() + fadeWidth * 2, progressBarRewardSize]
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                function onAttach() {
                  let curStageIdx = getCurStageIdx(progressUnlock.get())
                  if (curStageIdx == null)
                    return
                  local x = 0
                  for (local i = 0; i < curStageIdx; i++)
                    x += minStageProgressWidth + stageRewardsWidth(stageRewards.get()[i], allShopGoods.get(), serverConfigs.get())
                  scrollHandler.scrollToX(max(0, x - progressBarRewardSize / 4))
                }
                children = [
                  (isFullScreenWidth.get() ? pannableAreaNoTabs : pannableArea)(
                    mkStages(progressUnlock.get(), minStageProgressWidth, tabId, curSectionId),
                    { pos = const [0, 0], size = FLEX_H, vplace = ALIGN_CENTER },
                    {
                      size = FLEX_H
                      behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
                      scrollHandler
                    })
                  {
                    size = [progressBarWidth.get() + hdpx(80), SIZE_TO_CONTENT]
                    hplace = ALIGN_LEFT
                    vplace = ALIGN_CENTER
                    children = mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
                  }
                ]
              }
          {
            key = progressUnlock.get().name
            size = const [starIconSize, starIconSize]
            vplace = ALIGN_CENTER
            pos = const [-starIconOffset, hdpx(-7)]
            rendObj = ROBJ_IMAGE
            image = Picture("ui/gameuiskin#quest_experience_icon.avif:0:P")
            transform = {}
            animations = animHighlight(progressUnlock.get().name).append(statsAnimation)
          }
        ]
      }
}

return {
  mkQuestBar
  mkQuestListProgressBar

  calcStageCompletion
}
