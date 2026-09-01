from "%globalsDarg/darg_library.nut" import *
from "wt.behaviors" import HangarCameraControl
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%rGui/battlePass/passPkg.nut" import bottomPanelH, bottomPanelIconSize
from "%rGui/battlePass/passState.nut" import playerSelectedScene
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/components/infoButton.nut" import infoEllipseButton
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/event/eventLocName.nut" import curEventLoc
from "%rGui/event/eventState.nut" import curEvent
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/news/newsState.nut" import openNewsWndTagged
import "%rGui/seasonScene/seasonSceneContentCfg.nut" as sceneContentCfg
from "%rGui/seasonScene/seasonSceneState.nut" import seasonSceneOpenCounter, seasonTabs, seasonTabIdx, seasonPageId,
  newsTag, PASS_SCENE, openSeasonTab, closeSeasonScene, bgScene, bgUnits, registerSeasonTabClose, isBattleTab
from "%rGui/style/gradients.nut" import mkGradientCtorRadial, gradTexSize
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/unit/hangarUnit.nut" import setHangarUnitGroup
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate
from "%rGui/updater/updaterState.nut" import registerAutoDownloadUnits, DLP_HIGH


let tabHighlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 10, 27, 31,-22))

let isWndAttached = Watched(false)
let chosenUnitIdx = Watched(null)
let bgSceneExt = keepref(Computed(@() bgUnits.get() == null ? bgScene.get() : { bg = "" }))

let unitsToSetInHangar = keepref(Computed(@() isWndAttached.get() ? bgUnits.get() : null))
unitsToSetInHangar.subscribe(@(v) v == null ? null
  : chosenUnitIdx.set(setHangarUnitGroup(v, chosenUnitIdx.get() == null, chosenUnitIdx.get())))
isMainMenuAttached.subscribe(@(v) v ? chosenUnitIdx.set(null) : null)
registerAutoDownloadUnits(Computed(@() (unitsToSetInHangar.get() ?? []).reduce(@(res, u) res.$rawset(u, true), {})),
  DLP_HIGH)


foreach (tabName, cfg in sceneContentCfg)
  if (cfg?.onTabClose != null)
    registerSeasonTabClose(tabName, cfg.onTabClose)

seasonSceneOpenCounter.subscribe(function(v) {
  if (v > 0 && seasonPageId.get() == PASS_SCENE) {
    let def = sceneContentCfg?[PASS_SCENE].defaultSubId
    if (def != null)
      playerSelectedScene.set(def.get ? def.get() : def)
  }
})

function mkSeasonTab(tabName, tabConfig, isActive) {
  let iconRaw = tabConfig?.icon ?? $"season_tab_{tabName}"
  let icon = iconRaw instanceof Watched ? iconRaw : Watched(iconRaw)
  let isUnseen = tabConfig?.mkHasUnseen(curEvent)
  return {
    key = tabConfig?.key
    size = FLEX_V
    behavior = Behaviors.Button
    onClick = @() openSeasonTab(tabName)
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    children = [
      {
        size = 0
        halign = ALIGN_CENTER
        children = @() {
          watch = isActive
          size = const [hdpx(370), hdpx(120)]
          rendObj = ROBJ_IMAGE
          image = tabHighlight()
          color = isActive.get() ? selectColor : 0
        }
      }
      {
        padding = const [hdpx(10), 0, 0, 0]
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          @() {
            watch = icon
            size = bottomPanelIconSize
            rendObj = ROBJ_IMAGE
            image = Picture($"{icon.get()}:{bottomPanelIconSize}:P")
            keepAspect = true
          }
          {
            rendObj = ROBJ_TEXT
            text = loc(tabConfig?.label ?? tabName)
            children = isUnseen == null ? null
              : @() {
                  watch = [isUnseen, isActive]
                  pos = const [pw(100), 0]
                  children = isUnseen.get() && !isActive.get() ? priorityUnseenMark : null
                }
          }.__update(fontSmallShaded)
        ]
      }
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
  watch = seasonTabs.map(@(t) sceneContentCfg?[t].isVisible)
    .filter(@(w) w != null)
  size = [FLEX, bottomPanelH]
  rendObj = ROBJ_SOLID
  color = 0xDD22262E
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = addTabGaps(seasonTabs
    .map(@(t, idx) !sceneContentCfg?[t].isVisible.get() ? null
      : mkSeasonTab(t, sceneContentCfg[t], Computed(@() seasonTabIdx.get() == idx)))
    .filter(@(c) c != null))
}

function headerRightBlock() {
  let { currencies = null, headerRightCtor = null } = sceneContentCfg?[seasonPageId.get()]
  return {
    watch = [ seasonPageId, currencies ].filter(@(v) v != null)
    size = FLEX
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = headerRightCtor != null ? headerRightCtor()
      : currencies != null ? mkCurrenciesBtns(currencies.get())
      : null
  }
}

let seasonHeader = headerGradientWithRightBlock(
  [
    backButton(function() {
      if (!sceneContentCfg?[seasonPageId.get()].onBack())
        closeSeasonScene()
    })
    @() {
      watch = newsTag
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        @() {
          watch = curEventLoc
          rendObj = ROBJ_TEXT
          text = curEventLoc.get()
        }.__update(fontBig)
        newsTag.get() == null ? null
          : infoEllipseButton(@() openNewsWndTagged(newsTag.get()))
      ]
    }
  ],
  headerRightBlock)

function seasonScene() {
  let tabConfig = sceneContentCfg?[seasonPageId.get()]
  if (!tabConfig)
    return {
      watch = seasonPageId
      padding = saBordersRv
      children = backButton(closeSeasonScene)
    }

  let { content, sceneShadeColor = null } = tabConfig

  return {
    watch = [seasonPageId, bgUnits]
    size = FLEX
    flow = FLOW_VERTICAL

    behavior = bgUnits.get() == null ? null : HangarCameraControl
    touchMarginPriority = TOUCH_BACKGROUND

    children = [
      {
        size = const [FLEX, SIZE_TO_CONTENT]
        padding = [saBordersRv[0], saBordersRv[1], 0, saBordersRv[1]]
        rendObj = sceneShadeColor != null ? ROBJ_SOLID : null
        color = sceneShadeColor
        children = seasonHeader
      }
      {
        key = isWndAttached
        onAttach = @() isWndAttached.set(true)
        onDetach = @() isWndAttached.set(false)
        size = FLEX
        children = content()
      }
      {
        rendObj = ROBJ_SOLID
        color = selectColor
        size = const [FLEX, hdpx(8)]
      }
      seasonTabsBlock
    ]
    animations = wndSwitchAnim
  }
}

const sceneId = "seasonScene"

registerScene(sceneId, seasonScene, closeSeasonScene, seasonSceneOpenCounter)
setSceneBg(sceneId, bgSceneExt.get()?.bg, isBattleTab.get() ? null : bgSceneExt.get()?.bgColor)
bgSceneExt.subscribe(@(v) setSceneBg(sceneId, v?.bg, isBattleTab.get() ? null : v?.bgColor))
isBattleTab.subscribe(@(v) setSceneBg(sceneId, bgSceneExt.get()?.bg, v ? null : bgSceneExt.get()?.bgColor))
registerUnlocksSceneToUpdate(sceneId)
