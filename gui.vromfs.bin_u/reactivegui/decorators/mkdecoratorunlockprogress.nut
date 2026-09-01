from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_DECORATOR
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonInactive, textButtonPrimary
from "%rGui/quests/bqQuests.nut" import sendBqQuestsTask
from "%rGui/quests/questBar.nut" import mkQuestBar
from "%rGui/quests/questsState.nut" import questsBySection, questsCfg, getStarsTotalNonUpdatable
from "%rGui/rewards/unlockRewards.nut" import findUnlockWithReward
from "%rGui/unlocks/unlocks.nut" import activeUnlocks, unlockInProgress, receiveUnlockRewards


let btnStyleSound = { ovr = { sound = { click  = "meta_get_unlock" } } }

function receiveReward(unlock) {
  receiveUnlockRewards(unlock.name, 1, { stage = 1 })
  sendBqQuestsTask(unlock, getStarsTotalNonUpdatable(unlock), 0, null)
}

function mkReceiveButton(unlock) {
  let { name } = unlock
  let isRewardInProgress = Computed(@() name in unlockInProgress.get())
  local children = []

  if (unlock?.hasReward)
    children = textButtonPrimary(
      utf8ToUpper(loc("btn/receive")),
      @() receiveReward(unlock),
      btnStyleSound)
  else {
    children = textButtonInactive(
      utf8ToUpper(loc("btn/receive")),
      @() anim_start($"unfilledBarEffect_{name}"))
  }
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkSpinnerHideBlock(isRewardInProgress, children)
  }
}

let mkDecoratorUnlockProgress = @(decName) function() {
  let unlockByDecorator = findUnlockWithReward(activeUnlocks.get(), serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == G_DECORATOR && g.id == decName)))

  local unlock = null
  if (unlockByDecorator != null) {
    local sectionName = ""
    foreach (k, v in questsBySection.get())
      if(unlockByDecorator.name in v) {
        sectionName = k
        break
      }
    let tabId = questsCfg.get().findindex(@(v) v.contains(sectionName))
    unlock = unlockByDecorator.__merge({ tabId })
  }

  return unlock == null
    ? {
      watch = [activeUnlocks, serverConfigs, questsCfg]
      children = {
        rendObj = ROBJ_TEXT
        text = loc("decor/decorNotAvailable")
      }.__update(fontTinyAccented)
    }
    : {
        watch = [activeUnlocks, serverConfigs, questsCfg]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_BOTTOM
        gap = hdpx(20)
        children = [
          mkReceiveButton(unlock)
          {
            size = [SIZE_TO_CONTENT, defButtonHeight]
            flow = FLOW_VERTICAL
            valign = ALIGN_BOTTOM
            gap = hdpx(15)
            children = [
              {
                size = const [hdpx(500), SIZE_TO_CONTENT]
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                text = loc($"{unlock.name}/desc")
              }.__update(fontTinyAccented)
              mkQuestBar(unlock)
            ]
          }
        ]
    }
}

return {
  mkDecoratorUnlockProgress
}