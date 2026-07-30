from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { curGmList, openedGmEventId } = require("%rGui/event/gmEventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")


let headerGap = hdpx(30)

let gmEventText = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFE0E0E0
}

let gmEventSubTitleText = @(text) {
  halign = ALIGN_CENTER
  maxWidth = hdpx(1100)
  text
}.__update(fontTiny, gmEventText)

let gmEventDescriptionText = @(text) {
  maxWidth = hdpx(900)
  text
}.__update(fontTiny, gmEventText)

let content = @() {
  watch = openedGmEventId
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    "descHeaderLocId" not in getEventPresentation(openedGmEventId.get()) ? null
      : gmEventSubTitleText(loc(getEventPresentation(openedGmEventId.get()).descHeaderLocId))
    "descLocId" not in getEventPresentation(openedGmEventId.get()) ? null
      : gmEventDescriptionText(loc(getEventPresentation(openedGmEventId.get()).descLocId))
  ]
}

let toBattleHint = @(text) {
  hplace = ALIGN_RIGHT
  pos = [saBorders[0] * 0.5, 0]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, saBorders[0]]
  color = 0x70000000
  children = {
    size = [defButtonMinWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
  }.__update(fontTinyAccented)
}

let footer = @() {
  watch = curGmList
  size = [FLEX, defButtonHeight]
  valign = ALIGN_BOTTOM
  children = curGmList.get().len() == 0 ? null
    : [
        {
          hplace = ALIGN_CENTER
          children = squadPanel
        }
        @() {
          watch = openedGmEventId
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          children = [
            toBattleHint(loc("events/toBattle"))
            mkToBattleButtonWithSquadManagement(
              function() {
                if (curGmList.get().len() == 0)
                  return
                sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = openedGmEventId.get() })
                let modeId = curGmList.get()[0].gameModeId
                let campaign = curGmList.get()[0].campaign
                if (tryOpenQueuePenaltyWnd(campaign, curGmList.get()[0], { id = "queueToGameMode", modeId }))
                  return
                eventbus_send("queueToGameMode", { modeId })
              },
              Computed(@() curGmList.get()?[0]))
          ]
        }
      ]
}

let gmEventWnd = {
  size = FLEX
  padding = saBordersRv

  flow = FLOW_VERTICAL
  gap = headerGap
  children = [
    content
    footer
  ]
  animations = wndSwitchAnim
}

return gmEventWnd