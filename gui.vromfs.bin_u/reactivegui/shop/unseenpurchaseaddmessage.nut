from "%globalsDarg/darg_library.nut" import *
let { modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { G_CURRENCY, G_BLUEPRINT, G_UNIT } = require("%appGlobals/rewardType.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar, mkRewardTextLabel, mkRewardPlateTexts,
  mkRewardPlate, mkRewardUnitFlag
} = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_MEDIUM, REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardStyles.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")

let textColor = 0xFFE0E0E0

let padding = hdpx(50)
let minWidthWnd = hdpx(900)


let mkTapToContinueText = @() {
  rendObj = ROBJ_TEXT
  color = textColor
  text = loc("TapAnyToContinue")
  vplace = ALIGN_BOTTOM
}.__update(fontSmall)

let exceedBlueprintsProgress = @(count, targetCount) {
  size = flex()
  valign = ALIGN_BOTTOM
  children = [
    mkProgressBar(targetCount + count, targetCount)
    mkProgressLabel(targetCount + count, targetCount, REWARD_STYLE_SMALL)
  ]
}

let fromCtor = {
  [G_BLUEPRINT] = @(reward) @() {
    watch = serverConfigs
    children = [
      mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
      reward.count >= 0
        ? exceedBlueprintsProgress(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount ?? 1)
        : mkRewardTextLabel(-reward.count, REWARD_STYLE_SMALL)
      mkRewardUnitFlag(serverConfigs.value?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  },

  [G_CURRENCY] = @(reward) mkRewardPlate(reward, REWARD_STYLE_MEDIUM),

  [G_UNIT] = @(reward) @() {
    watch = serverConfigs
    children = [
      mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateTexts(reward, REWARD_STYLE_MEDIUM)
      mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  },
}

let mkConvertRow = @(reward, toReward) @() {
  watch = serverConfigs
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = fromCtor?[reward?.rType](reward)
    }
    {
      rendObj = ROBJ_IMAGE
      size = [hdpx(100), hdpx(70)]
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = mkRewardPlate(toReward, REWARD_STYLE_MEDIUM)
    }
  ]
}


let mkVerticalPannableArea = verticalPannableAreaCtor(hdpx(400), [hdpx(10), hdpx(90)])
let scrollHandler = ScrollHandler()

let scrollArrowsBlock = {
  size = [SIZE_TO_CONTENT, hdpx(400)]
  hplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
}

function mkMsgConvert(stackDataV, onClick) {
  let mainRArray = {}
  local sum = 0
  local isOnlyBlueprints = true
  foreach(info in stackDataV) {
    sum = sum + info.to.count
    isOnlyBlueprints = isOnlyBlueprints && info.from.gType == G_BLUEPRINT
    local amount = info.from.count
    mainRArray[info.from.id] <- {
      reward = getRewardsViewInfo([{
        id = info.from.id
        gType = info.from.gType
        count = amount >= 0 ? amount : -amount
        subId = info.from.subId
      }])[0],
      toReward = getRewardsViewInfo([{
        id = info.to.id
        gType = info.to.gType
        count = info.to.count
        subId = info.to.subId
      }])[0]
    }
  }
  let cont = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(35)
    children = mainRArray.map(@(data) mkConvertRow(data.reward, data.toReward)).values()
  }
  return {
    minWidth = minWidthWnd
    padding = [0,0, padding, 0]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    flow = FLOW_VERTICAL
    children = [
      modalWndHeader(loc("mainmenu/convert"))
      {
        flow = FLOW_VERTICAL
        padding = padding
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
              size = [minWidthWnd, SIZE_TO_CONTENT]
              children = mainRArray.len() > 2 ? [
                mkVerticalPannableArea(
                  cont,
                  {},
                  { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                scrollArrowsBlock
              ] : cont
          }
          stackDataV.len() <= 1 ? null
            : {
                padding = [hdpx(40), 0]
                flow = FLOW_HORIZONTAL
                gap = hdpx(10)
                halign = ALIGN_CENTER
                children = [
                  {
                    rendObj = ROBJ_TEXT
                    text = loc("debriefing/total")
                  }.__update(fontSmall)
                  mkCurrencyComp(sum, "gold")
                ]
              }
          !isOnlyBlueprints ? null
            : {
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                halign = ALIGN_CENTER
                maxWidth = hdpx(600)
                text = "\n".concat(loc("mainmenu/convertReward/desc"), loc("mainmenu/convertCourse"))
                hplace = ALIGN_CENTER
              }.__update(fontSmall)
        ]
      }
      mkTapToContinueText()
    ]
  }
}

return {
  mkMsgConvert
}