from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%rGui/globals/fontUtils.nut" import getFontToFitWidth
import "%rGui/ads/adBudget.nut" as adBudget
from "%rGui/ads/adsState.nut" import adsButtonCounter, isProviderInited
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/currencyComp.nut" import CS_INCREASED_ICON
from "%rGui/components/glare.nut" import mkGlare
from "%rGui/components/selectedLine.nut" import opacityTransition
from "%rGui/components/textButton.nut" import mkCustomButton, mergeStyles
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/quests/bqQuests.nut" import sendBqQuestsSpeedUp
from "%rGui/quests/questsState.nut" import onWatchQuestAd, SPEED_UP_AD_COST, getStarsTotalNonUpdatable
from "%rGui/quests/rewardsComps.nut" import progressBarRewardSize
from "%rGui/state/profilePremium.nut" import hasVip
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdColors.nut" import selectColor, tabBgColor
from "%rGui/textFormatByLang.nut" import decimalFormat
from "%rGui/unlocks/unlocks.nut" import unlockProgress


const sectionBtnHeight = hdpx(70)
const sectionBtnMaxWidth = hdpx(400)
const sectionBtnGap = hdpx(10)
const linkToEventWidth = hdpx(240)
const linkToEventIconSize = hdpxi(74)
let iconSize = CS_INCREASED_ICON.iconSize
let btnSize = [isWidescreen ? hdpx(300) : hdpx(230), hdpx(90)]
let childOvr = isWidescreen ? {} : fontBoldTinyAccentedShaded
let btnStyle = { ovr = { size = btnSize, minWidth = 0, padding = const [0, hdpx(2)] }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, maxWidth = btnSize[0], sound = { click  = "meta_get_unlock" } }, childOvr }
const btnGap = hdpx(10)
let vipIconW = CS_INCREASED_ICON.iconSize
let vipIconH = (CS_INCREASED_ICON.iconSize / 1.3).tointeger()
const imageInProgress = "ui/unitskin#image_in_progress.avif"

let btnGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(selectColor, 0, 35, 20, 30, -35))

let mkSectionBtn = @(onClick, isSelected, hasUnseen, content) {
  size = const [FLEX, sectionBtnHeight]
  behavior = Behaviors.Button
  onClick
  sound = { click = "choose" }
  clickableInfo = loc("mainmenu/btnSelect")
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = tabBgColor
    }

    @() {
      watch = isSelected
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = btnGradient()
      flipY = true
      keepAspect = KEEP_ASPECT_FILL
      opacity = isSelected.get() ? 1 : 0
      transitions = opacityTransition
    }

    {
      size = FLEX
      margin = const [0, sectionBtnGap / 2]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = content
    }

    @() {
      watch = [hasUnseen, isSelected]
      hplace = ALIGN_RIGHT
      margin = sectionBtnGap / 2
      children = !isSelected.get() && hasUnseen.get() ? priorityUnseenMark : null
    }
  ]
}

let mkTimeUntil = @(time, locId = "quests/untilTheEnd", ovr = {}) {
  rendObj = ROBJ_TEXT
  text = loc(locId, { time })
}.__update(fontSmall, ovr)

let allQuestsCompleted = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("quests/allCompleted")
}.__update(fontMedium)

function mkQuestsHeaderBtn(text, iconWatch, onClick, addChild = null, imageSizeMul = 1) {
  let stateFlags = Watched(0)
  let headerIconH = (linkToEventIconSize * imageSizeMul).tointeger()
  let headerIconW = 2 * headerIconH
  return @() {
    watch = stateFlags
    size = [linkToEventWidth, progressBarRewardSize]
    padding = hdpx(2)
    rendObj = ROBJ_BOX
    fillColor = tabBgColor
    borderWidth = hdpx(2)
    behavior = Behaviors.Button
    onClick
    clickableInfo = loc("item/open")
    onElemState = @(sf) stateFlags.set(sf)
    clipChildren = true
    children = [
      {
        key = "quest_header_btn" 
        size = FLEX
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
          @() {
            minHeight = progressBarRewardSize
            children = @() {
              margin = const [hdpx(5), 0, 0, 0]
              watch = iconWatch
              size = [headerIconW, headerIconH]
              rendObj = ROBJ_IMAGE
              image = Picture($"{iconWatch.get() ?? imageInProgress}:{headerIconW}:{headerIconH}:P")
              keepAspect = KEEP_ASPECT_FIT
            }
          }
          {
            rendObj = ROBJ_TEXT
            text = utf8ToUpper(text)
          }.__update(fontTinyAccented)
        ]
      }
      mkGlare(linkToEventWidth)
      addChild
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }
}

function mkAdsTxtBlock(isVip, hasAdBudget, budget, txtMaxWidth) {
  let txtBlock = {
    maxWidth = txtMaxWidth
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = utf8ToUpper(hasAdBudget
      ? loc(!isVip ? "quests/addProgress" : "quests/addProgress_budget", { num = budget })
      : loc("btn/adsLimitReached"))
  }.__update(fontBoldVeryTinyShaded, adsButtonCounter)

  return txtBlock.__update(getFontToFitWidth(txtBlock, txtMaxWidth, [fontBoldVeryVeryTinyAccentedShaded, fontBoldVeryTinyShaded]))
}

function mkAdsBtn(unlock) {
  let hasAdBudget = Computed(@() adBudget.get() >= SPEED_UP_AD_COST)
  function onClick() {
    if (onWatchQuestAd(unlock))
      sendBqQuestsSpeedUp(unlock, getStarsTotalNonUpdatable(unlock))
  }
  let txtMaxWidth = Computed(@() hasAdBudget.get() ? (btnSize[0] - iconSize - btnGap * 2) : btnSize[0])

  return @() {
    watch = [hasAdBudget, isProviderInited, adBudget, hasVip]
    children = mkCustomButton(
      {
        size = FLEX
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = btnGap
        children = [
          !hasAdBudget.get() ? null
            : {
                size = !hasVip.get() ? [iconSize, iconSize] : [vipIconW, vipIconH]
                rendObj = ROBJ_IMAGE
                keepAspect = true
                image = !hasVip.get()
                  ? Picture($"ui/gameuiskin#watch_ads.svg:{iconSize}:{iconSize}:P")
                  : Picture($"ui/gameuiskin#gamercard_subs_vip.avif:{vipIconW}:{vipIconH}:P")
              }
          @() {
            watch = [hasVip, hasAdBudget, adBudget, txtMaxWidth]
            children = mkAdsTxtBlock(hasVip.get(), hasAdBudget.get(), adBudget.get(), txtMaxWidth.get())
          }
        ]
      },
      onClick,
      mergeStyles((hasAdBudget.get() && isProviderInited.get()) ? buttonStyles.SECONDARY : buttonStyles.COMMON , btnStyleSound)
    )
  }
}

let lockIconSize = [hdpxi(35), hdpxi(45)]

let lockIcon = {
  size = lockIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#lock_icon.svg:{lockIconSize[0]}:{lockIconSize[1]}:P")
}

function mkQuestText(item, ovr = {}) {
  let { lang_id = item.name, isMastery = false, chain_quest = null } = item?.meta
  let header = loc(lang_id)
  let text = isMastery ? loc($"{lang_id}/desc", { amountTxt = decimalFormat(item.required), amount = item.required })
    : loc($"{lang_id}/desc")
  let isLocked = chain_quest
    && item?.type == "INDEPENDENT"
    && item.requirement != ""
    && !(unlockProgress.get()?[item.requirement].isCompleted ?? false)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      {
        rendObj = ROBJ_BOX
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          isLocked ? lockIcon : null
          {
            rendObj = ROBJ_TEXT
            behavior = Behaviors.Marquee
            speed = hdpx(30)
            delay = defMarqueeDelay
            maxWidth = pw(100)
            text = header
          }.__update(fontSmall)
        ]
      }

      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = pw(100)
        text
      }.__update(fontTiny)
    ]
  }.__update(ovr)
}

return {
  mkSectionBtn
  sectionBtnHeight
  sectionBtnMaxWidth
  sectionBtnGap
  mkTimeUntil
  allQuestsCompleted
  mkQuestsHeaderBtn
  linkToEventWidth

  btnSize
  btnStyle
  btnStyleSound
  mkAdsBtn
  mkQuestText
}