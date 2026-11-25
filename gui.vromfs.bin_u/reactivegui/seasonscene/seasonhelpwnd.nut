from "%globalsDarg/darg_library.nut" import *
import "%rGui/battlePass/bpHelpContent.nut" as bpHelpContent
import "%rGui/collections/collectionsHelpContent.nut" as collectionsHelpContent
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
import "%rGui/event/treeEvent/treeEventHelpContent.nut" as treeEventHelpContent
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/seasonScene/seasonSceneState.nut" import openedSeasonHelpWndId, closeSeasonHelpWnd,
  COLLECTION_TAB, PASS_SCENE, MAP_TAB
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const sceneId = "seasonHelpWnd"

let helpWndCfg = {
  [COLLECTION_TAB] = collectionsHelpContent,
  [PASS_SCENE] = bpHelpContent,
  [MAP_TAB] = treeEventHelpContent,
}

let hasSeasonHelpWnd = @(id) id in helpWndCfg

let isSeasonHelpWndOpened = helpWndCfg.reduce(function(isOpenedBefore, cfg, id) {
  let { isAvailable } = cfg
  return Computed(@() isOpenedBefore.get() || (openedSeasonHelpWndId.get() == id && isAvailable.get()))
}, Watched(false))

let header = headerGradientBg([
  backButton(closeSeasonHelpWnd)
  {
    rendObj = ROBJ_TEXT
    text = loc("HowToPlay")
    ...fontBig
  }
])

let sceneWnd = @() {
  watch = openedSeasonHelpWndId
  key = sceneId
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  onDetach = closeSeasonHelpWnd
  children = [
    header
    helpWndCfg?[openedSeasonHelpWndId.get()].content
  ]
  animations = wndSwitchAnim
}

function updateSceneBg() {
  let bg = helpWndCfg?[openedSeasonHelpWndId.get()].bg.get()
  setSceneBg(sceneId, bg?.bg, bg?.bgColor, bg?.dimColor)
}

registerScene(sceneId, sceneWnd, closeSeasonHelpWnd, isSeasonHelpWndOpened)
updateSceneBg()
openedSeasonHelpWndId.subscribe(@(_) updateSceneBg())
foreach (cfg in helpWndCfg)
  cfg.bg.subscribe(@(_) updateSceneBg())

return {
  hasSeasonHelpWnd
}
