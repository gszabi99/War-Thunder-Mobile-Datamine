from "%globalsDarg/darg_library.nut" import *
from "math" import min

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardStyles.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, wndHeaderHeight, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { mkSquareIconBtn } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkQuestBar } = require("%rGui/quests/questBar.nut")
let { mkRewardsPreview, getRewardsPreviewInfo, REWARDS_PREVIEW_SLOTS } = require("%rGui/quests/rewardsComps.nut")
let { mkQuestText } = require("%rGui/quests/questsPkg.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let WND_UID = "quest_chain_info_wnd"

let maxVisibleQuestChains = 6
let iconWidth = hdpxi(40)
let questIconGap = hdpx(10)
let chainIconBlockWidth = iconWidth * maxVisibleQuestChains + questIconGap * (maxVisibleQuestChains - 1)
let questChainIconSize = [iconWidth, hdpxi(45)]
let iconColor = 0xFFFF9C11
let rewardPlateFullWidth = REWARD_STYLE_SMALL.boxSize + REWARD_STYLE_SMALL.boxGap

let questChainIconCurrent = Picture($"ui/gameuiskin/quest_chain_icon_current.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconCompleted = Picture($"ui/gameuiskin/quest_chain_icon_completed.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconComing = Picture($"ui/gameuiskin/quest_chain_icon_coming.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")

let P_COMPLETED = 0x1
let P_CURRENT = 0x2
let P_PERIODIC = 0x4

let mkProgresImage = memoize(@(mask) {
  size = questChainIconSize
  rendObj = ROBJ_IMAGE
  image = mask & P_COMPLETED ? questChainIconCompleted
    : mask & P_CURRENT ? questChainIconCurrent
    : questChainIconComing
  color = mask & P_COMPLETED ? iconColor : 0xFFFFFFFF
  keepAspect = true

  children = !(mask & P_PERIODIC) ? null
    : {
        size = flex()
        pos = [0, -hdpx(3)]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = mask & P_COMPLETED ? 0xFF000000 : 0xFFFFFFFF
        text = "∞"
      }.__update(fontTinyAccented)
})

let onClick = @(quests) addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  children = modalWndBg.__merge({
    maxHeight = saSize[1]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("quests/rewarsForChainCompletion"),
        @() removeModalWindow(WND_UID),
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      makeVertScroll({
        size = [saSize[0], SIZE_TO_CONTENT]
        rendObj = ROBJ_BOX
        flow = FLOW_VERTICAL
        padding = hdpx(20)
        gap = hdpx(20)
        children = quests.map(function(q, idx) {
          let rewardsPreview = Computed(@() getRewardsPreviewInfo(q, serverConfigs.get()))
          let blockWidth = min(chainIconBlockWidth, quests.len() < 1 ? 0 : iconWidth * quests.len() + questIconGap * (quests.len() - 1))
          let gap = min(questIconGap, idx == 0 ? 0 : (chainIconBlockWidth - (iconWidth * (idx + 1))) / idx)
          return {
            size = FLEX_H
            rendObj = ROBJ_SOLID
            color = 0x80000000
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            padding = hdpx(20)
            gap = hdpx(20)
            children = [
              {
                rendObj = ROBJ_BOX
                size = [blockWidth, SIZE_TO_CONTENT]
                flow = FLOW_VERTICAL
                gap = questIconGap
                children = [
                  {
                    rendObj = ROBJ_TEXT
                    size = FLEX_H
                    halign = ALIGN_CENTER
                    color = iconColor
                    text = $"{idx + 1}/{quests.len()}"
                  }.__update(fontSmall)
                  {
                    size = FLEX_H
                    gap
                    halign = ALIGN_CENTER
                    flow = FLOW_HORIZONTAL
                    children = array(idx, mkProgresImage(P_COMPLETED))
                      .append(mkProgresImage(q?.periodic ? P_COMPLETED | P_PERIODIC : P_COMPLETED))
                  }
                ]
              }
              {
                rendObj = ROBJ_BOX
                size = FLEX_H
                flow = FLOW_VERTICAL
                children = [
                  mkQuestText(q)
                  mkQuestBar(q)
                ]
              }
              @() {
                watch = rewardsPreview
                rendObj = ROBJ_BOX
                size = [rewardPlateFullWidth * min(rewardsPreview.get().reduce(@(acc, r) acc += r.slots, 0), REWARDS_PREVIEW_SLOTS),
                  SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                gap = hdpx(10)
                halign = ALIGN_RIGHT
                children = rewardsPreview.get().len() > 0 ? mkRewardsPreview(rewardsPreview.get(), q.isFinished) : null
              }
            ]
          }})
      }, { size = [SIZE_TO_CONTENT, saSize[1] - wndHeaderHeight], isBarOutside = true })
    ]
  })
  animations = wndSwitchAnim
}))

let mkChainProgress = function(item, ovr = {}) {
  let gap = min(questIconGap,
    item.chainQuests.len() < 2 ? 0 : (chainIconBlockWidth - (iconWidth * item.chainQuests.len())) / (item.chainQuests.len() - 1))
  return {
    rendObj = ROBJ_BOX
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      mkSquareIconBtn("⌡", @() onClick(item.chainQuests),
        {
          size = hdpx(50)
          borderColor = 0xFFFFFFFF
          borderWidth = 2
          rendObj = ROBJ_BOX
        }, fontSmall)
      {
        rendObj = ROBJ_TEXT
        color = iconColor
        text = $"{item.chainQuests.filter(@(v) v.isCompleted).len()}/{item.chainQuests.len()}"
      }.__update(fontSmall)
      {
        size = [chainIconBlockWidth, SIZE_TO_CONTENT]
        rendObj = ROBJ_BOX
        flow = FLOW_HORIZONTAL
        gap
        valign = ALIGN_CENTER
        children = item.chainQuests.map(@(q, idx) mkProgresImage(
          (q.isCompleted ? P_COMPLETED : 0)
            | (idx == item.pos ? P_CURRENT : 0)
            | (q?.periodic ? P_PERIODIC : 0)))
      }
    ]
  }.__update(ovr)
}

return {
  mkChainProgress
}
