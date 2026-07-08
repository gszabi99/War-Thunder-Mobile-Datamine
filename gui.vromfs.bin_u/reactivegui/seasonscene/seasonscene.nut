from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { seasonSceneOpenCounter, seasonTabs, seasonTabIdx, seasonPageId,
  PASS_SCENE, QUESTS_TAB, LOOTBOX_TAB, openSeasonTab, closeSeasonScene, bgScene, registerSeasonTabClose
} = require("seasonSceneState.nut")
let { passSceneWnd } = require("%rGui/battlePass/passScene.nut")
let { visibleTabs, BATTLE_PASS, playerSelectedScene, closePassScene } = require("%rGui/battlePass/passState.nut")
let { isCurEventActive, curEventLootboxes, closeEventWnd,
  closeEventShellCleanup, shouldShowEventMechanics
} = require("%rGui/event/eventState.nut")
let { eventbus_send } = require("eventbus")
let questsTabs = require("%rGui/quests/questsWnd.nut")
let { curTabId, questsCfg, questsBySection, ACHIEVEMENTS_TAB } = require("%rGui/quests/questsState.nut")
let { contentWidth, contentWidthFull, tabW, minContentOffset } = require("%rGui/options/optionsStyle.nut")
let { selLineSize } = require("%rGui/components/selectedLine.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let mkOptionsTabs = require("%rGui/options/mkOptionsTabs.nut")
let mkChildrenOptions = require("%rGui/options/mkChildrenOptions.nut")
let eventWnd = require("%rGui/event/eventWnd.nut")
let seasonHeader = require("%rGui/seasonScene/seasonHeader.nut")
let { isEventWndLootboxOpen, closeEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { registerUnlocksSceneToUpdate } = require("%rGui/unlocks/userstat.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { contentH } = require("%rGui/battlePass/battlePassPkg.nut")

let mkTabsVerticalPannableArea = verticalPannableAreaCtor(sh(100) - hdpx(180), [hdpx(30), saBorders[1]])

let iconSize = hdpxi(60)
let bottomPanelH = saBorders[1] + iconSize
let tabHighlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 10, 30, 31,-22))

let tabsConfig = {
  [PASS_SCENE] = {
    content = @() passSceneWnd
    icon = "ui/gameuiskin#icon_bp.svg"
    label = "pass"
    isVisible = Computed(@() shouldShowEventMechanics.get() && visibleTabs.get().len() > 0)
    defaultSubId = Computed(@() visibleTabs.get().len() > 0 ? visibleTabs.get()?[0] : BATTLE_PASS)
    onTabClose = closePassScene
  },
  [QUESTS_TAB] = {
    function content() {
      function findTabIdxById(pageId) {
        if (pageId != null) {
          let idxById = questsTabs.findindex(@(v) v?.id == pageId)
          if (idxById != null && (questsTabs[idxById]?.isVisible.get() ?? true))
            return idxById
          return questsTabs.findindex(@(v) v?.id == ACHIEVEMENTS_TAB)
        }

        return questsTabs.findindex(@(v) (v?.isVisible.get() ?? true)) ?? 0
      }
      let curTabIdx = Watched(findTabIdxById(curTabId.get()))
      let scrollHandler = ScrollHandler()

      function setTabById(id) {
        local idx = findTabIdxById(id)
        if (idx != null && (questsTabs[idx]?.isVisible.get() ?? true))
          curTabIdx.set(idx)
      }

      function curOptionsContent() {
        let tab = questsTabs?[curTabIdx.get()]
        let { isFullWidth = false } = tab
        return (tab?.content ?? tab?.contentCtor)
          ? {
              watch = curTabIdx
              size = [isFullWidth ? contentWidthFull : contentWidth, contentH]
              children = {
                hplace = ALIGN_CENTER
                key = tab
                size = [FLEX, contentH]
                flow = FLOW_VERTICAL
                children = tab?.content ?? tab?.contentCtor()
                animations = wndSwitchAnim
              }
            }
          : {
              watch = curTabIdx
              size = FLEX
              children = tab?.children ? mkChildrenOptions(tab?.children) : { size = FLEX }
            }
      }

      let tabsList = mkTabsVerticalPannableArea(
        mkOptionsTabs(questsTabs, curTabIdx),
          { size = [ tabW + minContentOffset, contentH ] },
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })

      return {
        pos = [-selLineSize, 0]
        key = setTabById
        onAttach = @() curTabId.subscribe(setTabById)
        onDetach = @() curTabId.unsubscribe(setTabById)
        size = [FLEX, contentH]
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = [
          tabsList
          curOptionsContent
        ]
      }
    }
    icon = "ui/gameuiskin#quests.svg"
    isVisible = Computed(function() {
      foreach (sections in questsCfg.get())
        if (sections.findindex(@(s) questsBySection.get()[s].len() > 0) != null)
          return true
      return false
    })
    label = "tasks"
    function onTabClose() {
      closeEventShellCleanup()
      closeEventWnd()
      eventbus_send("seasonSceneClosed", { tab = QUESTS_TAB })
    }
  },
  [LOOTBOX_TAB] = {
    content = @() eventWnd
    icon = "ui/gameuiskin#events_chest_icon.svg"
    label = "trophies"
    isVisible = Computed(@() shouldShowEventMechanics.get() && isCurEventActive.get() && curEventLootboxes.get().len() > 0)
    function onTabClose() {
      closeEventShellCleanup()
      closeEventWnd()
      eventbus_send("seasonSceneClosed", { tab = LOOTBOX_TAB })
    }
  },
}

let getTabConfig = @(tabName) tabsConfig?[tabName]


foreach (tabName, cfg in tabsConfig)
  if (cfg?.onTabClose != null)
    registerSeasonTabClose(tabName, cfg.onTabClose)

seasonSceneOpenCounter.subscribe(function(v) {
  if (v > 0 && seasonPageId.get() == PASS_SCENE) {
    let def = getTabConfig(PASS_SCENE)?.defaultSubId
    if (def != null)
      playerSelectedScene.set(def.get ? def.get() : def)
  }
})

function mkSeasonTab(tabName, tabConfig, isActive) {
  let icon = tabConfig?.icon ?? $"season_tab_{tabName}"
  return @() {
    watch = isActive
    size = FLEX_V
    rendObj = ROBJ_IMAGE
    image = tabHighlight()
    behavior = Behaviors.Button
    onClick = @() openSeasonTab(tabName)
    color = isActive.get() ? selectColor : 0
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    padding = [hdpx(10), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      {
        size = iconSize
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{iconSize}:P")
        keepAspect = true
      }
      {
        rendObj = ROBJ_TEXT
        text = loc(tabConfig?.label ?? tabName)
      }.__update(fontSmallShaded)
    ]
  }
}

let tabGap = { size = flex(), maxWidth = hdpx(300) }
function addTabGaps(children) {
  let res = [tabGap]
  foreach (c in children)
    res.append(c, tabGap)
  return res
}

let seasonTabsBlock = @() {
  watch = seasonTabs.map(@(t) tabsConfig?[t].isVisible)
    .filter(@(w) w != null)
  size = [FLEX, bottomPanelH]
  rendObj = ROBJ_SOLID
  color = 0xDD22262E
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = addTabGaps(seasonTabs
    .map(@(t, idx) !tabsConfig?[t].isVisible.get() ? null
      : mkSeasonTab(t, tabsConfig[t], Computed(@() seasonTabIdx.get() == idx)))
    .filter(@(c) c != null))
}

function seasonScene() {
  if (seasonTabs.len == 0)
    return { watch = seasonPageId }

  let tabConfig = getTabConfig(seasonPageId.get())
  if (!tabConfig)
    return {
      watch = seasonPageId
      padding = saBordersRv
      children = backButton(closeSeasonScene)
    }

  let { content } = tabConfig

  return {
    watch = seasonPageId
    size = FLEX
    flow = FLOW_VERTICAL
    children = [
      {
        size = [FLEX, SIZE_TO_CONTENT]
        padding = [saBordersRv[0], saBordersRv[1], hdpx(50), saBordersRv[1]]
        children = seasonHeader(function() {
          if (isEventWndLootboxOpen.get())
            closeEventWndLootbox()
          else
            closeSeasonScene()
        })
      }
      {
        size = FLEX
        children = content()
      }
      {
        rendObj = ROBJ_SOLID
        color = selectColor
        size = [FLEX, hdpx(4)]
      }
      seasonTabsBlock
    ]
    animations = wndSwitchAnim
  }
}

let sceneId = "seasonScene"
registerScene(sceneId, seasonScene, closeSeasonScene, seasonSceneOpenCounter)
setSceneBg(sceneId, bgScene.get()?.bg, bgScene.get()?.bgColor)
bgScene.subscribe(@(v) setSceneBg(sceneId, v?.bg, v?.bgColor))
registerUnlocksSceneToUpdate(sceneId)
