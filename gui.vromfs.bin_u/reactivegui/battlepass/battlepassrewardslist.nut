from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bpCardStyle, bpCardPadding, bpCardGap, bpCardFooterHeight, bpCardHeight, bpCardMargin
} = require("bpCardsStyle.nut")
let { mkRewardPlate, getRewardPlateSize } = require("%rGui/rewards/rewardPlateComp.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { receiveBpRewards, isBpRewardsInProgress, selectedStage } = require("battlePassState.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")

let rewardBoxSize = bpCardStyle.boxSize
let emptySlot = { size = array(2, rewardBoxSize) }
let receiveMarkIconSize = [hdpxi(100), hdpxi(100)]
let lockedMarkIconSize = [hdpxi(25), hdpxi(32)]

let bgCard = mkColoredGradientY(0xFFC59E49, 0xFFCA7119)

let function markAvailableReward(slot){
  let defaulScale = 1.25
  let widthScale = (defaulScale - 1) / slot
  return{
    key = {}
    size = flex()
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0, duration = 1.5, play = true,
        loop = true, easing = OutCubic }
      { prop = AnimProp.scale, from = [1, 1] to = [ 1 + widthScale, defaulScale], duration = 1.5, play = true,
        loop = true,  easing = OutCubic }
    ]
  }
}

let paidMark = {
  size = [flex(), hdpx(12)]
  rendObj = ROBJ_SOLID
  color = 0xFFFFDE70
}

let receivedMark = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x80000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    pos = [hdpx(12), -hdpx(10)]
    rendObj = ROBJ_IMAGE
    size = receiveMarkIconSize
    image = Picture($"ui/gameuiskin#daily_mark_claimed.avif:{receiveMarkIconSize[0]}:{receiveMarkIconSize[1]}:P")
  }
}

let lockedMark = {
  rendObj = ROBJ_IMAGE
  size = lockedMarkIconSize
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  image = Picture($"ui/gameuiskin#lock_icon.svg:{lockedMarkIconSize[0]}:{lockedMarkIconSize[1]}:P")
  margin = hdpx(10)
}

let canReceiveMark = mkSpinnerHideBlock(isBpRewardsInProgress,
  textButtonBattle(
    utf8ToUpper(loc("btn/receive")),
    null,
    {
      ovr = { size = flex(), minWidth = 0, behavior = null }
      childOvr = fontTiny
    }),
  { size = [flex(), bpCardFooterHeight], valign = ALIGN_CENTER, halign = ALIGN_CENTER })

let freeMark = {
  size = [flex(), bpCardFooterHeight]
  padding = [0, 0, 0.3 * bpCardFooterHeight, 0]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#bp_progress_icon.svg:{rewardBoxSize}:{bpCardFooterHeight}:P")
  color = 0xAA000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(loc("shop/free"))
  }.__update(fontVeryTinyAccented)
}

let function cardContent(stageInfo, stateFlags) {
  let { canReceive, viewInfo, isPaid, isReceived } = stageInfo
  return @() {
    watch = stateFlags
    padding = bpCardPadding
    flow = FLOW_VERTICAL
    gap = bpCardGap
    children = [
      {
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          canReceive ? markAvailableReward(viewInfo.slots) : null
          viewInfo != null ? mkRewardPlate(viewInfo, bpCardStyle) : emptySlot
          isReceived
            ? receivedMark
            : canReceive ? null : lockedMark
        ]
      }
      canReceive ? canReceiveMark
        : isPaid ? paidMark
        : freeMark
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }
}

let cardBorder = @(cardWidth, selStage, progress) @() {
  watch = selStage
  size = [cardWidth + 2 * bpCardMargin, bpCardHeight + 2 * bpCardMargin]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_BOX
  fillColor = 0
  borderWidth = bpCardMargin
  borderColor = progress == selStage.value ? 0xFFFFFFFF : 0
}

let hoverCard = @(stateFlags) @() {
  watch = stateFlags
  size = flex()
  rendObj = ROBJ_IMAGE
  image = stateFlags.value & S_HOVER
    ? Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
    : null
}

let function mkCard(stageInfo) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress } = stageInfo
  let function onClick(){
    selectedStage(progress)
    if(canReceive)
      receiveBpRewards(progress)
  }
  let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  return @(){
    watch = selectedStage
    size = [cardWidth, bpCardHeight]
    rendObj = ROBJ_IMAGE
    image = bgCard

    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    onClick
    xmbNode = {}
    sound = { click  = "click" }

    children = [
      hoverCard(stateFlags)
      cardBorder(cardWidth, selectedStage, progress)
      cardContent(stageInfo, stateFlags)
    ]
  }
}

let battlePassRewardsList = @(rewardsStages) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bpCardMargin
  children = rewardsStages.map(mkCard)
}

return battlePassRewardsList
