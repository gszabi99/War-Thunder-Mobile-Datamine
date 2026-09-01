from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/event/gmEventState.nut" import curGmList, openedGmEventId, gmEventEndsAt
from "%rGui/mainMenu/toBattleButton.nut" import mkToBattleButtonWithSquadManagement
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
import "%rGui/squad/squadPanel.nut" as squadPanel
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/timerBlock.nut" import mkTimerBlock


const headerGap = hdpx(30)
let txtWidth = defButtonMinWidth + saBorders[0] * 2
const txtPaddingV = hdpx(20)
let txtPaddingH = saBorders[0] / 2

let curGameMode = Computed(@() curGmList.get()?[0])

let gmEventText = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFE0E0E0
}

let gmEventSubTitleText = @(text) {
  halign = ALIGN_CENTER
  maxWidth = txtWidth
  text
}.__update(fontTinyAccentedShaded, gmEventText)

let gmEventDescriptionText = @(text) {
  maxWidth = txtWidth
  text
}.__update(fontTinyAccentedShaded, gmEventText)

let txtBlock = @() {
  watch = openedGmEventId
  flow = FLOW_VERTICAL
  children = [
    "descHeaderLocId" not in getEventPresentation(openedGmEventId.get()) ? null
      : gmEventSubTitleText(loc(getEventPresentation(openedGmEventId.get()).descHeaderLocId))
    "descLocId" not in getEventPresentation(openedGmEventId.get()) ? null
      : gmEventDescriptionText(loc(getEventPresentation(openedGmEventId.get()).descLocId))
    gmEventDescriptionText(loc("events/toBattle"))
  ]
}

let footer = @() {
  watch = curGameMode
  size = const [FLEX, SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  vplace = ALIGN_BOTTOM
  children = curGameMode.get() == null ? null
    : [
        (curGameMode.get()?.maxSquadSize ?? 1) <= 1 ? null
          : {
              hplace = ALIGN_CENTER
              children = squadPanel
            }
        @() panelBg.__merge({
          watch = openedGmEventId
          padding = [txtPaddingV, saBorders[0], saBorders[0], txtPaddingH]
          pos = [saBorders[0], saBorders[0]]
          hplace = ALIGN_RIGHT
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          gap = txtPaddingV
          children = [
            txtBlock
            mkToBattleButtonWithSquadManagement(
              function() {
                if (curGameMode.get() == null)
                  return
                sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = openedGmEventId.get() })
                let modeId = curGameMode.get().gameModeId
                let campaign = curGameMode.get().campaign
                if (tryOpenQueuePenaltyWnd(campaign, curGameMode.get(), { id = "queueToGameMode", modeId }))
                  return
                eventbus_send("queueToGameMode", { modeId })
              },
              curGameMode)
          ]
        })
      ]
}

let gmEventWnd = {
  size = FLEX
  padding = [0, saBordersRv[1], saBordersRv[0], saBordersRv[1]]

  gap = headerGap
  children = [
    mkTimerBlock(gmEventEndsAt)
    footer
  ]
  animations = wndSwitchAnim
}

return gmEventWnd