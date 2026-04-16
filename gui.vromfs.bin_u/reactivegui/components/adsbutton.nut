from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { apply_last_battle_ad_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { battleAdsBonusesCfg, isAdsAvailable, showAdsForReward } = require("%rGui/ads/adsState.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { iconTextButton } = require("%rGui/components/textButton.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let adBudget = require("%rGui/ads/adBudget.nut")


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
      || debrData?.predefinedReward != null
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
            @() hasVip.get() ? apply_last_battle_ad_reward(debrData.sessionId, { id = "debriefing.adShowed", debrData })
              : showAdsForReward({ debrData = debrData }),
            { ovr = { size = [hdpx(400), hdpxi(109)]} })
        ]
      }
}

eventbus_subscribe("adsShowFinish", function(data) {
  if (data?.debrData.sessionId != null) {
    apply_last_battle_ad_reward(data?.debrData.sessionId, { id = "debriefing.adShowed", debrData = data.debrData })
  }
})

registerHandler("debriefing.adShowed", function(res, context) {
  let { debrData } = context
  let sessionId = debrData?.sessionId.tostring()
  if (res?.error == null && sessionId && res?.lastBattles[sessionId])
    eventbus_send("adsBonusToApply",
      {
        goldDif = res?.unseenPurchases.findvalue(@(_) true).goods.findvalue(@(g) g.id == "gold").count ?? 0
        wpDif = res?.unseenPurchases.findvalue(@(_) true).goods.findvalue(@(g) g.id == "wp").count ?? 0
        expDif = res.lastBattles[sessionId].playerExp - debrData.reward.playerExp.totalExp
        unitsDif = res.lastBattles[sessionId].unitsProgress.map(function(unit, uName) {
          let debrUnit = debrData.reward.units.findvalue(@(u) u.name == uName)
          return unit.__merge({
            expDif = unit.exp - (debrUnit?.exp.totalExp ?? 0)
            slotExpDif = unit.slotExp - (debrUnit?.slotExp.totalExp ?? 0)
            goldDif = unit.gold - (debrUnit?.gold.totalGold ?? 0)
        })})
      })
})

return { mkAdsButton }
