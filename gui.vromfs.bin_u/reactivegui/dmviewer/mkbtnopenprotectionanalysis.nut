from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/components/textButton.nut" import mkCustomButton, buttonStyles, mergeStyles, buttonTextWidth, paddingX
from "%rGui/dmViewer/protectionAnalysisState.nut" import isProtectionAnalysisAvailable, openProtectionAnalysis
from "%rGui/unit/hangarUnit.nut" import hasHangarUnitResources


const iconSize = hdpxi(60)
const contentGap = hdpx(20)

let mkBtnContent = @(contentOvr = {}) {
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = contentGap
  children = [
    {
      size = iconSize
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"ui/gameuiskin#icon_armor_analysis.svg:{iconSize}:{iconSize}:P")
    }
    {
      size = [contentOvr?.width != null
        ? contentOvr.width - (paddingX * 2 + contentGap + iconSize)
        : buttonTextWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = utf8ToUpper(loc("mainmenu/btnProtectionAnalysis"))
    }.__update(fontBoldTinyAccentedShaded)
  ]
}

let mkBtnOpenProtectionAnalysis = @(unitToShowW, baseUnitW, ovr = {}) @() {
  watch = [isProtectionAnalysisAvailable, hasHangarUnitResources, unitToShowW, baseUnitW]
  children = !isProtectionAnalysisAvailable.get() || !hasHangarUnitResources.get()
      || getCampaignPresentation(unitToShowW.get()?.campaign ?? "").campaign != "tanks"
    ? null
    : mkCustomButton(mkBtnContent(ovr?.contentOvr),
        @() openProtectionAnalysis(unitToShowW.get(), baseUnitW.get()),
        mergeStyles(buttonStyles.COMMON, ovr))
}

return mkBtnOpenProtectionAnalysis
