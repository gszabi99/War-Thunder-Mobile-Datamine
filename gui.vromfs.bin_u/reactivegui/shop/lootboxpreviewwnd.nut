from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxName, getLootboxPreviewBg
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg, headerMargin, headerHeightInSafeArea
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageVerySmall
from "%rGui/navState.nut" import registerScene, setSceneBg, setSceneBgFallback
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_TINY_SMALL_GAP, REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM
from "%rGui/shop/lootboxPreviewContent.nut" import getLootboxRewardsAutoLast, lootboxImageWithTimer, mkReward
from "%rGui/shop/lootboxPreviewState.nut" import previewLootbox, isLootboxPreviewOpen, closeLootboxPreview
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const infoBlockWidth = hdpx(500)
let rewardsMaxWidth = saSize[0] - infoBlockWidth - headerMargin
let rewardsMaxHeight = saSize[1] - headerHeightInSafeArea - headerMargin
let rewardsGradientSize = [headerMargin, saBorders[1]]

let infoFont = fontSmallShaded
let infoTextHeight = calc_str_box("A", infoFont)[1]

const defaultBgImage = "ui/images/event_bg.avif"
let bgImage = keepref(Computed(@() getLootboxPreviewBg(previewLootbox.get()?.name) ?? { bg = defaultBgImage}))

let pannableArea = verticalPannableAreaCtor(rewardsMaxHeight + rewardsGradientSize[0] + rewardsGradientSize[1],
  rewardsGradientSize)
let scrollHandler = ScrollHandler()

let getSlotsInRow = @(style) 2 * max(1, (rewardsMaxWidth + style.boxGap).tointeger() / (style.boxSize + style.boxGap) / 2)

function calcRewardsHeight(rewards, slotsInRow, style) {
  if (rewards.len() == 0)
    return infoTextHeight
  let rows = ceil(rewards.reduce(@(res, r) res + r.slots, 0).tofloat() / slotsInRow).tointeger()
  return infoTextHeight + rows * (style.boxSize + style.boxGap)
}

let mkStyleComp = @(rewards) Computed(function() {
  foreach(style in [REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL]) {
    let slotsInRow = getSlotsInRow(style)
    let height = calcRewardsHeight(rewards.get(), slotsInRow, style)
    if (height <= rewardsMaxHeight)
      return style
  }
  return REWARD_STYLE_TINY_SMALL_GAP
})

let mkRewardsSizes = @(rewards, style) Computed(function() {
  let slotsInRow = getSlotsInRow(style.get())
  return {
    slotsInRow
    height = calcRewardsHeight(rewards.get(), slotsInRow, style.get())
    width = min(slotsInRow, rewards.get().reduce(@(res, r) res + r.slots, 0))
      * (style.get().boxSize + style.get().boxGap) - style.get().boxGap
  }
})

let wndHeader = headerGradientBg(
  [
    backButton(closeLootboxPreview)
    @() {
      watch = previewLootbox
      rendObj = ROBJ_TEXT
      color = 0xFFFFFFFF
      text = !previewLootbox.get()?.name ? ""
        : getLootboxName(previewLootbox.get()?.name)
    }.__update(fontBigShaded)
  ])

let infoText = {
  size = [SIZE_TO_CONTENT, infoTextHeight]
  rendObj = ROBJ_TEXT
  text = loc("events/lootboxContains")
}.__update(infoFont)

let mkRewardsBlock = @(rewards, style, sizes) function() {
  let { slotsInRow, width } = sizes.get()
  let { boxGap } = style.get()
  let rows = []
  local slotsLeft = 0
  foreach(r in rewards.get()) {
    if (r.slots > slotsLeft) {
      rows.append([])
      slotsLeft = slotsInRow
    }
    slotsLeft -= r.slots
    rows.top().append(mkReward(r, style.get()))
  }
  return {
    watch = [rewards, style, sizes]
    size = [width, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = boxGap
    children = rows.map(@(children) {
      flow = FLOW_HORIZONTAL
      gap = boxGap
      children
    })
      .insert(0, infoText)
  }
}

function lootboxPreviewContent(lootbox, ovr = {}) {
  if (lootbox == null)
    return { size = FLEX }.__update(ovr)
  let rewards = Computed(@() getLootboxRewardsAutoLast(lootbox, servProfile.get(), serverConfigs.get()))
  let style = mkStyleComp(rewards)
  let sizes = mkRewardsSizes(rewards, style)
  let needScroll = Computed(@() sizes.get().height > rewardsMaxHeight)
  let rewardsBlock = mkRewardsBlock(rewards, style, sizes)
  return @() {
    watch = needScroll
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    flow = FLOW_HORIZONTAL
    gap = headerMargin
    children = [
      @() {
        watch = needScroll
        size = [rewardsMaxWidth, rewardsMaxHeight]
        children = !needScroll.get() ? rewardsBlock
          : [
              pannableArea(
                rewardsBlock,
                {},
                { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
              mkScrollArrow(scrollHandler, MR_B, scrollArrowImageVerySmall,
                { vplace = ALIGN_CENTER, pos = [0, 0.5 * (rewardsMaxHeight + saBorders[1])] })
            ]
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          { size = FLEX }
          lootboxImageWithTimer(lootbox)
          { size = flex(2) }
        ]
      }
    ]
  }.__update(ovr)
}

let lootboxPreviewWnd = @() {
  key = isLootboxPreviewOpen
  watch = previewLootbox
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    lootboxPreviewContent(previewLootbox.get())
  ]
  animations = wndSwitchAnim
}

const sceneId = "lootboxPreviewWnd"
registerScene(sceneId, lootboxPreviewWnd, closeLootboxPreview, isLootboxPreviewOpen)
setSceneBgFallback(sceneId, defaultBgImage)
setSceneBg(sceneId, bgImage.get().bg, bgImage.get()?.bgColor)
bgImage.subscribe(@(v) setSceneBg(sceneId, v.bg, v?.bgColor))
