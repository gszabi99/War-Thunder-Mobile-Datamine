from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getUnitName } = require("%appGlobals/unitPresentation.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { getNewbieBPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkNPPaidStageList, mkNPFreeStageList, winsCount, closeNPWnd, isNPWndOpened, curStatsCampaign,
selectedStage, receiveNPRewards, isNPRewardsInProgress, isNPActive, npPassGoods, seasonEndTime, sendNpBqEvent
} = require("%rGui/battlePass/newPlayerBpState.nut")
let { getRewardPlateSize, mkRewardPlate, REWARD_STYLE_MEDIUM  } = require("%rGui/rewards/rewardPlateComp.nut")
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin} = require("%rGui/battlePass/bpCardsStyle.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { bgCard, hoverCard, cardBorder, cardContent } = require("%rGui/battlePass/passRewardsListComp.nut")
let bpProgressBarSimple = require("%rGui/battlePass/bpProgressBarSimple.nut")
let { textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { purchaseGoods } = require("%rGui/shop/purchaseGoods.nut")
let { toBattleButtonForRandomBattles } = require("%rGui/mainMenu/toBattleButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { buyPlatformGoods, platformPurchaseInProgress } = require("%rGui/shop/platformGoods.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")


let fontIconPreview = "⌡"
let bgCardGray = mkColoredGradientY(0xFFB4B4B4, 0xFF767676)

let passCardSize = [hdpx(300), bpCardHeight*2 + hdpx(20)]

let mkText = @(text, ovr) {
  rendObj = ROBJ_TEXT
  halign = ALIGN_CENTER
  text = text
}.__update(ovr)

let header = {
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    mkText(utf8ToUpper(loc("newPlayerPass/header")), fontMedium)
    mkText(loc("newPlayerPass/headerDescription"), fontTinyAccented)
    @() {
      watch = [serverTime, seasonEndTime]
      rendObj = ROBJ_TEXT
      text = !seasonEndTime.get() || (seasonEndTime.get() - serverTime.get() < 0)
        ? loc("lb/seasonFinished")
        : loc("battlepass/endsin", { time = secondsToHoursLoc(seasonEndTime.get() - serverTime.get())})
    }.__update(fontVeryTiny)
  ]
}

function buyButton(goods) {
  if (goods == null)
    return null
  let { id, priceExt } = goods
  let { price, currencyId } = goods.price

  let priceComp = price != 0
    ? mkCurrencyComp(price, currencyId)
    : {
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = priceExt?.priceText
      }.__update(fontMediumShaded)
  return mkSpinnerHideBlock(
    price > 0 ? shopPurchaseInProgress : platformPurchaseInProgress,
    textButtonPricePurchase(utf8ToUpper(loc("mainmenu/btnBuy")),
      priceComp,
      function() {
        sendNpBqEvent("purchase_newbie_pass_press")
        if(price > 0 && currencyId != "")
          purchaseGoods(id)
        else
          buyPlatformGoods(id)
      }
      {
        hotkeys = ["^J:X"]
        ovr = {
          size = [hdpx(280), hdpx(100)]
          minWidth = hdpx(280)
        }
      }
    ),
    { size = [flex(), defButtonHeight], vplace = ALIGN_BOTTOM, halign = ALIGN_CENTER, valign = ALIGN_CENTER })
}

let passCard = @() {
  watch = [isNPActive, npPassGoods, curStatsCampaign]
  size = passCardSize
  rendObj = ROBJ_IMAGE
  image = !isNPActive.get()
    ? Picture($"ui/images/newbie_pass_{curStatsCampaign.get()}_bg.avif:{passCardSize[0]}:{passCardSize[1]}:P")
    : Picture($"ui/images/newbie_pass_{curStatsCampaign.get()}_bg_vip.avif:{passCardSize[0]}:{passCardSize[1]}:P")
  padding = hdpx(10)
  children = [
    {
      size = [hdpx(280), hdpx(100)]
      rendObj = ROBJ_SOLID
      color = 0x90000000
      hplace = ALIGN_CENTER
      vplace = ALIGN_TOP
      children = {
        size = flex()
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = loc("totalWins")
      }.__update(fontMedium)
    }
    {
      size = [hdpx(100), hdpx(100)]
      rendObj = ROBJ_IMAGE
      color = 0x90000000
      image = Picture($"ui/gameuiskin#bp_progress_icon.svg:{hdpx(100)}:{hdpx(100)}:P")
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = @() {
        watch = winsCount
        rendObj = ROBJ_TEXT
        text = winsCount.get()
        color = 0xFFFFFFFF
      }.__update(fontMedium)
    }
    !isNPActive.get() ? buyButton(npPassGoods.get()) : null
  ]
}

let previewComp = @(viewInfo) viewInfo.rType != "unit" ? null : {
  size = [hdpx(80), hdpx(80)]
  margin = hdpx(10)
  rendObj = ROBJ_SOLID
  behavior = Behaviors.Button
  function onClick() {
    closeMsgBox("npRewardInfo")
    unitDetailsWnd({ name = viewInfo.id })
  }
  color = 0x80000000
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = fontIconPreview
  }.__update(fontMedium)
}

function rewardInfoMsg(reward) {
  let viewInfo = reward.viewInfo
  if (viewInfo.rType != "unit")
    return
  openMsgBox({
    uid = "npRewardInfo"
    text = {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(25)
      children = [
        {
          rendObj = ROBJ_TEXT
          text = getUnitName(getTagsUnitName(viewInfo.id), loc)
        }.__update(fontTinyAccented)

        mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM)

        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          maxWidth = hdpx(600)
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          text = loc("newPlayerPass/rDesc")
        }.__update(fontTinyAccented)
      ]
    }
    buttons = [{ id = "ok", styleId = "PRIMARY", isDefault = true }]
  })
}


function mkCard(stageInfo, cardW = null, image = bgCard) {
  let stateFlags = Watched(0)
  let { canReceive, progress } = stageInfo
  return {
    size = [cardW, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    vplace = ALIGN_TOP
    children = [
      {
        size = [cardW, bpCardHeight]
        rendObj = ROBJ_IMAGE
        image
        onElemState = @(v) stateFlags.set(v)

        behavior = Behaviors.Button
        function onClick() {
          selectedStage.set(progress)
          if (canReceive)
            receiveNPRewards(progress)
          else if (!isNPActive.get())
            rewardInfoMsg(stageInfo)
        }
        xmbNode = {}
        sound = { click  = "click" }
        halign = ALIGN_CENTER

        children = [
          hoverCard(stateFlags)
          cardBorder(cardW, selectedStage, progress)
          cardContent(stageInfo, stateFlags, isNPRewardsInProgress, previewComp(stageInfo.viewInfo))
          canReceive ? null
            : {
                size = [cardW, bpCardHeight]
                rendObj = ROBJ_SOLID
                color = 0x40000000
              }
        ]
      }
    ]
  }
}

let operationPassRewardsListRows = @(rewardsStages, rewardsStages2, commonCardBg) {
  key = rewardsStages
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bpCardMargin
  children = rewardsStages.map(function(v, idx) {
    let rSlots2 = rewardsStages2[idx].viewInfo?.slots ?? 1
    let cardWidth = (getRewardPlateSize(max(rSlots2, v.viewInfo?.slots ?? 1) ?? 1, bpCardStyle)[0]) + 2 * bpCardPadding[1]
    return mkCard(v, cardWidth, commonCardBg)
  })
}

let rewardsList = @() {
  watch = [mkNPPaidStageList, mkNPFreeStageList]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    bpProgressBarSimple(mkNPFreeStageList.get(), winsCount, mkNPPaidStageList.get())
    operationPassRewardsListRows(mkNPFreeStageList.get(), mkNPPaidStageList.get(), bgCardGray)
    operationPassRewardsListRows(mkNPPaidStageList.get(), mkNPFreeStageList.get(), bgCard)
  ]
}

let wnd = bgShaded.__merge({
  size = flex()
  padding = saBordersRv
  gap = hdpx(20)
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        backButton(closeNPWnd)
        header
      ]
    }
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
      gap = hdpx(20)
      children = [
        passCard
        rewardsList
      ]
    }
    {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = toBattleButtonForRandomBattles
    }
  ]
})

let sceneId = "newPlayerBpScene"
registerScene(sceneId, wnd, closeNPWnd, isNPWndOpened)
setSceneBg(sceneId, getNewbieBPPresentation(curStatsCampaign.get()).bg)
curStatsCampaign.subscribe(@(v) setSceneBg(sceneId, getNewbieBPPresentation(v).bg))
