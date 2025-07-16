from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { progressBarRewardSize, questItemsGap, rewardProgressBarCtor, statsAnimation
} = require("rewardsComps.nut")
let { getUnlockRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { receiveUnlockRewards, unlockInProgress, unlockProgress } = require("%rGui/unlocks/unlocks.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { mkBalanceDiffAnims } = require("%rGui/mainMenu/balanceAnimations.nut")
let { headerLineGap } = require("questsPkg.nut")
let { sendBqQuestsStage } = require("bqQuests.nut")
let { allShopGoods, isDisabledGoods } = require("%rGui/shop/shopState.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")


let questBarHeight = hdpx(28)
let progressBarHeight = hdpx(30)
let starIconSize = hdpxi(60)
let starIconOffset = hdpx(40)
let borderWidth = hdpx(3)
let bgColor = 0x80000000
let questBarColor = 0xFF2EC181
let completedBarColor = 0xFF505050
let progressBarColor = 0xFF5AA0E9
let progressBarColorLight = 0xFFDEECFA
let barBorderColor = 0xFF606060
let subtleRedColor = 0xC8800000
let BAR_COLOR_SHOW = 0.4
let BAR_COLOR_BLINK = 1.0

let fadeWidth = hdpx(10)
let minStageProgressWidth = hdpx(100)
let progressBarWidthFull = sw(100) - saBorders[0] * 2 - tabW - minContentOffset
let firstProgressWider = starIconOffset

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
  if (change != changeOrders.get()?[name][0] || name not in visibleProgress.value)
    return
  visibleProgress.mutate(@(v) v[name] = change.cur)
  changeOrders.mutate(@(v) v[name].remove(0))
  anim_start($"quest_progress_{name}")
}

let animHighlight = @(name) [
  { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2],
    duration = 0.6, easing = CosineFull, trigger = $"quest_progress_{name}" }
]

let bgGradient = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#gradient_button.svg:0:P")
  color = 0x00505050
}

function mkQuestBar(quest) {
  let current = quest?.current ?? 0
  let required = quest?.required ?? 1
  let questCompletion = current.tofloat() / required
  let trigger = $"unfilledBarEffect_{quest.name}"

  return {
    key = quest.name
    rendObj = ROBJ_BOX
    size = [flex(), questBarHeight]
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

function getCurStageIdx(unlock) {
  let { stages = [], current = 0 } = unlock
  return stages.findindex(@(s) s.progress >= current) ?? stages.reduce(
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
        size = [starIconSize, starIconSize]
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
    children = nextChange.get() == null ? null
      : mkChangeView(name, nextChange.get())
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
  let isRewardInProgress = Computed(@() name in unlockInProgress.value)
  let visProgress = Computed(@() visibleProgress.get()?[name] ?? unlockProgress.get()?[name].current ?? 0)
  let nextChange = Computed(@() changeOrders.get()?[name][0])

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
          .filter(@(reward) !isDisabledGoods(reward))
          .sort(sortRewardsViewInfo))

      function onRewardClick() {
        if (isRewardInProgress.get())
          return
        if (canClaimReward.get()) {
          receiveUnlockRewards(name, stage, { stage, finalStage = idx + 1 })
          sendBqQuestsStage(progressUnlock.__merge({ tabId, sectionId = curSectionId.get() }),
            rewardPreview.get()[0]?.count, rewardPreview.get()[0]?.id)
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
            size = [progressWidth + (idx == 0 ? firstProgressWider : 0), flex()]
            valign = ALIGN_CENTER
            children = [
              @() {
                watch = stageCompletion
                size = [flex(), progressBarHeight]
                children = [
                  {
                    rendObj = ROBJ_SOLID
                    size = flex()
                    color = bgColor
                  }
                  {
                    key = name
                    rendObj = ROBJ_SOLID
                    size = flex()
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
                    size = flex()
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

function rewardWidth(r) {
  let { slots = 1 } = r
  return isDisabledGoods(r) ? 0 : progressBarRewardSize * slots + questItemsGap * (slots - 1)
}

function stageRewardsWidth(rewardsArray) {
  return rewardsArray.reduce(@(total, r) total + rewardWidth(r), 0) + (rewardsArray.len() > 0 ? (rewardsArray.len() - 1) * questItemsGap : 0)
}

function mkQuestListProgressBar(progressUnlock, tabId, curSectionId, headerChildWidth) {
  let progressBarWidth = Computed(@() progressBarWidthFull - starIconOffset
    - (headerChildWidth.get() == 0 ? 0 : headerChildWidth.get() + headerLineGap))
  let stageRewards = Computed(@() (progressUnlock.get()?.stages ?? [])
    .map(@(s) getUnlockRewardsViewInfo(s, serverConfigs.get()).sort(sortRewardsViewInfo)))
  let rewardsFullWidth = Computed(@() stageRewards.get().reduce(@(res, r) res + stageRewardsWidth(r), 0))
  let minWidth = Computed(@() rewardsFullWidth.get() + stageRewards.get().len() * minStageProgressWidth + firstProgressWider)
  let hasScroll = Computed(@() progressBarWidth.get() < minWidth.get())
  return @() progressUnlock.get() == null ? { watch = progressUnlock }
    : {
        watch = [progressUnlock, hasScroll, headerChildWidth, progressBarWidth, minWidth, rewardsFullWidth]
        size = [flex(), progressBarHeight]
        padding = [0, 0, 0, starIconOffset]
        children = [
          !hasScroll.get()
            ? mkStages(progressUnlock.get(),
                (progressBarWidth.get() - rewardsFullWidth.get() - firstProgressWider) / (progressUnlock.get()?.stages.len() || 1),
                tabId, curSectionId)
            : {
                key = hasScroll
                size = [progressBarWidth.get() + fadeWidth * 2, progressBarHeight]
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                function onAttach() {
                  let curStageIdx = getCurStageIdx(progressUnlock.get())
                  if (curStageIdx == null)
                    return
                  local x = 0
                  for (local i = 0; i < curStageIdx; i++)
                    x += minStageProgressWidth + stageRewardsWidth(stageRewards.get()[i])
                  scrollHandler.scrollToX(max(0, x - progressBarRewardSize / 4))
                }
                children = [
                  pannableArea(mkStages(progressUnlock.get(), minStageProgressWidth, tabId, curSectionId),
                    { pos = [0, 0], size = FLEX_H, vplace = ALIGN_CENTER },
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
            size = [starIconSize, starIconSize]
            vplace = ALIGN_CENTER
            pos = [-starIconOffset, hdpx(-7)]
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

  progressBarHeight

  calcStageCompletion
}
