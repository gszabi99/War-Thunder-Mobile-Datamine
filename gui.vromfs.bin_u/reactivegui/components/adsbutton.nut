from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { apply_last_battle_ad_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { battleAdsBonusesCfg, isAdsAvailable, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { iconTextButton } = require("%rGui/components/textButton.nut")
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

let mkAdsButton = @(debrData) @() {
  watch = [hasVip, isAdsAvailable, adBudget]
  children = (debrData?.reward.playerWp.totalWp ?? 0) == 0 || debrData?.adsBonuses || !isAdsAvailable.get() || adBudget.get() <= 0
      || debrData?.predefinedReward != null || !debrData?.sessionId
    ? null
    : {
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
            hasVip.get() ? "ui/gameuiskin#gamercard_subs_vip.avif"
              : "ui/gameuiskin#watch_ads.svg",
            utf8ToUpper(loc("debriefing/improveReward"))
            @() hasVip.get() ? apply_last_battle_ad_reward(debrData.sessionId, { id = "debriefing.adShowed", sessionId = debrData.sessionId })
              : showAdsForReward({
                  bqId = "after_battle",
                  bqParams = { details = debrData?.campaign ?? "" },
                  cost = 1,
                  sessionId = debrData?.sessionId,
                }),
            { ovr = { size = [hdpx(400), hdpxi(109)]} })
        ]
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
