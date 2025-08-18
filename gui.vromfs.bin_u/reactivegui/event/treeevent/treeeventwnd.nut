from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")

let { registerScene } = require("%rGui/navState.nut")
let { isTreeEventWndOpened, closeTreeEventWnd, openedTreeEventId, presetBgElems, closeSubPreset,
  presetBackground, presetMapSize, presetPointSize, selectedPointId, curEventEndsAt, getUnlocksCurrencies,
  presetGridSize, curGmList, presetLines, curEventUnlocks, presetPoints, isSubPresetOpened,
  getFirstOrCurSubPreset, presetUnlocksComplete
} = require("%rGui/event/treeEvent/treeEventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let mapNet = require("%rGui/event/treeEvent/mapNet.nut")
let { mkTimeUntil } = require("%rGui/quests/questsPkg.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { mkLineCmds, mkLineCmdsOutline, mkLinePresetColor, mkPoint, mkBgElement, mkQuestInfoWnd
} = require("%rGui/event/treeEvent/treeEventComps.nut")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let { CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { openEventWnd, unseenLootboxes, MAIN_EVENT_ID } = require("%rGui/event/eventState.nut")
let { eventLootboxesRaw, orderLootboxesBySlot } = require("%rGui/event/eventLootboxes.nut")
let { subPresetContainer } = require("%rGui/event/treeEvent/treeEventSubPreset/subPresetContainer.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let lootboxIconSize = CS_INCREASED_ICON.iconSize
let gapSectionsWnd = hdpx(20)
let headerGap = hdpx(30)
let gamercardHeight = hdpx(70)
let footerHeight = gamercardHeight + defButtonHeight + gapSectionsWnd
let bgMapWidth = saSize[0]
let bgMapHeight = saSize[1] - (saBorders[1] + headerGap + footerHeight)

let bgTexOffs = [178, 130, 227, 127]
let bgScreenOffs = bgTexOffs.map(@(v) hdpx(v))

let delayToLoadBgElems = 0.2

let isShowSubPresetAllowed = Watched(false)

let mapPoints = @() {
  watch = [presetPoints, presetPointSize]
  size = flex()
  children = presetPoints.get().reduce(@(acc, value, id) acc.append(mkPoint(value.__merge({ id }), presetPointSize.get())), [])
}

let bgElementsOnTop = @() {
  watch = presetBgElems
  size = flex()
  children = presetBgElems.get()
    .filter(@(v) !!v?.isOnTop)
    .map(mkBgElement)
}

let bgElements = @() {
  watch = presetBgElems
  size = flex()
  children = presetBgElems.get()
    .filter(@(v) !v?.isOnTop)
    .map(mkBgElement)
}

let mapContentAnims = [
  { prop = AnimProp.opacity, from = 0.01, to = 0.01, play = true,
    duration = delayToLoadBgElems
  }
  { prop = AnimProp.opacity, from = 0.01, to = 1.0, easing = InQuad, play = true,
    duration = 0.3, delay = delayToLoadBgElems,
  }
]

let mapBackground = @() {
  watch = presetBackground
  size = flex()
  children = presetBackground.get() == "" ? null
    : {
        size = flex()
        behavior = Behaviors.Button
        onClick = @() selectedPointId.set(null)
        rendObj = ROBJ_IMAGE
        image = Picture($"{presetBackground.get()}:0:P")
        keepAspect = true
      }
}

function mapLines() {
  let commands = []
  let points = presetPoints.get()
  let size = presetMapSize.get()

  foreach (line in presetLines.get()) {
    commands.append(mkLinePresetColor(line.to, presetUnlocksComplete.get()))
    commands.extend(mkLineCmds(line, points, size))
  }

  return {
    watch = [presetLines, presetPoints, presetMapSize, presetUnlocksComplete]
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    commands = mkLineCmdsOutline(commands)
  }
}

let scrollHandler = ScrollHandler()

function scrollToCurSubPreset() {
  let preset = presetBgElems.get()
    .findvalue(@(v) v.id == getFirstOrCurSubPreset())
  let { pos = [0, 0], size = 0 } = preset
  scrollHandler.scrollToX(hdpxi(pos[0]) - hdpxi(size[0]/2))
  scrollHandler.scrollToY(hdpxi(pos[1]))
}

let mapInsideBg = @() {
  watch = openedTreeEventId
  size = flex()
  rendObj = ROBJ_9RECT
  texOffs = bgTexOffs
  screenOffs = [0, 0, 0, 0]
  image = Picture(gmEventPresentation(openedTreeEventId.get()).bgMapImage)
}

function mapContainer() {
  let mapSize = presetMapSize.get().map(hdpx)
  return {
    key = presetMapSize
    size = [bgMapWidth, bgMapHeight]
    clipChildren = true
    children = {
      size = flex()
      behavior = [Behaviors.Pannable, Behaviors.ScrollEvent],
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = scrollHandler
      onAttach = scrollToCurSubPreset
      skipDirPadNav = true
      xmbNode = XmbContainer()
      children = @() {
        watch = presetMapSize
        size = mapSize
        children = [
          mapInsideBg
          {
            size = flex()
            children = [
              mapBackground
              bgElements
              mapNet(presetMapSize, presetGridSize, presetBgElems)
              bgElementsOnTop
              mapLines
              mapPoints
            ]
            animations = mapContentAnims
          }
        ]
      }
    }
  }
}

let mkCurrencies = @() {
  watch = [curEventUnlocks, serverConfigs]
  children = curEventUnlocks.get().len() == 0 ? null
    : {
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      color = 0x70000000
      children = mkCurrenciesBtns(getUnlocksCurrencies(curEventUnlocks.get(), serverConfigs.get()))
        .__update({ size = SIZE_TO_CONTENT })
    }
}

let eventGamercard = {
  size = [saSize[0], gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = headerGap
  children = [
    @() {
      watch = isSubPresetOpened
      children = backButton(@() isSubPresetOpened.get() ? closeSubPreset() : closeTreeEventWnd())
    }
    @() {
      watch = openedTreeEventId
      flow = FLOW_HORIZONTAL
      gap = headerGap
      children = [
        {
          rendObj = ROBJ_TEXT
          valign = ALIGN_CENTER
          text = loc($"events/name/{openedTreeEventId.get()}")
        }.__update(fontBig)
        infoEllipseButton(@() openNewsWndTagged(openedTreeEventId.get()))
      ]
    }
    { size = flex() }
    mkCurrencies
  ]
}

let lootboxBtn = mkCustomButton({
  key = "lootbox"
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = gapSectionsWnd
  children = [
    {
      size = [lootboxIconSize, lootboxIconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"ui/gameuiskin#events_chest_icon.svg:{lootboxIconSize}:{lootboxIconSize}:P") 
    }
    {
      maxWidth = hdpx(250)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = utf8ToUpper(loc("events/lootboxBtn"))
    }.__update(fontTinyAccentedShaded)
  ]
}, @() openEventWnd(openedTreeEventId.get()))

let curEventLootboxes = Computed(@()
  orderLootboxesBySlot(eventLootboxesRaw.get().filter(@(v) (v?.meta.event_id ?? MAIN_EVENT_ID) == openedTreeEventId.get())))

let needShowUnseenMark = Computed(function(){
  foreach(lb in curEventLootboxes.get())
    if(lb.name in unseenLootboxes.get()?[openedTreeEventId.get()])
      return true
  return false
})

let footer = {
  size = [flex(), defButtonHeight]
  valign = ALIGN_BOTTOM
  children = [
    @() {
      watch = eventLootboxesRaw
      children = [
        eventLootboxesRaw.get().findvalue(@(v) (v?.meta.event_id) == openedTreeEventId.get()) != null
          ? lootboxBtn
          : null
        @() {
          watch = needShowUnseenMark
          padding = hdpx(7)
          hplace = ALIGN_RIGHT
          children = needShowUnseenMark.get() ? priorityUnseenMark : null
        }
      ]
    }
    {
      hplace = ALIGN_CENTER
      children = squadPanel
    }
    @() {
      watch = openedTreeEventId
      hplace = ALIGN_RIGHT
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      children = [
        @() {
          watch = [serverTime, curEventEndsAt]
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = !curEventEndsAt.get() || (curEventEndsAt.get() - serverTime.get() < 0) ? null
            : mkTimeUntil(secondsToHoursLoc(curEventEndsAt.get() - serverTime.get()),
                "quests/untilTheEnd",
                { key = "event_time", margin = const [hdpx(20), 0, hdpx(60), 0] }.__update(fontTinyAccented))
        }
        mkToBattleButtonWithSquadManagement(function() {
          if (curGmList.get().len() == 0)
            return
          sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = openedTreeEventId.get() })
          let modeId = curGmList.get()[0].gameModeId
          if (tryOpenQueuePenaltyWnd(curGmList.get()[0].campaign, { id = "queueToGameMode", modeId }))
            return
          eventbus_send("queueToGameMode", { modeId })
        })
      ]
    }
  ]
}

let allowSubPreset = @() isShowSubPresetAllowed.set(true)

let treeEventWnd = @() {
  watch = openedTreeEventId
  key = {}
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(gmEventPresentation(openedTreeEventId.get()).bgImage)
  onAttach = @() resetTimeout(delayToLoadBgElems, allowSubPreset)
  onDetach = @() isShowSubPresetAllowed.set(false)
  children = [
    {
      pos = [0, headerGap]
      size = [bgMapWidth + bgScreenOffs[1] + bgScreenOffs[3], bgMapHeight + bgScreenOffs[0] + bgScreenOffs[2]]
      rendObj = ROBJ_9RECT
      texOffs = bgTexOffs
      screenOffs = bgScreenOffs
      image = Picture(gmEventPresentation(openedTreeEventId.get()).bgMapImage)
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      padding = bgScreenOffs
      children = mapContainer
    }
    @() {
      watch = [isSubPresetOpened, isShowSubPresetAllowed]
      size = flex()
      padding = saBordersRv
      children = isSubPresetOpened.get() && isShowSubPresetAllowed.get() ? subPresetContainer : null
    }
    {
      size = flex()
      padding = saBordersRv
      flow = FLOW_VERTICAL
      children = [
        eventGamercard
        { size = flex() }
        footer
      ]
    }
    @() {
      watch = selectedPointId
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = selectedPointId.get() != null ? mkQuestInfoWnd(selectedPointId.get()) : null
    }
  ]
  animations = wndSwitchAnim
}

registerScene("treeEventWnd", treeEventWnd, closeTreeEventWnd, isTreeEventWndOpened)
