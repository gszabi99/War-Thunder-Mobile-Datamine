from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { mkQuestBar } = require("%rGui/quests/questBar.nut")
let { findUnlockWithReward } = require("%rGui/rewards/unlockRewards.nut")
let { G_DECORATOR } = require("%appGlobals/rewardType.nut")

let mkDecoratorUnlockProgress = @(decName) function() {
  let unlockByDecorator = findUnlockWithReward(activeUnlocks.get(), serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == G_DECORATOR && g.id == decName)))
  return !unlockByDecorator
    ? {
      watch = [activeUnlocks, serverConfigs]
      children = {
        rendObj = ROBJ_TEXT
        text = loc("decor/decorNotAvailable")
      }.__update(fontTinyAccented)
    }
    : {
        watch = [activeUnlocks, serverConfigs]
        size = [hdpx(500), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = hdpx(10)
        valign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc($"{unlockByDecorator.name}/desc")
          }.__update(fontTinyAccented)
          mkQuestBar(unlockByDecorator)
        ]
    }
}

return {
  mkDecoratorUnlockProgress
}