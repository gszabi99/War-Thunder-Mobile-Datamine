from "%globalsDarg/darg_library.nut" import *
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { bgMessage, bgHeader } = require("%rGui/style/backgrounds.nut")
let { levelMark, defColor, hlColor, iconSize, mkText } = require("%rGui/mpStatistics/playerInfo.nut")
let { getMedalPresentation } = require("%rGui/mpStatistics/medalsPresentation.nut")
let { actualizeStats, userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { viewStats, mkStatRow, mkMarqueeRow, mkMarqueeText } = require("%rGui/mpStatistics/statRow.nut")

let playerStats = Computed( @() userstatStats.get()?.stats["global"])

let mkMedals = @(selCampaign) function() {
  let children = []
  let curr = servProfile.get()?.levelInfo[selCampaign] ?? {}
  foreach(v in curr?.starLevelHistory ?? [])
    children.append(levelMark(v.baseLevel, v.starLevel + 1))
  if ((curr?.starLevel ?? 0) > 0)
    children.append(levelMark(curr.level - curr.starLevel, curr.starLevel))

  foreach(medal in servProfile.get()?.medals ?? {}) {
    let { campaign = selCampaign, ctor } = getMedalPresentation(medal)
    if (campaign == selCampaign)
      children.append(ctor(medal))
  }
  return {
    watch = servProfile
    size = [pw(35), SIZE_TO_CONTENT]
    padding = [0, hdpx(25), 0, hdpx(50)]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = [
      mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
      {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(30)
        children = children.len() > 0 ? children : mkMarqueeText(loc("mainmenu/noMedal"))
      }
    ]
  }
}

function mkInfo(campaign, unitsStats) {

  return bgMessage.__merge({
    minWidth = SIZE_TO_CONTENT
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      bgHeader.__merge({
        size = [flex(), SIZE_TO_CONTENT]
        padding = hdpx(5)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          color = defColor
          text = loc($"campaign/{campaign}")
        }.__update(fontSmallAccented)
      })
      {
        size = [pw(100), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        padding = [hdpx(20), 0]
        children = [
          mkMedals(campaign)
          function() {
            let my = unitsStats.get().my[campaign]
            let all = unitsStats.get().all[campaign]
            return {
              watch = unitsStats
              size = [pw(35), SIZE_TO_CONTENT]
              padding = [0, hdpx(25)]
              valign = ALIGN_CENTER
              flow = FLOW_VERTICAL
              gap = hdpx(5)
              children = [
                mkText(loc("lobby/vehicles"), hlColor).__update(fontTinyAccented)
                mkMarqueeRow(loc("stats/line"), $"{my.wp}/{all.wp}")
                mkMarqueeRow(loc("stats/maxLevel"), $"{my.maxLevel}/{my.wp + my.prem + my.rare}")
                mkMarqueeRow(loc("stats/premium"), $"{my.prem}/{all.prem}", {
                  size = iconSize
                  rendObj = ROBJ_IMAGE
                  keepAspect = KEEP_ASPECT_FIT
                  image = Picture($"ui/gameuiskin#icon_premium.svg:{iconSize[0]}:{iconSize[1]}:P")
                  vplace = ALIGN_CENTER
                })
                mkMarqueeRow(loc("stats/rare"), $"{my.rare}")
              ]
            }
          }
          function() {
            let stats = playerStats.get()?[campaign] ?? {}
            return {
              watch = playerStats
              size = [pw(30), SIZE_TO_CONTENT]
              padding = [0, hdpx(50), 0, hdpx(25)]
              valign = ALIGN_CENTER
              flow = FLOW_VERTICAL
              gap = hdpx(5)
              children = [mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)]
                .extend(viewStats.map(@(conf) mkStatRow(stats, conf, campaign, mkMarqueeRow)))
            }
          }
        ]
      }
    ]
  })
}

return function() {
  let unitsStats = Computed(function() {
    let { unitLevels = {}, allUnits = {} } = serverConfigs.get()
    let { units = {} } = servProfile.get()
    let all = {}
    let my = {}

    foreach (v in campaignsList.get()) {
      all[v] <- { prem = 0, wp = 0 }
      my[v] <- { prem = 0 wp = 0 maxLevel = 0 rare = 0 }
    }

    foreach (id, v in allUnits) {
      let { levelPreset = "0", campaign = "", isHidden = false, isPremium = false, costWp = 0 } = v
      if (campaign not in all)
        all[campaign] <- { prem = 0, wp = 0 }
      if (campaign not in my)
        my[campaign] <- { prem = 0 wp = 0 maxLevel = 0 rare = 0 }
      if (isPremium && !isHidden)
        all[campaign].prem++
      else if (costWp > 0)
        all[campaign].wp++

      if (id not in units)
        continue
      let unit = units[id]
      let levels = unitLevels?[levelPreset ?? "0"] ?? []
      if (isHidden)
        my[campaign].rare++
      if (isPremium && !isHidden)
        my[campaign].prem++
      else if ((costWp ?? 0) > 0)
        my[campaign].wp++
      if (unit?.level == levels.len())
        my[campaign].maxLevel++
    }
    return {all my}
  })

  return {
    onAttach = actualizeStats
    watch = campaignsList
    minWidth = SIZE_TO_CONTENT
    size = [flex(), SIZE_TO_CONTENT]
    padding = [0, 0, hdpx(40), 0]
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = campaignsList.value.map(@(v) mkInfo(v, unitsStats))
  }
}
