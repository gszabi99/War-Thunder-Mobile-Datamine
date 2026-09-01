from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/passPresentation.nut" import getNewbieBPPresentation
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin
import "%rGui/battlePass/bpProgressBarSimple.nut" as bpProgressBarSimple
from "%rGui/battlePass/newPlayerBpState.nut" import mkNPPaidStageList, mkNPFreeStageList, winsCount, closeNPWnd,
  isNPWndOpened, selectedStage, receiveNPRewards, isNPRewardsInProgress, isNPActive, npPassGoods, nbpSeasonEndTime,
  sendNpBqEvent
from "%rGui/battlePass/passRewardsListComp.nut" import bgCard, hoverCard, cardBorder, cardContent
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPricePurchase
from "%rGui/mainMenu/toBattleButton.nut" import toBattleButtonForRandomBattles
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/rewards/rewardPlateComp.nut" import getRewardPlateSize, mkRewardPlate, REWARD_STYLE_MEDIUM
from "%rGui/shop/platformGoods.nut" import buyPlatformGoods, platformPurchaseInProgress
from "%rGui/shop/purchaseGoods.nut" import purchaseGoods
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate


const fontIconPreview = "⌡"
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
      watch = [serverTime, nbpSeasonEndTime]
      rendObj = ROBJ_TEXT
      text = !nbpSeasonEndTime.get() || (nbpSeasonEndTime.get() - serverTime.get() < 0)
        ? loc("lb/seasonFinished")
        : loc("battlepass/endsin", { time = secondsToHoursLoc(nbpSeasonEndTime.get() - serverTime.get())})
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
          size = const [hdpx(280), hdpx(100)]
          minWidth = hdpx(280)
        }
      }
    ),
    { size = [FLEX, defButtonHeight], vplace = ALIGN_BOTTOM, halign = ALIGN_CENTER, valign = ALIGN_CENTER })
}

let passCard = @() {
  watch = [isNPActive, npPassGoods, curCampaign]
  size = passCardSize
  rendObj = ROBJ_IMAGE
  image = !isNPActive.get()
    ? Picture($"ui/images/newbie_pass_{curCampaign.get()}_bg.avif:{passCardSize[0]}:{passCardSize[1]}:P")
    : Picture($"ui/images/newbie_pass_{curCampaign.get()}_bg_vip.avif:{passCardSize[0]}:{passCardSize[1]}:P")
  padding = hdpx(10)
  children = [
    {
      size = const [hdpx(280), hdpx(100)]
      rendObj = ROBJ_SOLID
      color = 0x90000000
      hplace = ALIGN_CENTER
      vplace = ALIGN_TOP
      children = {
        size = FLEX
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = loc("totalWins")
      }.__update(fontMedium)
    }
    {
      size = const [hdpx(100), hdpx(100)]
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

let previewComp = @(viewInfo) viewInfo?.rType != "unit" ? null : {
  size = const [hdpx(80), hdpx(80)]
  margin = hdpx(10)
  rendObj = ROBJ_SOLID
  behavior = Behaviors.Button
  function onClick() {
    closeMsgBox("npRewardInfo")
    openUnitDetailsWnd({ name = viewInfo.id })
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
  if (viewInfo?.rType != "unit")
    return
  openMsgBox({
    uid = "npRewardInfo"
    text = {
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(25)
      children = [
        {
          rendObj = ROBJ_TEXT
          text = getUnitName(viewInfo.id)
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
  size = FLEX
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

const sceneId = "newPlayerBpScene"
registerScene(sceneId, wnd, closeNPWnd, isNPWndOpened)
setSceneBg(sceneId, getNewbieBPPresentation(curCampaign.get()).bg)
curCampaign.subscribe(@(v) setSceneBg(sceneId, getNewbieBPPresentation(v).bg))
registerUnlocksSceneToUpdate(sceneId)
