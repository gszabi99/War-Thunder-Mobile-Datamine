from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { curCampaignUnseenBranches } = require("%rGui/unitsTree/unseenBranches.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature } = require("%rGui/components/unseenMark.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { unseenResearchedUnits, currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")

let hasUnseen = Computed(@() unseenUnits.get().len() > 0
  || unseenSkins.get().len() > 0
  || unseenResearchedUnits.get().len() > 0
  || unseenUnitLvlRewardsList.get().len() > 0)
let discount = Computed(@() unitDiscounts.get().reduce(@(res, val) max(val.discount, res), 0.0))

let unseenMarkOvr = { pos = [hdpx(4), -hdpx(4)], hplace = ALIGN_RIGHT }

function discountTagUnitTree(dis) {
  let height = hdpxi(38)
  let markTexOffs = [ 0, height / 2, 0, 0 ]
  let discountPrc = (dis * 100 + 0.5).tointeger()
  return @(sf) discountPrc <= 0 || discountPrc >= 100 ? null : {
    size = [SIZE_TO_CONTENT, height]
    rendObj = ROBJ_9RECT
    image = Picture($"ui/gameuiskin#tag_popular.svg:{height}:{height}:P")
    keepAspect = KEEP_ASPECT_NONE
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
      pos = [0, hdpx(3)]
    }.__update(fontTiny)
  }
}

return @(){
  watch = [hasUnseen, discount, curCampaignUnseenBranches, currentResearch]
  children = [
    translucentButton("ui/gameuiskin#icon_tree.svg",
      "",
      function() {
        openUnitsTreeWnd()
        openLvlUpWndIfCan()
      },
      discountTagUnitTree(discount.get())
    )
    curCampaignUnseenBranches.get().len() > 0 && currentResearch.get() != null
      ? priorityUnseenMarkFeature.__update(unseenMarkOvr)
      : mkPriorityUnseenMarkWatch(hasUnseen, unseenMarkOvr)
  ]
}
