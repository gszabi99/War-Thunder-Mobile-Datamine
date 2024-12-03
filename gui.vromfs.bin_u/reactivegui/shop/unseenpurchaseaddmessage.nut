from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { G_CURRENCY, G_BLUEPRINT } = require("%appGlobals/rewardType.nut")
let { bgHeader } = require("%rGui/style/backgrounds.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar, mkRewardTextLabel
} = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_MEDIUM,REWARD_STYLE_SMALL, getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkUnitFlag } = require("%rGui/unit/components/unitPlateComp.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")

let textColor = 0xFFE0E0E0
let rewIconSize = hdpxi(200)
let blockW = round(rewIconSize *  1.8).tointeger()
let blockH = round(blockW / 1.61).tointeger()
let imgH = round(blockH * 0.8).tointeger()

let padding = hdpx(50)
let minWidthWnd = hdpx(900)


let mkTapToContinueText = @() {
  rendObj = ROBJ_TEXT
  color = textColor
  text = loc("TapAnyToContinue")
  vplace = ALIGN_BOTTOM
}.__update(fontSmall)


let wndTitle = bgHeader.__merge({
  size = [flex(), SIZE_TO_CONTENT]
  padding = hdpx(15)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    color = textColor
    rendObj = ROBJ_TEXT
    text = loc("mainmenu/convert")
  }.__update(fontBig)
})

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
    size = getRewardPlateSize(reward.slots, REWARD_STYLE_MEDIUM)
    children = [
      mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
      mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
      reward.count >= 0
        ? exceedBlueprintsProgress(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount ?? 1)
        : mkRewardTextLabel(-reward.count, REWARD_STYLE_SMALL)
      mkUnitFlag(serverConfigs.value?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
    ]
  },

  [G_CURRENCY] = function(reward) {
    let { id, count } = reward
    let amount = -count
    let imgCfg = getCurrencyGoodsPresentation(id)
    let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
    let cfg = imgCfg?[max(0, idxByAmount - 1)]
    return {
      size = [blockW, blockH]
      children = [
        {
          size = [blockW, imgH]
          vplace = ALIGN_BOTTOM
          rendObj = ROBJ_IMAGE
          image = !cfg?.img ? null : Picture($"ui/gameuiskin#{cfg.img}:{blockW}:{blockH}:P")
          keepAspect = true
          imageHalign = ALIGN_RIGHT
        }
        {
            pos = [hdpx(20), hdpx(30)]
          rendObj = ROBJ_TEXT
          text = amount
        }.__update(fontMediumShaded)
      ]
    }
  },
}

let mkConvertRow = @(reward) @() {
  watch = serverConfigs
  pos = [hdpx(35), 0]
  size = [SIZE_TO_CONTENT, evenPx(160)]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    fromCtor?[reward?.rType](reward)
    {
      rendObj = ROBJ_IMAGE
      size = [hdpx(100), hdpx(70)]
      image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
    }
    {
      rendObj = ROBJ_IMAGE
      size = [blockW, blockH]
      image = Picture($"ui/gameuiskin#shop_eagles_02.avif:{blockW}:{blockH}:P")
      valign = ALIGN_TOP
      halign = ALIGN_RIGHT
      children = {
        pos = [hdpx(-80), hdpx(30)]
        rendObj = ROBJ_TEXT
        text = reward.toCount
      }.__update(fontMedium)
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
    mainRArray[info.from.id] <- {
      id = info.from.id
      toCount = info.to.count
      rType = info.from.gType
      count = info.from.count
      slots = 2
    }
  }
  let cont = {
    flow = FLOW_VERTICAL
    gap = hdpx(35)
    children = mainRArray.map(@(r) mkConvertRow(r)).values()
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
      wndTitle
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