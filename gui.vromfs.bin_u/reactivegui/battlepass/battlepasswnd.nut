from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { register_command } = require("console")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isBattlePassWndOpened, openBattlePassWnd, closeBattlePassWnd, listStages,
  isActiveBP } = require("battlePassState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let btnOpenQuests = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonPurchase } = require("%rGui/components/textButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkRewardsPreview } = require("%rGui/quests/rewardsComps.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let battlePassSeason = require("battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText, bpLevelLabel } = require("battlePassPkg.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")

let bpIconSize = [hdpx(150), hdpx(130)]

let backBtn = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children =[
        backButton(closeBattlePassWnd, { hplace = ALIGN_LEFT })
        battlePassSeason
      ]
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      gap = hdpx(70)
      children = [
        mkCurrencyBalance(WP)
        mkCurrencyBalance(GOLD)
      ]
    }
  ]
}

let function mkCard(rewards){
  let rewardsPreview = Computed(function() {
    local res = []
    foreach (id, count in rewards) {
      let reward = serverConfigs.value.userstatRewards?[id]
      res.extend(getRewardsViewInfo(reward, count))
    }
    return res
  })

  return @(){
    watch = rewardsPreview
    flow = FLOW_VERTICAL
    size = [hdpx(100), SIZE_TO_CONTENT ]
    children = mkRewardsPreview(rewardsPreview.value, false)
  }
}

let progressLine = @(){
  watch = listStages
  gap = hdpx(50)
  flow = FLOW_HORIZONTAL
  children = listStages.value.map(@(stage) mkCard(stage.rewards))
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(265)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccented)

let leftMiddle = {
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  hplace = ALIGN_LEFT
  children = [
    bpLevelLabel
    {
      size = [hdpx(300), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        bpCurProgressbar
        bpProgressText
      ]
    }
    taskDesc
    btnOpenQuests
  ]
}

let rightMiddle = {
  size = [SIZE_TO_CONTENT, flex()]
  hplace = ALIGN_RIGHT
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(15)
      children =[
        @(){
          watch = isActiveBP
          size = bpIconSize
          rendObj = ROBJ_IMAGE
          image = isActiveBP.value
            ? Picture($"ui/gameuiskin#bp_icon_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
            : Picture($"ui/gameuiskin#bp_icon_not_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
          opacity = isActiveBP.value ? 1 : 0.5
        }
        @(){
          watch = isActiveBP
          rendObj = ROBJ_TEXT
          padding = [hdpx(20), 0]
          text = isActiveBP.value ? loc("battlepass/active") : null
        }.__update(fontTinyAccented)
      ]
    }
    {
      vplace = ALIGN_BOTTOM
      children = textButtonPurchase(loc("battlepass/buyBattlepass"), @() null)
    }
  ]
}

let middlePart = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    leftMiddle
    { size = flex() }
    rightMiddle
  ]
}

let bottomPart = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  gap = hdpx(15)
  flow = FLOW_VERTICAL
  children = [
    middlePart
    progressLine
  ]
}

let battlePassWnd = {
  key = {}
  size = flex()
  rendObj = ROBJ_IMAGE
  padding = saBordersRv
  image = Picture("ui/gameuiskin#offer_bg_blue.avif")
  gap = hdpx(10)
  children = [
    backBtn
    bottomPart
  ]
  animations = wndSwitchAnim
}

register_command(openBattlePassWnd, "ui.battle_pass_open")
register_command(closeBattlePassWnd, "ui.battle_pass_close")

registerScene("battlePassWnd", battlePassWnd, closeBattlePassWnd, isBattlePassWndOpened)