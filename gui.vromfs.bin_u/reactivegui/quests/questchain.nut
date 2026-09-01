from "%globalsDarg/darg_library.nut" import *
from "math" import min
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, wndHeaderHeight, modalWndHeaderWithClose
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/textButton.nut" import buttonsHGap
from "%rGui/quests/questBar.nut" import mkQuestBar
from "%rGui/quests/questsPkg.nut" import mkQuestText
from "%rGui/quests/rewardsComps.nut" import mkRewardsPreview, getRewardsPreviewInfo, REWARDS_PREVIEW_SLOTS
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_SMALL
from "%rGui/shop/goodsView/sharedParts.nut" import mkSquareIconBtn
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const WND_UID = "quest_chain_info_wnd"

const maxVisibleQuestChains = 6
const iconWidth = hdpxi(40)
const questIconGap = hdpx(10)
const chainIconBlockWidth = iconWidth * maxVisibleQuestChains + questIconGap * (maxVisibleQuestChains - 1)
let questChainIconSize = [iconWidth, hdpxi(45)]
const iconColor = 0xFFFF9C11
let rewardPlateFullWidth = REWARD_STYLE_SMALL.boxSize + REWARD_STYLE_SMALL.boxGap

let questChainIconCurrent = Picture($"ui/gameuiskin/quest_chain_icon_current.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconCompleted = Picture($"ui/gameuiskin/quest_chain_icon_completed.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconComing = Picture($"ui/gameuiskin/quest_chain_icon_coming.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")

const P_COMPLETED = 0x1
const P_CURRENT = 0x2
const P_PERIODIC = 0x4

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
        size = FLEX
        pos = const [0, -hdpx(3)]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = mask & P_COMPLETED ? 0xFF000000 : 0xFFFFFFFF
        text = "∞"
      }.__update(fontTinyAccented)
})

let onClick = @(quests) addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = FLEX
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
      }, { size = SIZE_TO_CONTENT, maxHeight = saSize[1] - wndHeaderHeight, isBarOutside = true })
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
