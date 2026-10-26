from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/event/gmEventState.nut" import openedGmEventId, gmEventEndsAt, curGmList
from "%rGui/seasonScene/seasonSceneState.nut" import seasonPageId, BATTLE_TAB_MODE_IDX
from "%rGui/mainMenu/toBattleButton.nut" import mkToBattleButtonWithSquadManagement
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
from "%rGui/squad/squadPanel.nut" import squadPanelFull
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/components/timerBlock.nut" import mkTimerBlock


const headerGap = hdpx(30)
let txtWidth = defButtonMinWidth + saBorders[0] * 2
const txtPaddingV = hdpx(20)
let txtPaddingH = saBorders[0] / 2
const txtGradFadeW = hdpx(50)
let txtSize = [txtWidth, SIZE_TO_CONTENT]
let txtBgPadding = [txtPaddingV, saBorders[0], txtPaddingV, txtGradFadeW]
let toBattleBtnPadding = [0, saBorders[0], 0, txtGradFadeW]

let curGameMode = Computed(function() {
  let modeIdx = BATTLE_TAB_MODE_IDX?[seasonPageId.get()]
  return (modeIdx == null ? null : curGmList.get()?[modeIdx]) ?? curGmList.get()?[0]
})
let hasGmEventSquadPanel = Computed(@() (curGameMode.get()?.maxSquadSize ?? 1) > 1)

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

function txtBlock() {
  let { descHeaderLocId = null, descLocId = null } = getEventPresentation(openedGmEventId.get())
  if (descHeaderLocId == null && descLocId == null)
    return { watch = openedGmEventId }
  return {
    watch = openedGmEventId
    padding = txtBgPadding
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    color = 0x80000000
    children = {
      size = txtSize
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        descHeaderLocId == null ? null : gmEventSubTitleText(loc(descHeaderLocId))
        descLocId == null ? null : gmEventDescriptionText(loc(descLocId))
      ]
    }
  }
}

let squadBlock = {
  hplace = ALIGN_CENTER
  children = squadPanelFull
}

let footer = @() {
  watch = [curGameMode, hasGmEventSquadPanel]
  size = const [FLEX, SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  vplace = ALIGN_BOTTOM
  children = curGameMode.get() == null ? null
    : [
        hasGmEventSquadPanel.get() ? squadBlock : null
        @() {
          watch = openedGmEventId
          padding = [txtPaddingV, 0, saBorders[0], txtPaddingH]
          pos = [saBorders[0], saBorders[0]]
          hplace = ALIGN_RIGHT
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          gap = txtPaddingV
          children = [
            txtBlock
            {
              padding = toBattleBtnPadding
              children = mkToBattleButtonWithSquadManagement(
                function() {
                  let gm = curGameMode.get()
                  if (gm == null)
                    return
                  sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = openedGmEventId.get() })
                  let modeId = gm.gameModeId
                  if (tryOpenQueuePenaltyWnd(gm.campaign, gm, { id = "queueToGameMode", modeId }))
                    return
                  eventbus_send("queueToGameMode", { modeId })
                },
                curGameMode)
            }
          ]
        }
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

return {
  gmEventWnd
  hasGmEventSquadPanel
}
