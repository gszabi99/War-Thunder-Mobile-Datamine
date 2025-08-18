from "%globalsDarg/darg_library.nut" import *

let { lootboxesCfg, isOpened, selectedLootbox, allRewards } = require("%rGui/debugTools/debugLootboxState.nut")
let { mkRewardPlate, REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardPlateComp.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let chooseByNameWnd = require("%rGui/debugTools/debugSkins/chooseByNameWnd.nut")
let { registerScene } = require("%rGui/navState.nut")

let close = @() isOpened.set(false)

let opacityGradientSize = saBorders[1]
let wndHeaderHeight = hdpx(60)
let wndContentWidth = saSize[0]
let wndContentHeight = saSize[1] - wndHeaderHeight + opacityGradientSize
let wndBackgroundColor = 0xFF5c5e73

let wndHeader = @(children) {
  size = const [flex(), hdpx(60)]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(15)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      text = "Debug lootbox rewards"
    }.__update(fontBig)
  ].extend(children)
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight, [opacityGradientSize, opacityGradientSize])
let mkWndContent = @(rewards, rStyle) pannableArea({
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = wrap(rewards.map(@(r) mkRewardPlate(r, rStyle)),
    { flow = FLOW_HORIZONTAL, width = wndContentWidth, hGap = rStyle.boxGap, vGap = rStyle.boxGap })
})

let mkSelector = @(curValue, allValues, setValue, mkLoc, mkValues, title = "") @() {
  watch = curValue
  children = textButtonPrimary(mkLoc(curValue.get()),
    @(event) chooseByNameWnd(event.targetRect,
      title
      mkValues(allValues?.get() ?? allValues, mkLoc),
      curValue.get(),
      setValue))
}

function mkDebugRewardPlateCompWnd() {
  let allLootboxes = lootboxesCfg.get().keys().sort()
  let curLootbox = Computed(@() allLootboxes.contains(selectedLootbox.get()) ? selectedLootbox.get() : allLootboxes?[0])

  if (selectedLootbox.get() == null)
    selectedLootbox.set(curLootbox.get())

  return {
    watch = [lootboxesCfg, allRewards]
    key = isOpened
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    rendObj = ROBJ_SOLID
    color = wndBackgroundColor
    children = [
      wndHeader([mkSelector(curLootbox,
        allLootboxes,
        @(value) selectedLootbox.set(value),
        @(name) loc($"lootbox/{name}"),
        @(allValues, mkLoc) allValues.map(@(value) { text = mkLoc(value), value }),
        "Select lootbox")])
      mkWndContent(allRewards.get(), REWARD_STYLE_MEDIUM)
    ]
    animations = wndSwitchAnim
  }
}

registerScene("debugLootboxRewardsWnd", mkDebugRewardPlateCompWnd, close, isOpened)
