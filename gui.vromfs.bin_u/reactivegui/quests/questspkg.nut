from "%globalsDarg/darg_library.nut" import *
let { txt, tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { onWatchQuestAd, SPEED_UP_AD_COST } = require("questsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { progressBarRewardSize } = require("rewardsComps.nut")
let { CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { adsButtonCounter } = require("%rGui/ads/adsState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { sendBqQuestsSpeedUp } = require("bqQuests.nut")
let { mkGlare } = require("%rGui/components/glare.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")

let SECTION_OPACITY = 0.3
let bgGradColor = 0x990C1113
let gradColor = 0xFF52C4E4
let newMarkH = hdpxi(50)
let newMarkTexOffs = [0, newMarkH / 2, 0, newMarkH / 10]
let sectionBtnHeight = hdpx(70)
let sectionBtnMaxWidth = hdpx(400)
let sectionBtnGap = hdpx(10)
let linkToEventWidth = hdpx(240)
let linkToEventIconSize = hdpxi(74)
let iconSize = CS_INCREASED_ICON.iconSize
let headerLineGap = isWidescreen ? hdpx(20) : hdpx(8)
let btnSize = [isWidescreen ? hdpx(300) : hdpx(230), hdpx(90)]
let childOvr = isWidescreen ? {} : fontSmallShaded
let btnStyle = { ovr = { size = btnSize, minWidth = 0 }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, maxWidth = btnSize[0], sound = { click  = "meta_get_unlock" } }, childOvr }
let btnGap = hdpx(10)
let vipIconW = CS_INCREASED_ICON.iconSize
let vipIconH = (CS_INCREASED_ICON.iconSize / 1.3).tointeger()

let newMark = {
  size  = [SIZE_TO_CONTENT, newMarkH]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{newMarkH}:{newMarkH}:P")
  keepAspect = KEEP_ASPECT_NONE
  screenOffs = newMarkTexOffs
  texOffs = newMarkTexOffs
  color = tagRedColor
  padding = [0, hdpx(30), 0, hdpx(20)]
  children = txt({
    text = utf8ToUpper(loc("shop/item/new"))
    vplace = ALIGN_CENTER
  })
}

let mkSectionBtn = @(onClick, isSelected, hasUnseen, content) {
  size = [flex(), sectionBtnHeight]
  maxWidth = sectionBtnMaxWidth
  behavior = Behaviors.Button
  onClick
  sound = { click = "choose" }
  clickableInfo = loc("mainmenu/btnSelect")
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgGradColor
    }

    @() {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = gradColor
      opacity = isSelected.get() ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = SECTION_OPACITY, easing = InOutQuad }]
    }

    {
      size = flex()
      margin = [0, sectionBtnGap / 2]
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
  let headerIconSize = (linkToEventIconSize * imageSizeMul).tointeger()
  return @() {
    watch = stateFlags
    size = [linkToEventWidth, progressBarRewardSize]
    padding = hdpx(2)
    rendObj = ROBJ_BOX
    fillColor = bgGradColor
    borderWidth = hdpx(2)
    behavior = Behaviors.Button
    onClick
    clickableInfo = loc("item/open")
    onElemState = @(sf) stateFlags(sf)
    clipChildren = true
    children = [
      {
        key = "quest_header_btn" 
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
          @() {
            minHeight = progressBarRewardSize
            children = @() {
              margin = [hdpx(5), 0, 0, 0]
              watch = iconWatch
              size = [headerIconSize, headerIconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"{iconWatch.get()}:{headerIconSize}:{headerIconSize}:P")
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
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }
}

function mkAdsBtn(unlock) {
  let hasAdBudget = Computed(@() adBudget.value >= SPEED_UP_AD_COST)
  function onClick() {
    if (onWatchQuestAd(unlock))
      sendBqQuestsSpeedUp(unlock)
  }

  return @() {
    watch = hasAdBudget
    children = mkCustomButton(
      {
        size = flex()
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = btnGap
        children = [
          !hasAdBudget.value ? null : {
            size = !hasVip.get() ? [iconSize, iconSize] : [vipIconW, vipIconH]
            rendObj = ROBJ_IMAGE
            keepAspect = KEEP_ASPECT_FILL
            image = !hasVip.get()
              ? Picture($"ui/gameuiskin#watch_ads.svg:{iconSize}:{iconSize}:P")
              : Picture($"ui/gameuiskin#gamercard_subs_vip.svg:{vipIconW}:{vipIconH}:P")
          }
          {
            maxWidth = hasAdBudget.value ? (btnSize[0] - iconSize - btnGap) : btnSize[0]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            halign = ALIGN_CENTER
            text = utf8ToUpper(hasAdBudget.get()
              ? loc(!hasVip.get() ? "quests/addProgress" : "quests/addProgress_budget", { num = adBudget.get() })
              : loc("btn/adsLimitReached"))
          }.__update(fontVeryTinyAccentedShaded, adsButtonCounter)
        ]
      },
      onClick,
      mergeStyles(hasAdBudget.value ? buttonStyles.SECONDARY : buttonStyles.COMMON , btnStyleSound)
    )
  }
}

return {
  newMark
  mkSectionBtn
  sectionBtnHeight
  sectionBtnMaxWidth
  sectionBtnGap
  mkTimeUntil
  allQuestsCompleted
  mkQuestsHeaderBtn
  linkToEventWidth
  headerLineGap

  btnSize
  btnStyle
  btnStyleSound
  mkAdsBtn
}