from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import clanInfoInProgress
from "%rGui/clans/clanState.nut" import viewedClan, isClanInfoOpen, closeClanInfo
from "%rGui/clans/components/clanComps.nut" import clanScrollBarStyle
import "%rGui/clans/components/clanHeaderSection.nut" as mkClanHeaderSection
from "%rGui/clans/components/clanMembersSection.nut" import mkClanMembersSection, selectedMemberId
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let wndKey = {}

function clanInfoWnd() {
  let clanHeaderSection = mkClanHeaderSection(viewedClan)
  let clanMembersScroll = makeVertScroll(
    mkClanMembersSection(viewedClan),
    {
      size = FLEX
      isBarOutside = true
      barStyleCtor = clanScrollBarStyle
    })
  let spinner = mkSpinner(hdpx(100))

  return bgShaded.__merge({
    key = wndKey
    size = FLEX
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    padding = saBordersRv
    onClick = @() selectedMemberId.set(null)
    children = [
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = headerGradientBg(backButton(closeClanInfo))
      }
      @() {
        watch = [viewedClan, clanInfoInProgress]
        size = const [pw(80), FLEX]
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        children = viewedClan.get() != null
            ? [clanHeaderSection, clanMembersScroll]
          : clanInfoInProgress.get().len() > 0
            ? spinner
          : {
              rendObj = ROBJ_TEXT
              text = loc("clans/error/fetchFailed")
            }.__update(fontSmallShaded)
      }
    ]
    animations = wndSwitchAnim
  })
}

registerScene("clanInfoWnd", clanInfoWnd, closeClanInfo, isClanInfoOpen)
