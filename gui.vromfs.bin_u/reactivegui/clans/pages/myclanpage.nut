from "%globalsDarg/darg_library.nut" import *
from "%rGui/clans/components/clanComps.nut" import clanScrollBarStyle
import "%rGui/clans/components/clanHeaderSection.nut" as mkClanHeaderSection
from "%rGui/clans/components/clanMembersSection.nut" import mkClanMembersSection, selectedMemberId
from "%rGui/clans/currentClanState.nut" import currentClan
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/style/gamercardStyle.nut" import gamercardHeight


return {
  size = FLEX
  behavior = Behaviors.Button
  onClick = @() selectedMemberId.set(null)
  children = makeVertScroll({
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_LEFT
    valign = ALIGN_TOP
    children = [
      mkClanHeaderSection(currentClan)
      mkClanMembersSection(currentClan)
    ]
  },
  {
    size = [FLEX, saSize[1] - (gamercardHeight + saBorders[1])]
    isBarOutside = true
    barStyleCtor = clanScrollBarStyle
  })
}
