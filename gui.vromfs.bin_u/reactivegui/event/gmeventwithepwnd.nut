from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { isGmEventWndEPOpened, closeGmEPWnd, curGmList, openedGMEvenPasstId, hasAccessCurGmEvent
} = require("%rGui/event/gmEventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { textButtonCommon, mkCustomButton, ICON_SIZE } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { openEventPassWnd, curOpenEventPass, eventBgImage} = require("%rGui/battlePass/eventPassState.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { defaultShopCategory } = require("%rGui/shop/shopCommon.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { COMMON_TAB } = require("%rGui/quests/questsState.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")

let headerGap = hdpx(30)

let openEventPass = @(eventId)  openEventPassWnd(eventId)

let toBattleHint = @(text) {
  pos = [saBorders[0] * 0.5, saBorders[1]]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  color = 0x70000000
  children = {
    size = [ SIZE_TO_CONTENT, hdpx(500)]
    maxWidth = hdpx(550)
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
  }.__update(fontTiny)
}

let gmEventTitle = @() {
  watch = openedGMEvenPasstId
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = pw(97)
      text = loc($"events/name/{openedGMEvenPasstId.get()}")
    }.__update(fontBig)
    infoEllipseButton(@() openNewsWndTagged(openedGMEvenPasstId.get()))
  ]
}

let header = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = doubleSideGradient.__merge({
    padding = const [hdpx(20), hdpx(200), hdpx(17), 0]
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    valign = ALIGN_CENTER
    children = [
      backButton(closeGmEPWnd)
      gmEventTitle
    ]
  })
}

let buttonsContent = @(image, text) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  valign = ALIGN_CENTER
  children = [
    {
      size = [ICON_SIZE, ICON_SIZE]
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{ICON_SIZE}:{ICON_SIZE}:P")
    }
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
    }.__update(fontTinyAccented)
  ]
}

let footer = @() {
  watch = curGmList
  size = [flex(), defButtonHeight]
  valign = ALIGN_BOTTOM
  children = curGmList.get().len() == 0 ? null
    : [
        @() {
          watch = curOpenEventPass
          flow = FLOW_VERTICAL
          gap = hdpx(20)
          children = [
            mkBtnOpenTabQuests(curOpenEventPass.get()?.eventId ?? COMMON_TAB, {
              sizeBtn = [hdpx(109), hdpx(109)],
              iconSize = hdpx(85)
              size = hdpx(109)
            })
            {
              flow = FLOW_HORIZONTAL
              gap = hdpx(20)
              children = [
                mkCustomButton(buttonsContent("ui/gameuiskin#icon_shop.svg", utf8ToUpper(loc("eventShop"))),
                  @() openShopWnd(defaultShopCategory))
                mkCustomButton(buttonsContent("ui/gameuiskin#icon_event_pass.svg", utf8ToUpper(loc("eventPass"))),
                  @() openEventPass(openedGMEvenPasstId.get()))
              ]
            }
          ]
        }

        @() {
          watch = [hasAccessCurGmEvent, openedGMEvenPasstId]
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          valign = ALIGN_BOTTOM
          gap = hdpx(10)
          children = hasAccessCurGmEvent.get()
            ? [
                toBattleHint(loc($"events/toBattle/{openedGMEvenPasstId.get()}"))
                mkToBattleButtonWithSquadManagement(
                  function() {
                    if (curGmList.get().len() == 0)
                      return
                    sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = openedGMEvenPasstId.get() })
                    let modeId = curGmList.get()[0].gameModeId
                    let campaign = curGmList.get()[0].campaign
                    let name = curGmList.get()[0]?.mission_decl.missions_list.findindex(@(_) true) ?? curGmList.get()[0]?.name ?? ""
                    if (tryOpenQueuePenaltyWnd(campaign, { id = "queueToGameMode", modeId }, null, name))
                      return
                    eventbus_send("queueToGameMode", { modeId })
                  },
                  Watched(null)
                )
              ]
            : [
                toBattleHint(loc($"{openedGMEvenPasstId.get()}/requireAccess"))
                textButtonCommon(utf8ToUpper(loc("mainmenu/toBattle/short")),
                  @() openMsgBox({ text = loc($"{openedGMEvenPasstId.get()}/requireAccess") }))
              ]
        }
      ]
}

let wndKey = {}
let gmEventWnd = {
  key = wndKey
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = headerGap
  children = [
    header
    { size = flex() }
    footer
  ]
  animations = wndSwitchAnim
}

registerScene("gmEventEPWnd", gmEventWnd, closeGmEPWnd, isGmEventWndEPOpened)
setSceneBg("gmEventEPWnd", eventBgImage.get())
eventBgImage.subscribe(@(v) setSceneBg("gmEventEPWnd", v))
