from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/activeControls.nut" import needCursorForActiveInputDevice
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/cursor.nut" import needShowCursor, cursor
from "%rGui/navState.nut" import registerScene
from "%rGui/mainMenu/gamercard.nut" import mkLeftBlockUnitCampaign
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonBattle
from "%rGui/dmViewer/protectionAnalysisState.nut" import inspectedBaseUnit, isSimulationMode,
  isHintVisible, doFire
import "%rGui/dmViewer/protectionAnalysisControl.nut" as protectionAnalysisControl
import "%rGui/dmViewer/protectionAnalysisCrosshair.nut" as protectionAnalysisCrosshair
from "%rGui/dmViewer/protectionAnalysisHint.nut" import strTitle, strAngle, strHeadingAngle,
  strPenetratedArmor, strRicochetProb, strParts

let hintContentMaxWidth = hdpx(400)

let close = @() isSimulationMode.set(false)

let sceneHeader = @() {
  watch = [inspectedBaseUnit, needShowCursor]
  children = mkLeftBlockUnitCampaign(
    close,
    getCampaignPresentation(inspectedBaseUnit.get()?.campaign).levelUnitDetailsLocId,
    inspectedBaseUnit,
    needShowCursor.get() ? { cursor } : {})
}

let mkHintStr = @(watch, ovr = {}) @() {
  watch
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = watch.get()
  maxWidth = hintContentMaxWidth
}.__update(fontVeryTiny, ovr)

let hintComp = @() !isHintVisible.get() ? { watch = isHintVisible } : panelBg.__merge({
  watch = isHintVisible
  children = [
    mkHintStr(strTitle, { margin = [0, 0, hdpx(24), 0], maxWidth = null }.__update(fontSmall))
    mkHintStr(strAngle)
    mkHintStr(strHeadingAngle)
    mkHintStr(strPenetratedArmor)
    mkHintStr(strRicochetProb)
    mkHintStr(strParts, { margin = [hdpx(24), 0, 0, 0] })
  ]
})

let fireBtn = @() !isHintVisible.get() ? { watch = isHintVisible } : {
  watch = [isHintVisible, needShowCursor]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  cursor = needShowCursor.get() ? cursor : null
  children = textButtonBattle(utf8ToUpper(loc("hints/duel_battle_fire")),
    doFire, { hotkeys = ["^J:RT | Enter"] })
}

let mkScene = @() {
  key = {}
  size = flex()
  animations = wndSwitchAnim
  children = [
    protectionAnalysisControl
    protectionAnalysisCrosshair
    {
      size = flex()
      margin = saBordersRv
      flow = FLOW_VERTICAL
      gap = hdpx(24)
      children = [
        sceneHeader
        {
          size = flex()
          children = [
            hintComp
            fireBtn
          ]
        }
      ]
    }
  ]
}

registerScene("protAnalysisSimulationWnd", mkScene, close, isSimulationMode)
