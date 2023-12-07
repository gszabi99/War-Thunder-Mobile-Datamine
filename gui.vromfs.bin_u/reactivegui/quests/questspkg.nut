from "%globalsDarg/darg_library.nut" import *
let { txt, tagRedColor, mkBgImg } = require("%rGui/shop/goodsView/sharedParts.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { onSectionChange, curSectionId, hasUnseenQuestsBySection, sectionsCfg,
  onWatchQuestAd, SPEED_UP_AD_COST } = require("questsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkLockedIcon, progressBarRewardSize } = require("rewardsComps.nut")
let { eventSeason, openEventWnd } = require("%rGui/event/eventState.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { mkLoootboxImage } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { sendBqQuestsSpeedUp } = require("bqQuests.nut")


let SECTION_OPACITY = 0.3
let bgGradColor = 0x990C1113
let gradColor = 0xFF52C4E4
let newMarkH = hdpxi(50)
let newMarkTexOffs = [0, newMarkH / 2, 0, newMarkH / 10]
let sectionBtnHeight = hdpx(70)
let sectionBtnMaxWidth = hdpx(400)
let lockedOpacity = 0.5
let sectionBtnGap = hdpx(10)
let lootboxSize = hdpx(130)
let linkToEventWidth = hdpx(240)
let iconSize = CS_INCREASED_ICON.iconSize
let btnSize = [isWidescreen ? hdpx(300) : hdpx(230), hdpx(90)]
let childOvr = isWidescreen ? {} : fontSmallShaded
let btnStyle = { ovr = { size = btnSize, minWidth = 0 }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, maxWidth = btnSize[0], sound = { click  = "meta_get_unlock" } }, childOvr }
let btnGap = hdpx(20)

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

let mkSectionBtn = @(id, width = sectionBtnMaxWidth, font = fontSmallShaded, isLocked = false) {
  size = [width, sectionBtnHeight]
  behavior = Behaviors.Button
  onClick = @() onSectionChange(id)
  clickableInfo = loc("mainmenu/btnSelect")
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgGradColor
    }

    @() {
      watch = curSectionId
      size = flex()
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = gradColor
      opacity = curSectionId.value == id ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = SECTION_OPACITY, easing = InOutQuad }]
    }

    {
      size = [width - sectionBtnGap, flex()]
      flow = FLOW_HORIZONTAL
      gap = sectionBtnGap
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        isLocked ? mkLockedIcon({ opacity = lockedOpacity }) : null
        @() {
          watch = sectionsCfg
          rendObj = ROBJ_TEXT
          opacity = isLocked ? lockedOpacity : 1.0
          text = sectionsCfg.value?[id].text
        }.__update(font)
      ]
    }

    @() {
      watch = [hasUnseenQuestsBySection, curSectionId]
      hplace = ALIGN_RIGHT
      margin = sectionBtnGap / 2
      children = hasUnseenQuestsBySection.value?[id] && id != curSectionId.value ? priorityUnseenMark : null
    }
  ]
}

let mkTimeUntil = @(time, locId = "quests/untilTheEnd", ovr = {}) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_TEXT
  text = loc(locId, { time })
}.__update(fontSmall, ovr)

let allQuestsCompleted = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("quests/allCompleted")
}.__update(fontMedium)

let function linkToEventBtn() {
  let stateFlags = Watched(0)
  let bigLootbox = Computed(@() eventLootboxes.value?[eventLootboxes.value.len() - 1].name)

  return @() {
    watch = [eventSeason, bigLootbox, stateFlags]
    size = [linkToEventWidth, progressBarRewardSize]
    behavior = Behaviors.Button
    onClick = openEventWnd
    clickableInfo = loc("item/open")
    onElemState = @(sf) stateFlags(sf)
    children = [
      mkBgImg($"ui/gameuiskin#banner_event_{eventSeason.value}.avif:0:P", "ui/gameuiskin#offer_bg_blue.avif:0:P")
      mkLoootboxImage(bigLootbox.value, lootboxSize, {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
      })
      {
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_TEXT
        padding = hdpx(10)
        text = utf8ToUpper(loc("mainmenu/rewardsList"))
      }.__update(fontTinyAccentedShaded)
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }
}

let function mkAdsBtn(unlock) {
  let hasAdBudget = Computed(@() adBudget.value > SPEED_UP_AD_COST)
  let function onClick() {
    if (onWatchQuestAd(unlock))
      sendBqQuestsSpeedUp(unlock)
  }

  return @() {
    watch = [hasAdBudget, canShowAds]
    children = mkCustomButton(
      {
        size = flex()
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = btnGap
        children = [
          !hasAdBudget.value ? null : {
            size = [iconSize, iconSize]
            rendObj = ROBJ_IMAGE
            keepAspect = KEEP_ASPECT_FILL
            image = Picture($"ui/gameuiskin#mp_spectator.avif:{iconSize}:{iconSize}:P")
          }
          {
            maxWidth = hasAdBudget.value ? (btnSize[0] - iconSize - btnGap) : btnSize[0]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            halign = ALIGN_CENTER
            text = utf8ToUpper(hasAdBudget.value ? loc("quests/addProgress") : loc("playBattles", { count = SPEED_UP_AD_COST }))
          }.__update(fontTinyAccentedShaded)
        ]
      },
      onClick,
      mergeStyles(canShowAds.value && hasAdBudget.value ? buttonStyles.SECONDARY : buttonStyles.COMMON , btnStyleSound)
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
  linkToEventBtn

  btnSize
  btnStyle
  btnStyleSound
  mkAdsBtn
}