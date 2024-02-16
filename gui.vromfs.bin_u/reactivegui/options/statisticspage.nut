from "%globalsDarg/darg_library.nut" import *
let { campaignsList, levelInfo } = require("%appGlobals/pServer/campaign.nut")
let { bgMessage, bgHeader } = require("%rGui/style/backgrounds.nut")
let { levelMark, defColor, hlColor, iconSize, mkText, mkRow} = require("%rGui/mpStatistics/playerInfo.nut")
let { getMedalPresentation } = require("%rGui/mpStatistics/medalsPresentation.nut")
let { actualizeStats, userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")

let playerStats = Computed( @() userstatStats.get()?.stats["global"])


function mkInfo(campaign, unitsStats, medals) {
  let levelMedals = Computed(@() levelInfo.get()?.campaigns[campaign].starLevelHistory ?? [])
  let medalItems = levelMedals.get().map(@(v) levelMark(v.level, v.starLevel + 1))
  medalItems.extend(medals.get().values()
                    .filter(@(medal) (getMedalPresentation(medal)?.campaign ?? campaign) == campaign)
                    .map(@(medal) getMedalPresentation(medal).ctor(medal)))
  return bgMessage.__merge({
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
        flow = FLOW_HORIZONTAL
        size = [flex(), SIZE_TO_CONTENT]
        margin = [hdpx(20), hdpx(50)]
        gap = hdpx(50)
        children = [
          @() {
              watch = [levelMedals, medals]
              size = [flex(), SIZE_TO_CONTENT]
              valign = ALIGN_CENTER
              flow = FLOW_VERTICAL
              gap = hdpx(30)
              children = medalItems.len() > 0
                ? [
                    mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
                    {
                      valign = ALIGN_CENTER
                      flow = FLOW_HORIZONTAL
                      gap = hdpx(30)
                      children = medalItems
                    }
                  ]
                : mkText(loc("mainmenu/noMedal"))
            }
          function() {
            let my = unitsStats.get().my[campaign]
            let all = unitsStats.get().all[campaign]
            return {
              watch = unitsStats
              size = [flex(), SIZE_TO_CONTENT]
              valign = ALIGN_CENTER
              flow = FLOW_VERTICAL
              gap = hdpx(5)
              children = [
                mkText(loc("lobby/vehicles"), hlColor).__update(fontTinyAccented)
                mkRow(loc("stats/line"), $"{my.wp}/{all.wp}")
                mkRow(loc("stats/maxLevel"), $"{my.maxLevel}/{my.wp + my.prem + my.rare}")
                mkRow(loc("stats/premium"), $"{my.prem}/{all.prem}", {
                  size = iconSize
                  rendObj = ROBJ_IMAGE
                  keepAspect = KEEP_ASPECT_FIT
                  image = Picture($"ui/gameuiskin#icon_premium.svg:{iconSize[0]}:{iconSize[1]}:P")
                  hplace = ALIGN_RIGHT
                  vplace = ALIGN_CENTER
                  pos = [hdpx(45), 0]
                })
                mkRow(loc("stats/rare"), $"{my.rare}")
              ]
            }
          }
          function() {
            let {win, battle_end} = playerStats.get()[campaign]
            let percent = battle_end > 0 ? win * 100 / battle_end : 0
            return {
              watch = playerStats
              size = [flex(), SIZE_TO_CONTENT]
              valign = ALIGN_CENTER
              flow = FLOW_VERTICAL
              gap = hdpx(5)
              children = [
                mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)
                mkRow(loc("lb/battles"), $"{battle_end}")
                mkRow(loc("stats/missions_wins"), $"{percent}%")
              ]
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
  let medals = Computed(@() servProfile.get()?.medals ?? {})

  return {
    onAttach = actualizeStats
    watch = campaignsList
    size = flex()
    padding = [0, 0, hdpx(40), 0]
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = campaignsList.value.map(@(v) mkInfo(v, unitsStats, medals))
  }
}
