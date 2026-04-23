from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { apply_last_battle_ad_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { battleAdsBonusesCfg, isAdsAvailable, showAdsForReward, isProviderInited } = require("%rGui/ads/adsState.nut")
let { SECONDARY, COMMON } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { iconTextButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let adBudget = require("%rGui/ads/adBudget.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")


let bonusIconSize = hdpxi(35)
let bonusIconShift = hdpx(25)

let adsBonuses = Computed(function() {
  let res = {}
  foreach(k, v in battleAdsBonusesCfg.get()) {
    let percent = (v * 100).tostring()
    res[percent] <- (res?[percent] ?? [])
      .extend(k != "addExpMul" ? [k] : ["bonusPlayerExp", "bonusUnitExp", "slotExpMul"])
  }
  return res
})

let mkIconCtor = @(icon) @(offset) mkCurrencyImage(icon, bonusIconSize, {pos = [bonusIconShift * offset, 0]})

let bonusIconCfg = {
  bonusPlayerExp = {
    mkIcon = mkIconCtor("playerExp")
  }
  bonusUnitExp = {
    mkIcon = mkIconCtor("unitExp")
  }
  slotExpMul = {
    mkIcon = mkIconCtor("slotExp")
  }
  addWpMul = {
    mkIcon = mkIconCtor("wp")
  }
  addGoldMul = {
    mkIcon = mkIconCtor("gold")
  }
}

function mkBonusesText(debrData, adBonuses) {
  let res = []
  foreach (percent, bonuses in adBonuses)
    res.append({
      flow = FLOW_HORIZONTAL
      children = [
        {
          rendObj = ROBJ_TEXT
          text = $"{percent}%"
        }.__update(fontTinyAccented)
        {
          size = [(bonuses.len() * bonusIconSize) - (bonuses.len() - 1) * (bonusIconSize - bonusIconShift), SIZE_TO_CONTENT]
          children = bonuses.filter(@(b) debrData?.campaign != "ships_new" || b != "slotExpMul").map(@(b, i) bonusIconCfg[b].mkIcon(i))
        }
      ]
    })
  return res
}

function onNotInitedProviderClick() {
  openMsgBox({ text = loc("shop/notAvailableAds") })
  sendErrorLocIdBqEvent("shop/notAvailableAds")
}

function mkAdsButton(debrData) {
  let { reward = null, predefinedReward = null, sessionId = null, campaign = "" } = debrData
  let { totalWp = 0 } = reward?.playerWp
  if (totalWp == 0 || debrData?.adsBonuses || predefinedReward != null || sessionId == null)
    return null
  let hasAdBudget = Computed(@() adBudget.get() > 0)
  return @() !isAdsAvailable.get() ? { watch = isAdsAvailable }
    : {
        watch = [hasVip, isAdsAvailable, hasAdBudget, isProviderInited]
        children = {
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = hdpx(5)
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("debriefing/improveReward")
            }.__update(fontTinyAccented)
            @() {
              watch = adsBonuses
              flow = FLOW_HORIZONTAL
              children = mkBonusesText(debrData, adsBonuses.get())
            }
            iconTextButton(
              hasVip.get() ? "ui/gameuiskin#gamercard_subs_vip.avif" : "ui/gameuiskin#watch_ads.svg",
              utf8ToUpper(hasAdBudget.get() ? loc("debriefing/improveReward") : loc("btn/adsLimitReached")),
              @() !hasAdBudget.get() ? openMsgBox({ text = loc("msg/adsLimitReached") })
                : hasVip.get() ? apply_last_battle_ad_reward(sessionId, { id = "debriefing.adShowed", sessionId })
                : !isProviderInited.get() ? onNotInitedProviderClick()
                : showAdsForReward({
                    bqId = "after_battle",
                    bqParams = { details = campaign },
                    cost = 1,
                    sessionId,
                  }),
              mergeStyles(hasAdBudget.get() && isProviderInited.get() ? SECONDARY : COMMON,
                { ovr = { size = [hdpx(400), hdpxi(109)]} }))
          ]
        }
  }
}

eventbus_subscribe("adsShowFinish", function(data) {
  if (data?.sessionId != null) {
    apply_last_battle_ad_reward(data.sessionId, {
      id = "debriefing.adShowed",
      sessionId = data.sessionId
    })
  }
})

registerHandler("debriefing.adShowed", function(res, context) {
  let sessionId = context?.sessionId
  if (!sessionId)
    return

  let battle = res?.lastBattles[sessionId.tostring()]
  if (res?.error == null && battle && debriefingData.get().sessionId == sessionId)
    eventbus_send("adsBonusToApply",
      {
        goldDif = res?.unseenPurchases.findvalue(@(_) true).goods.findvalue(@(g) g.id == "gold").count ?? 0
        wpDif = res?.unseenPurchases.findvalue(@(_) true).goods.findvalue(@(g) g.id == "wp").count ?? 0
        expDif = battle.playerExp - debriefingData.get().reward.playerExp.totalExp
        unitsDif = battle.unitsProgress.map(function(unit, uName) {
          let debrUnit = debriefingData.get().reward.units.findvalue(@(u) u.name == uName)
          return unit.__merge({
            expDif = unit.exp - (debrUnit?.exp.totalExp ?? 0)
            slotExpDif = unit.slotExp - (debrUnit?.slotExp.totalExp ?? 0)
            goldDif = unit.gold - (debrUnit?.gold.totalGold ?? 0)
        })})
      })
})

return { mkAdsButton }
