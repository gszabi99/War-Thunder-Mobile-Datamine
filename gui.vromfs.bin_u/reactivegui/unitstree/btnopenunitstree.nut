from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/translucentButton.nut" import translucentButton
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature
from "%rGui/unit/unitsDiscountState.nut" import unitDiscounts
from "%rGui/unit/unseenUnits.nut" import unseenUnits
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unseenResearchedUnits, currentResearch
from "%rGui/unitsTree/unitsTreeState.nut" import openUnitsTreeWnd
from "%rGui/unitsTree/unseenBranches.nut" import curCampaignUnseenBranches


let hasUnseen = Computed(@() unseenUnits.get().len() > 0
  || unseenResearchedUnits.get().len() > 0)
let discount = Computed(@() unitDiscounts.get().reduce(@(res, val) max(val.discount, res), 0.0))

let unseenMarkOvr = { pos = const [-hdpx(4), hdpx(4)], hplace = ALIGN_RIGHT }

function discountTagUnitTree(dis) {
  const height = hdpxi(38)
  let markTexOffs = [ 0, height / 2, 0, 0 ]
  let discountPrc = (dis * 100 + 0.5).tointeger()
  return @(sf) discountPrc <= 0 || discountPrc >= 100 ? null : {
    size = const [SIZE_TO_CONTENT, height]
    rendObj = ROBJ_9RECT
    image = Picture($"ui/gameuiskin#tag_popular.svg:{height}:{height}:P")
    screenOffs = markTexOffs
    texOffs = markTexOffs
    color = 0xFFD22A19
    transform = {
      scale = sf & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = {
      rendObj = ROBJ_TEXT
      text = $"-{round(discountPrc)}%"
      margin = const [0, hdpx(15), 0, hdpx(5)]
      pos = const [0, hdpx(3)]
    }.__update(fontTiny)
  }
}

return @() {
  watch = [hasUnseen, discount, curCampaignUnseenBranches, currentResearch]
  children = [
    translucentButton("ui/gameuiskin#icon_tree.svg",
      function() {
        openUnitsTreeWnd()
      },
      utf8ToUpper(loc("mainmenu/btnUnits")),
      discountTagUnitTree(discount.get()),
      { contentOvr = { gap = hdpx(-10)} }
    )
    curCampaignUnseenBranches.get().findvalue(@(v) v) && currentResearch.get() != null
      ? priorityUnseenMarkFeature.__merge(unseenMarkOvr)
      : mkPriorityUnseenMarkWatch(hasUnseen, unseenMarkOvr)
  ]
}
