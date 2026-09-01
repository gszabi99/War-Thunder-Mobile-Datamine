from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/unitPresentation.nut" import getUnitName
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textButton.nut" import textButtonBattle
from "%rGui/cursor.nut" import needShowCursor, cursor
import "%rGui/dmViewer/protectionAnalysisControl.nut" as protectionAnalysisControl
import "%rGui/dmViewer/protectionAnalysisCrosshair.nut" as protectionAnalysisCrosshair
from "%rGui/dmViewer/protectionAnalysisHint.nut" import strTitle, strAngle, strHeadingAngle, strPenetratedArmor,
  strRicochetProb, strParts
from "%rGui/dmViewer/protectionAnalysisState.nut" import inspectedBaseUnit, isSimulationMode, threatUnit,
  threatBulletData, fireDistance, isHintVisible, doFire
from "%rGui/mainMenu/gamercard.nut" import mkLeftBlockUnitCampaign
from "%rGui/navState.nut" import registerScene
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/weaponry/weaponsVisual.nut" import getAmmoNameShortText


const hintContentMaxWidth = hdpx(400)

let close = @() isSimulationMode.set(false)

let sceneHeader = @() {
  watch = [inspectedBaseUnit, needShowCursor]
  children = mkLeftBlockUnitCampaign(
    close,
    getCampaignPresentation(inspectedBaseUnit.get()?.campaign).levelUnitDetailsLocId,
    inspectedBaseUnit,
    needShowCursor.get() ? { cursor } : {})
}

let mkInfoStr = @(watch, toStr, ovr = {}) @() {
  watch
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  text = toStr(watch?.get())
}.__update(fontSmallShaded, ovr)

let threatInfoComp = {
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    mkInfoStr(null, @(_) loc("protection_analysis/attacker"),
      { margin = const [0, 0, hdpx(24), 0] }.__update(fontTinyAccentedShaded))
    mkInfoStr(threatUnit, @(v) getUnitName(v?.name ?? ""))
    mkInfoStr(threatBulletData, @(v) getAmmoNameShortText(v?.bSet))
    mkInfoStr(fireDistance, @(v) " ".concat(v, loc("measureUnits/meters_alt")))
  ]
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
    mkHintStr(strTitle, { margin = const [0, 0, hdpx(24), 0], maxWidth = null }.__update(fontSmall))
    mkHintStr(strAngle)
    mkHintStr(strHeadingAngle)
    mkHintStr(strPenetratedArmor)
    mkHintStr(strRicochetProb)
    mkHintStr(strParts, { margin = const [hdpx(24), 0, 0, 0] })
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
  size = FLEX
  animations = wndSwitchAnim
  children = [
    protectionAnalysisControl
    protectionAnalysisCrosshair
    {
      size = FLEX
      margin = saBordersRv
      flow = FLOW_VERTICAL
      gap = hdpx(24)
      children = [
        sceneHeader
        {
          size = FLEX
          children = [
            threatInfoComp
            hintComp
            fireBtn
          ]
        }
      ]
    }
  ]
}

registerScene("protAnalysisSimulationWnd", mkScene, close, isSimulationMode)
