from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import deferOnce, resetTimeout
from "%appGlobals/pServer/campaign.nut" import receivedSchRewards, abTests
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEsc
from "%rGui/gameModes/newbieOfflineMissions.nut" import hasFirstBattleRewards
from "%rGui/mainMenu/mainMenuState.nut" import isMainMenuAttached
from "%rGui/shop/schRewardsState.nut" import onSchRewardReceive
from "%rGui/shop/shopCommon.nut" import shopCategoriesCfg
from "%rGui/shop/shopState.nut" import openShopWnd, getGoodsShopId, isShopAttached, actualSchRewardByCategory,
  onTabChange, closeShopWnd
from "%rGui/tutorial/completedTutorials.nut" import markTutorialCompleted, mkIsTutorialCompleted
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_SHOP_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId


let logT = log_with_prefix("[TUTOR_SHOP] ")

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isFinished = mkIsTutorialCompleted(TUTORIAL_SHOP_ID)

let orderByCategory = shopCategoriesCfg.reduce(@(res, c, i) res.$rawset(c.id, i + 1), {})

let hasPriority = @(a, b) (orderByCategory?[a] ?? -1) < (orderByCategory?[b] ?? orderByCategory.len())
let isRewardFit = @(r) r.isReady && !r.needAdvert && getGoodsShopId(r) == "common"

let hasReceivedAnySchReward = Computed(@() null != receivedSchRewards.get().findvalue(@(v) v > 0))
let needShowTutorial = Computed(@() !isFinished.get()
  && !hasReceivedAnySchReward.get()
  && !hasFirstBattleRewards.get()
  && null != actualSchRewardByCategory.get().findvalue(isRewardFit))
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get()
  && (abTests.get()?.hasSpendTutorials ?? "false") == "true")
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_SHOP_ID
  && !(isMainMenuAttached.get() || isShopAttached.get())))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function startTutorial() {
  let wndShowEnough = Watched(false)
  let category = actualSchRewardByCategory.get().reduce(
    @(res, r, cat) isRewardFit(r) && hasPriority(cat, res) ? cat : res,
    null)
  let schReward = actualSchRewardByCategory.get()[category]
  setTutorialConfig({
    id = TUTORIAL_SHOP_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_SHOP_ID)
    }
    steps = [
      {
        id = "s1_start_tutorial"
        hasNextKey = true
        text = loc("tutorial/shop/start")
        charId = "mary_like"
      }
      {
        id = "s2_press_shop_wnd_btn"
        objects = [{
          keys = "shop_btn"
          onClick = openShopWnd
          needArrow = true
        }]
        text = loc("tutorial/shop/openShop")
      }
      {
        id = "s3_open_shop_wnd"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s4_open_shop_tab"
        beforeStart = @() wndShowEnough.set(false)
        objects = [{
          keys = $"shop_tab_{category}"
          onClick = @() onTabChange(category)
          needArrow = true
        }]
        text = loc("tutorial/shop/openTab")
      }
      {
        id = "s5_move_to_sch_reward"
        beforeStart = @() resetTimeout(0.5, @() wndShowEnough.set(true))
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s6_press_sch_reward"
        objects = [{
          keys = $"shop_card_{schReward.id}"
          onClick = @() onSchRewardReceive(schReward)
          needArrow = true
        }]
        text = loc("tutorial/shop/getReward")
      }
      {
        id = "s7_press_back"
        objects = [{
          keys = "backButton"
          sizeIncAdd = hdpx(20)
          needArrow = true
          onClick = @() closeShopWnd()
          hotkeys = [btnBEsc]
        }]
        text = loc("tutorial/shop/backToMenu")
      }
      {
        id = "s8_finish_tutorial"
        hasNextKey = true
        charId = "mary_like"
        text = loc("tutorial/shop/finish")
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.get())
    return
  startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(
  function() {
    if (activeTutorialId.get() == TUTORIAL_SHOP_ID)
      return finishTutorial()
    if (null == actualSchRewardByCategory.get().findvalue(isRewardFit))
      console_print("Unable to start tutorial, because of no available sch rewards") 
    else
      isDebugMode.set(true)
  },
  "debug.tutorial_shop")