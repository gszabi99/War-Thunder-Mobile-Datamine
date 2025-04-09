from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let logT = log_with_prefix("[EVENT_TUTOR] ")
let { TUTORIAL_TREE_EVENT } = require("tutorialConst.nut")
let { setTutorialConfig, isTutorialActive } = require("tutorialWnd/tutorialWndState.nut")
let { treeEventPresets, selectedElemId, curEventUnlocks, openedTreeEventId,
  getFirstOrCurSubPreset } = require("%rGui/event/treeEvent/treeEventState.nut")
let { getUnlockPrice, buyUnlock } = require("%rGui/unlocks/unlocks.nut")
let { getRewardsPreviewInfo, getEventCurrencyReward} = require("%rGui/quests/rewardsComps.nut")
let { exploreRewardMsgBox } = require("%rGui/quests/questsWndPage.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { closePurchaseAndBalanceBoxes } = require("%rGui/shop/msgBoxPurchase.nut")
let { markTutorialCompleted, isFinishedEvent } = require("completedTutorials.nut")

let canStartTutorial = Computed(@() openedTreeEventId.get()
  && treeEventPresets.get().len() > 0
  && !isFinishedEvent.get()
  && !isTutorialActive.get())

function startTutorial() {
  let id = getFirstOrCurSubPreset()
  if(!id)
    return
  let unlock = curEventUnlocks.get()?[id]
  let price = getUnlockPrice(unlock)
  let rewardsPreview = getRewardsPreviewInfo(unlock, serverConfigs.get())
  let eventCurrencyReward = getEventCurrencyReward(rewardsPreview)

  setTutorialConfig({
    id = TUTORIAL_TREE_EVENT
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_TREE_EVENT)
    }
    steps = [
      {
        id = "s1_event_tutor"
        text = loc("tutorial_april_event_start")
        objects = [{
          keys = id
          onClick = @() exploreRewardMsgBox(unlock, rewardsPreview, price.price, price.currency, eventCurrencyReward)
        }]
        charId = "mary_pirate"
      }
      {
        id = "s2_event_tutor"
        objects = [{
          keys = "purchase_tutor_btn"
          needArrow = true
          function onClick() {
            if(unlock?.name){
              buyUnlock(unlock.name, 1, price.currency, price.price,
                { onSuccessCb = { id = "quests.buyUnlock", item = unlock, currencyReward = eventCurrencyReward }})
              closePurchaseAndBalanceBoxes()
            }
          }
          hotkeys = ["^J:A"]
        }]
      }
      {
        id = "s3_event_tutor"
        objects = [{
          keys = id
          onClick = @() selectedElemId.set(id)
          needArrow = true
        }]
      }
      {
        id = "s4_event_tutor"
        text =  loc("tutorial_april_event_end")
        objects = [{ keys = "subPresetContainer" }]
        charId = "mary_pirate"
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!canStartTutorial.get())
    return
  startTutorial()
})

startTutorialDelayed()
canStartTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)