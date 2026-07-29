from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getLootboxName, getLootboxPreviewBg } = require("%appGlobals/config/lootboxPresentation.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { headerGradientBg } = require("%rGui/components/gradientDefComps.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageVerySmall } = require("%rGui/components/scrollArrows.nut")
let { registerScene, setSceneBg, setSceneBgFallback } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { previewLootbox, isLootboxPreviewOpen, closeLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")
let { getLootboxRewardsAutoLast, lootboxImageWithTimer, mkReward } = require("%rGui/shop/lootboxPreviewContent.nut")
let { REWARD_STYLE_TINY_SMALL_GAP, REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM
} = require("%rGui/rewards/rewardStyles.nut")


let gap = hdpx(15)
let rewardsMaxWidth = saSize[0] + (isWidescreen ? 0 : saBorders[0] / 2) 
let rewardsMaxHeight = hdpx(470)
let rewardsGradientSize = [gap, saBorders[1]]

let defaultBgImage = "ui/images/event_bg.avif"
let bgImage = keepref(Computed(@() getLootboxPreviewBg(previewLootbox.get()?.name) ?? { bg = defaultBgImage}))

let pannableArea = verticalPannableAreaCtor(rewardsMaxHeight + rewardsGradientSize[0] + rewardsGradientSize[1],
  rewardsGradientSize)
let scrollHandler = ScrollHandler()

let getSlotsInRow = @(style) 2 * max(1, (rewardsMaxWidth + style.boxGap).tointeger() / (style.boxSize + style.boxGap) / 2)

function calcRewardsHeight(rewards, slotsInRow, style) {
  if (rewards.len() == 0)
    return 0
  let rows = ceil(rewards.reduce(@(res, r) res + r.slots, 0).tofloat() / slotsInRow).tointeger()
  return rows * (style.boxSize + style.boxGap) - style.boxGap
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
  ],
  { margin = [0, 0, hdpx(30), 0] })

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
    flow = FLOW_VERTICAL
    gap = needScroll.get() ? gap : { size = FLEX }
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("events/lootboxContains")
      }.__update(fontSmallShaded)
      lootboxImageWithTimer(lootbox)
      !needScroll.get() ? rewardsBlock
        : @() {
            watch = sizes
            size = [sizes.get().width, rewardsMaxHeight]
            children = [
              pannableArea(
                rewardsBlock,
                {},
                { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
              mkScrollArrow(scrollHandler, MR_B, scrollArrowImageVerySmall,
                { vplace = ALIGN_CENTER, pos = [0, 0.5 * (rewardsMaxHeight + saBorders[1])] })
            ]
          }
      !needScroll.get() ? { size = [0, flex(2)] } : null
    ]
  }.__update(ovr)
}

let lootboxPreviewWnd = @() {
  key = isLootboxPreviewOpen
  watch = previewLootbox
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap
  children = [
    wndHeader
    lootboxPreviewContent(previewLootbox.get())
  ]
  animations = wndSwitchAnim
}

let sceneId = "lootboxPreviewWnd"
registerScene(sceneId, lootboxPreviewWnd, closeLootboxPreview, isLootboxPreviewOpen)
setSceneBgFallback(sceneId, defaultBgImage)
setSceneBg(sceneId, bgImage.get().bg, bgImage.get()?.bgColor)
bgImage.subscribe(@(v) setSceneBg(sceneId, v.bg, v?.bgColor))
