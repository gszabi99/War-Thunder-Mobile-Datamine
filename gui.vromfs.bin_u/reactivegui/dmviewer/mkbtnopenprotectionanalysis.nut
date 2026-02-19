from "%globalsDarg/darg_library.nut" import *

let { utf8ToUpper } = require("%sqstd/string.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { mkCustomButton, buttonStyles, mergeStyles, buttonTextWidth, paddingX } = require("%rGui/components/textButton.nut")
let { isProtectionAnalysisAvailable, openProtectionAnalysis } = require("%rGui/dmViewer/protectionAnalysisState.nut")
let { hasHangarUnitResources } = require("%rGui/unit/hangarUnit.nut")


let iconSize = hdpxi(60)
let contentGap = hdpx(20)

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
    }.__update(fontTinyAccentedShadedBold)
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
