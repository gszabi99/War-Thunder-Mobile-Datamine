from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { seenPasses, isPassGoodsUnseen } = require("%rGui/battlePass/passState.nut")
let { hasBpRewardsToReceive, battlePassGoods } = require("%rGui/battlePass/battlePassState.nut")
let { hasOPRewardsToReceive, operationPassGoods } = require("%rGui/battlePass/operationPassState.nut")
let { hasAnyEpRewardsToReceive, allEventPassGoods } = require("%rGui/battlePass/eventPassState.nut")
let { eventSeason, eventSeasonIdx, unseenLootboxes, unseenLootboxesShowOnce, MAIN_EVENT_ID,
} = require("%rGui/event/eventState.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { translucentButton, translucentButtonsVGap, translucentButtonsWidth } = require("%rGui/components/translucentButton.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { openSeasonScene, LOOTBOX_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { tutorialQuestBtnKey } = require("%rGui/quests/questsState.nut")


let bannerBtnKey = "bp_banner_btn" 

let bannerIconSize = [hdpxi(184), hdpxi(108)]
let borderColor = 0xFFDEDEDE
let bannerWidth = translucentButtonsVGap * 2 + translucentButtonsWidth * 3
let textRowHeight = hdpx(30)
let bannerHeight = hdpx(20) + bannerIconSize[1] + textRowHeight

let mainEventBtn = translucentButton("ui/gameuiskin#icon_events.svg",
  @() openSeasonScene(LOOTBOX_TAB, null, MAIN_EVENT_ID),
  null,
  @(_) @() {
    watch = [unseenLootboxes, unseenLootboxesShowOnce, eventLootboxes]
    children = eventLootboxes.get().reduce(@(res, v) res || !!unseenLootboxes.get()?[MAIN_EVENT_ID][v.name], false)
      || unseenLootboxesShowOnce.get().findindex(@(v) v == MAIN_EVENT_ID) != null
          ? priorityUnseenMark
        : null
})

let hasAnyPassRewards = Computed(@() hasBpRewardsToReceive.get() || hasOPRewardsToReceive.get() || hasAnyEpRewardsToReceive.get())
let hasUnseenOP = Computed(@() isPassGoodsUnseen(operationPassGoods.get(), seenPasses.get()))
let hasAnyUnseenPass = Computed(@() isPassGoodsUnseen(battlePassGoods.get(), seenPasses.get())
  || hasUnseenOP.get()
  || null != allEventPassGoods.get().findindex(@(v) isPassGoodsUnseen(v, seenPasses.get())))
let needShowUnseenMarker = Computed(@() hasAnyPassRewards.get() || hasAnyUnseenPass.get() || hasUnseenOP.get())

return @(isPassActive, isEventActive) function () {
  let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
  let mainBtn = isEventActive ? mainEventBtn : null
  let stateFlags = Watched(0)
  return {
    watch = eventSeason
    children = !isPassActive ? mainBtn
      : @() {
          watch = stateFlags
          key = bannerBtnKey
          onAttach = @() tutorialQuestBtnKey.set(bannerBtnKey)
          onDetach = @() tutorialQuestBtnKey.set(null)
          size = [bannerWidth, bannerHeight]
          sound = { click = "click" }
          rendObj = ROBJ_9RECT
          image = Picture($"ui/gameuiskin#gradient_btn_full.svg:{bannerWidth}:{bannerHeight}:P")
          texOffs = [bannerHeight / 2, bannerHeight / 2]
          screenOffs = [bannerHeight / 2, bannerHeight / 2]
          color = stateFlags.get() & S_HOVER ? hoverColor : borderColor
          onElemState = @(sf) stateFlags.set(sf)
          behavior = Behaviors.Button
          onClick = @() openSeasonScene(LOOTBOX_TAB)
          children = {
            size = [FLEX, SIZE_TO_CONTENT]
            rendObj = ROBJ_BOX
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            padding = const [hdpx(10), hdpx(20), hdpx(10), hdpx(20)]
            children = [
              {
                size = [FLEX, bannerIconSize[1]]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = [
                  {
                    size = [FLEX, hdpx(75)]
                    rendObj = ROBJ_9RECT
                    image = gradTranspDoubleSideX
                    texOffs = [0, gradDoubleTexOffset]
                    screenOffs = [0, hdpx(130)]
                    color
                  }
                  {
                    size = bannerIconSize
                    rendObj = ROBJ_IMAGE
                    keepAspect = true
                    pos = imageOffset.map(@(pos, idx) pos * bannerIconSize[idx])
                    image = Picture($"{image}:{bannerIconSize[0]}:{bannerIconSize[1]}:P")
                  }
                ]
              }
              @() {
                watch = [eventSeasonIdx, needShowUnseenMarker]
                size = [SIZE_TO_CONTENT, textRowHeight]
                flow = FLOW_HORIZONTAL
                valign = ALIGN_CENTER
                gap = hdpx(10)
                children = [
                  {
                    rendObj = ROBJ_TEXT
                    color = 0xFFFFFFFF
                    text = utf8ToUpper(loc("events/seasonNumber", { number = eventSeasonIdx.get() }))
                  }.__update(fontBoldTinyShaded)
                  needShowUnseenMarker.get() ? priorityUnseenMark : null
                ]
              }
            ]
          }
          transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
          transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
        }
  }
}
