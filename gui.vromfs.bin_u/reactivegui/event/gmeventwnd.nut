from "%globalsDarg/darg_library.nut" import *
let logE = log_with_prefix("[GM_EVENT] ")
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isGmEventWndOpened, closeGmEventWnd, curGmList, openedGmEventId, reqBattleMods, hasAccessCurGmEvent
} = require("%rGui/event/gmEventState.nut")
let { userstatStats, userstatSetStat, userstatRegisterExecutor, statsInProgress
} = require("%rGui/unlocks/userstat.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendNewbieBqEvent, sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { gmEventContent, goodsSize, goodsGap } = require("%rGui/event/gmEventComps.nut")
let { PLATINUM } = require("%appGlobals/currenciesState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let { shopGoodsAllCampaigns } = require("%rGui/shop/shopState.nut")
let { sendAppsFlyerEvent } = require("%rGui/notifications/logEvents.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")


let headerGap = hdpx(30)

let statMode = "meta_common"
let STAT_NO_NEED = -1
let STAT_NOT_REQUESTED = 0
let STAT_REQUESTED = 1
let STAT_HAS_ACCESS = 2
let MAX_GOODS_COUNT = 3

let isWndAttached = Watched(false)
let curEventAccessStat = Computed(@() openedGmEventId.get() == null ? ""
  : gmEventPresentation(openedGmEventId.get()).accessStat)
let curEventAccessStatValue = Computed(@() curEventAccessStat.get() == "" ? STAT_NO_NEED
  : userstatStats.get()?.stats["global"][statMode][curEventAccessStat.get()])
let isAcceessStatInProgress = Computed(@() !!statsInProgress.get()?[curEventAccessStat.get()])

function setAccessStat(value, context = {}) {
  if (isAcceessStatInProgress.get())
    return
  let stat = curEventAccessStat.get()
  if (stat != null && curEventAccessStatValue.get() != value) {
    sendUiBqEvent("set_access_stat", { id = stat, status = value.tostring() })
    userstatSetStat(statMode, stat, value, context)
  }
}

userstatRegisterExecutor("gmEvent.requestAccess", function(result, context) {
  let { eventId } = context
  if ("error" not in result)
    openMsgBox({ text = loc($"{eventId}/freeAccess/resultMsg"), title = loc($"{eventId}/freeAccess/resultMsg/header") })
})

let signUpForCbtContent = @() {
  watch = [isAcceessStatInProgress, openedGmEventId]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = isAcceessStatInProgress.get() ? spinner
    : [
        {
          maxWidth = hdpx(1400)
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = 0xFFE0E0E0
          colorTable = locColorTable
          preformatted = FMT_KEEP_SPACES
          text = loc($"{openedGmEventId.get()}/freeAcccess/desc")
        }.__update(fontSmall)
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = hdpx(30)
          children = [
            {
              rendObj = ROBJ_TEXT
              color = 0xFFE0E0E0
              text = loc("readMore")
            }.__update(fontSmall)
            infoEllipseButton(@() openNewsWndTagged(openedGmEventId.get()))
          ]
        }
        textButtonPrimary(utf8ToUpper(loc($"{openedGmEventId.get()}/freeAccess/btn")),
          function() {
            logE("User press freeAccess button")
            setAccessStat(STAT_REQUESTED, { executeAfter = "gmEvent.requestAccess", eventId = openedGmEventId.get() })
          })
      ]
}

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

let gmEventStatusText = @(text) {
  maxWidth = (saSize[0] - (goodsSize[0] * MAX_GOODS_COUNT + goodsGap * MAX_GOODS_COUNT * 2)) / 2
  pos = [0, hdpx(40)]
  text
}.__update(fontTinyAccented, gmEventText)

function validateAccessStat() {
  if (curEventAccessStat.get() == "" || !isWndAttached.get())
    return
  if (hasAccessCurGmEvent.get() && curEventAccessStatValue.get() != STAT_HAS_ACCESS) {
    logE($"Has access on window attach. set stat {curEventAccessStat.get()} to {STAT_HAS_ACCESS}")
    setAccessStat(STAT_HAS_ACCESS)
    sendAppsFlyerEvent("purchase_cbt_access")
  }
  else if (!hasAccessCurGmEvent.get() && curEventAccessStatValue.get() == STAT_HAS_ACCESS) {
    logE($"Dont has access on window attach. But has stat. So set stat {curEventAccessStat.get()} to {STAT_NOT_REQUESTED}")
    setAccessStat(STAT_NOT_REQUESTED)
  }
}

isWndAttached.subscribe(@(_) validateAccessStat())
hasAccessCurGmEvent.subscribe(@(_) validateAccessStat())
let content = @() {
  watch = [hasAccessCurGmEvent, curEventAccessStatValue, curEventAccessStat]
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  onAttach = @() isWndAttached.set(true)
  onDetach = @() isWndAttached.set(false)
  children = !hasAccessCurGmEvent.get() && curEventAccessStat.get() != "" && curEventAccessStatValue.get() != STAT_REQUESTED
    ? signUpForCbtContent
    : [
        {
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          children = [
            gmEventSubTitleText(loc($"{openedGmEventId.get()}/accessPacks/header"))
            gmEventContent(Computed(@() reqBattleMods.get().len() == 0 ? []
              : shopGoodsAllCampaigns.get()
                .filter(@(goods) null != (goods?.battleMods.findvalue(@(_, bm) reqBattleMods.get().contains(bm))))
                .values()))
            gmEventDescriptionText(loc($"{openedGmEventId.get()}/accessPacks/description"))
          ]
        }
      ].append(!hasAccessCurGmEvent.get() ?
        {
          hplace = ALIGN_LEFT
          vplace = ALIGN_TOP
          children = gmEventStatusText(loc($"{openedGmEventId.get()}/freeAccess/resultMsg"))
        }
      : null)
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

let gmEventTitle = @(text) @() {
  hplace = ALIGN_CENTER
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    {
      maxWidth = pw(97)
      text
    }.__update(fontBig, gmEventText)
    infoEllipseButton(@() openNewsWndTagged(openedGmEventId.get()))
  ]
}

let header = @() {
  watch = openedGmEventId
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(closeGmEventWnd)
    gmEventTitle(loc($"{openedGmEventId.get()}/title"))
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      gap = hdpx(70)
      children = mkCurrenciesBtns([PLATINUM])
    }
  ]
}

let footer = @() {
  watch = curGmList
  size = [flex(), defButtonHeight]
  valign = ALIGN_BOTTOM
  children = curGmList.get().len() == 0 ? null
    : [
        {
          hplace = ALIGN_CENTER
          children = squadPanel
        }
        @() {
          watch = [hasAccessCurGmEvent, openedGmEventId]
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          children = hasAccessCurGmEvent.get()
            ? [
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
            : [
                toBattleHint(loc($"{openedGmEventId.get()}/requireAccess"))
                textButtonCommon(utf8ToUpper(loc("mainmenu/toBattle/short")),
                  @() openMsgBox({ text = loc($"{openedGmEventId.get()}/requireAccess") }))
              ]
        }
      ]
}

let wndKey = {}
let gmEventWnd = @() {
  watch = openedGmEventId
  key = wndKey
  size = flex()
  padding = saBordersRv
  rendObj = ROBJ_IMAGE
  image = Picture(gmEventPresentation(openedGmEventId.get()).bgImage)
  flow = FLOW_VERTICAL
  gap = headerGap
  children = [
    header
    content
    footer
  ]
  animations = wndSwitchAnim
}

registerScene("gmEventWnd", gmEventWnd, closeGmEventWnd, isGmEventWndOpened)
