from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { headerGradientBg } = require("%rGui/components/gradientDefComps.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { seasonSceneOpenCounter, seasonTabs, seasonTabIdx, seasonPageId,
  PASS_SCENE, openSeasonTab, closeSeasonScene, bgScene, registerSeasonTabClose
} = require("%rGui/seasonScene/seasonSceneState.nut")
let sceneContentCfg = require("%rGui/seasonScene/seasonSceneContentCfg.nut")
let { playerSelectedScene } = require("%rGui/battlePass/passState.nut")
let { registerUnlocksSceneToUpdate } = require("%rGui/unlocks/userstat.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { curEvent } = require("%rGui/event/eventState.nut")


let iconSize = hdpxi(60)
let bottomPanelH = saBorders[1] + iconSize
let tabHighlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 10, 27, 31,-22))


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
  let icon = tabConfig?.icon ?? $"season_tab_{tabName}"
  let isUnseen = tabConfig?.mkHasUnseen(curEvent)
  return {
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
          size = [hdpx(370), hdpx(120)]
          rendObj = ROBJ_IMAGE
          image = tabHighlight()
          color = isActive.get() ? selectColor : 0
        }
      }
      {
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
            children = isUnseen == null ? null
              : @() {
                  watch = [isUnseen, isActive]
                  pos = [pw(100), 0]
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

let mkHeaderChildren = @(seasonName, seasonEndTime) [
  @() {
    watch = seasonName
    rendObj = ROBJ_TEXT
    text = seasonName.get()
  }.__update(fontBig)
  @() {
    key = "battle_pass_time" 
    watch = [seasonEndTime, serverTime]
    rendObj = ROBJ_TEXT
    text = !seasonEndTime.get() || (seasonEndTime.get() - serverTime.get() < 0) ? null
      : loc("battlepass/endsin", { time = secondsToHoursLoc(seasonEndTime.get() - serverTime.get()) }  )
  }.__update(fontTinyAccented)
]

function headerCurrencies() {
  let { currencies = null } = sceneContentCfg?[seasonPageId.get()]
  return currencies == null ? { watch = seasonPageId }
    : {
        watch = [seasonPageId, currencies]
        children = mkCurrenciesBtns(currencies.get())
      }
}

let seasonHeader = {
  size = FLEX_H
  vplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    headerGradientBg([
      backButton(function() {
        if (!sceneContentCfg?[seasonPageId.get()].onBack())
          closeSeasonScene()
      })
      @() {
        watch = seasonPageId
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = hdpx(5)
        children = seasonPageId.get() not in sceneContentCfg ? null
          : mkHeaderChildren(sceneContentCfg[seasonPageId.get()].headerTitle,
              sceneContentCfg?[seasonPageId.get()].headerEndTime)
      }
    ])
    { size = FLEX }
    headerCurrencies
  ]
}

function seasonScene() {
  if (seasonTabs.len == 0)
    return { watch = seasonPageId }

  let tabConfig = sceneContentCfg?[seasonPageId.get()]
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
        children = seasonHeader
      }
      {
        size = FLEX
        children = content()
      }
      {
        rendObj = ROBJ_SOLID
        color = selectColor
        size = [FLEX, hdpx(8)]
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
