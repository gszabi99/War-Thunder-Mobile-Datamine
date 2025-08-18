from "%globalsDarg/darg_library.nut" import *

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { contentWidth } = require("%rGui/options/optionsStyle.nut")
let { REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardStyles.nut")
let { addModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { mkSquareIconBtn } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkQuestBar } = require("%rGui/quests/questBar.nut")
let { mkRewardsPreview, getRewardsPreviewInfo, REWARDS_PREVIEW_SLOTS } = require("%rGui/quests/rewardsComps.nut")
let { mkQuestText } = require("%rGui/quests/questsPkg.nut")


let WND_UID = "quest_chain_info_wnd"

let questChainIconSize = [hdpxi(40), hdpxi(45)]
let questIconGap = hdpx(10)
let iconColor = 0xFFFF9C11

let questChainIconCurrent = Picture($"ui/gameuiskin/quest_chain_icon_current.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconCompleted = Picture($"ui/gameuiskin/quest_chain_icon_completed.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")
let questChainIconComing = Picture($"ui/gameuiskin/quest_chain_icon_coming.svg:{questChainIconSize[0]}:{questChainIconSize[1]}:P")

let mkProgresImage = @(isCompleted, isComming = false) {
  size = questChainIconSize
  rendObj = ROBJ_IMAGE
  image = isCompleted ? questChainIconCompleted
    : isComming ? questChainIconComing
    : questChainIconCurrent
  color = isCompleted ? iconColor : 0xFFFFFFFF
  keepAspect = true
}

let onClick = @(quests) addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  children = modalWndBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeader(
        loc("quests/rewarsForChainCompletion"),
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      {
        rendObj = ROBJ_BOX
        flow = FLOW_VERTICAL
        padding = hdpx(20)
        gap = hdpx(20)
        children = quests.map(function(q, idx) {
          let rewardsPreview = Computed(@() getRewardsPreviewInfo(q, serverConfigs.get()))
          return {
            rendObj = ROBJ_SOLID
            color = 0x80000000
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            padding = hdpx(20)
            gap = hdpx(20)
            children = [
              {
                rendObj = ROBJ_BOX
                size = [quests.len() * (questChainIconSize[0] + questIconGap), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                gap = questIconGap
                children = array(idx + 1).map(@(_) mkProgresImage(true))
              }
              {
                rendObj = ROBJ_BOX
                size = [contentWidth, SIZE_TO_CONTENT]
                flow = FLOW_VERTICAL
                children = [
                  mkQuestText(q)
                  mkQuestBar(q)
                ]
              }
              @() {
                watch = rewardsPreview
                rendObj = ROBJ_BOX
                size = [(REWARD_STYLE_SMALL.boxSize + REWARD_STYLE_SMALL.boxGap) * REWARDS_PREVIEW_SLOTS, SIZE_TO_CONTENT ]
                flow = FLOW_HORIZONTAL
                gap = hdpx(10)
                halign = ALIGN_RIGHT
                children = rewardsPreview.get().len() > 0 ? mkRewardsPreview(rewardsPreview.get(), q.isFinished) : null
              }
            ]
          }})
      }
    ]
  })
  animations = wndSwitchAnim
}))

let mkChainProgress = @(item, ovr = {}) {
  rendObj = ROBJ_BOX
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    mkSquareIconBtn("⌡", @() onClick(item.chainQuests), { size = hdpx(50), borderColor = 0xFFFFFFFF, borderWidth = 2, rendObj = ROBJ_BOX }, fontSmall)
    {
      rendObj = ROBJ_BOX
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(15)
      children = item.chainQuests.map(@(q, idx)
        mkProgresImage(q.isCompleted, idx > item.pos)
      )
    }
  ]
}.__update(ovr)

return {
  mkChainProgress
}
