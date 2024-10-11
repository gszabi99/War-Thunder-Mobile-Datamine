from "%globalsDarg/darg_library.nut" import *
let { bgHeader } = require("%rGui/style/backgrounds.nut")
let { round } = require("math")
let { mkRewardPlateBg, mkRewardPlateImage, mkProgressLabel, mkProgressBar
} = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_MEDIUM,REWARD_STYLE_SMALL, getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkUnitFlag } = require("%rGui/unit/components/unitPlateComp.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")

let textColor = 0xFFE0E0E0
let rewIconSize = hdpxi(200)
let imgW = round(rewIconSize *  1.8).tointeger()
let imgH = round(imgW / 1.61).tointeger()

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

let mkUnitRow = @(reward) {
  pos = [hdpx(35), 0]
  size = [SIZE_TO_CONTENT, evenPx(160)]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    @() {
      watch = serverConfigs
      size = getRewardPlateSize(reward.slots, REWARD_STYLE_MEDIUM)
      children = [
        mkRewardPlateBg(reward, REWARD_STYLE_MEDIUM)
        mkRewardPlateImage(reward, REWARD_STYLE_MEDIUM)
        {
          size = flex()
          valign = ALIGN_BOTTOM
          children = [
            mkProgressBar(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount ?? 1)
            mkProgressLabel(reward.count, serverConfigs.get()?.allBlueprints[reward.id].targetCount, REWARD_STYLE_SMALL)
          ]
        }
        mkUnitFlag(serverConfigs.value?.allUnits?[reward.id], REWARD_STYLE_MEDIUM)
      ]
    }
    {
      rendObj = ROBJ_IMAGE
      size = [hdpx(100), hdpx(70)]
      image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
    }
    {
      rendObj = ROBJ_IMAGE
      size = [imgW, imgH]
      image = Picture($"ui/gameuiskin#shop_eagles_02.avif:{imgW}:{imgH}:P")
      valign = ALIGN_TOP
      halign = ALIGN_RIGHT
      children = {
        pos = [hdpx(-80), hdpx(30)]
        rendObj = ROBJ_TEXT
        text = reward.subId
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

function mkMsgConvertBlueprint(stackDataV, onClick) {
  let mainRArray = {}
  local sum = 0
  foreach(info in (stackDataV ?? [])){
    sum = sum + info.from.count
    mainRArray[info.from.id] <-{
      id = info.from.id
      subId = info.from.count
      rType = info.from.gType
      count = (serverConfigs.get()?.allBlueprints[info.from.id].targetCount ?? 1) + info.from.count
      slots = 2
    }
  }
  let cont = {
    flow = FLOW_VERTICAL
    gap = hdpx(35)
    children = mainRArray.map(@(r) mkUnitRow(r)).values()
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
          {
            padding = [hdpx(10), 0]
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
          {
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
  mkMsgConvertBlueprint
}