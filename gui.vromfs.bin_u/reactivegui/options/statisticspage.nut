from "%globalsDarg/darg_library.nut" import *
let { campaignsList, getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { levelMark, hlColor, iconSize, mkText, levelHolderSize } = require("%rGui/mpStatistics/playerInfo.nut")
let { getMedalPresentationWithCtor } = require("%rGui/mpStatistics/medalsCtors.nut")
let { actualizeStats, userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { viewStats, mkStatRow, mkMarqueeRow, mkMarqueeText } = require("%rGui/mpStatistics/statRow.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { contentWidthFull } = require("%rGui/options/optionsStyle.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")


let infoBlockPadding = [hdpx(10), hdpx(50)]
let scrollMedalsPadding = [hdpx(20), hdpx(20), 0, hdpx(10)]
let medalsGap = hdpx(25)
let infoBlockPartsGap = hdpx(50)
let infoBlockParts = 3

let medalsBlockWidth = (contentWidthFull - infoBlockPadding[1] * 2 - ((infoBlockParts - 1) * infoBlockPartsGap)) / infoBlockParts
let scrollPaddingsWidth = scrollMedalsPadding[1] + scrollMedalsPadding[3]

let minMedalsInRow = 4
let columns = max(((medalsBlockWidth - scrollPaddingsWidth) / (medalsGap + levelHolderSize)).tointeger(), minMedalsInRow)
let playerStats = Computed( @() userstatStats.get()?.stats["global"])

let mkMedals = @(selCampaign) function() {
  let children = []
  let curr = servProfile.get()?.levelInfo[selCampaign] ?? {}
  foreach(v in curr?.starLevelHistory ?? [])
    children.append(levelMark(v.baseLevel, v.starLevel + 1))
  if ((curr?.starLevel ?? 0) > 0)
    children.append(levelMark(curr.level - curr.starLevel, curr.starLevel))
  let campaignExt = getCampaignPresentation(selCampaign).campaign
  foreach(medal in servProfile.get()?.medals ?? {}) {
    let { campaign = campaignExt, ctor } = getMedalPresentationWithCtor(medal.name)
    if (campaign == campaignExt)
      children.append(ctor(medal))
  }
  return {
    watch = servProfile
    size = flex()
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = [
      mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
      makeVertScroll({
        size = FLEX_H
        padding = scrollMedalsPadding
        valign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = hdpx(25)
        children = children.len() == 0
          ? mkMarqueeText(loc("mainmenu/noMedal")).__update({ maxWidth = pw(100) })
          : arrayByRows(children, columns).map(@(item) {
              flow = FLOW_HORIZONTAL
              gap = medalsGap
              children = item
            })
      })
    ]
  }
}

let mkInfo = @(campaign, unitsStats) modalWndBg.__merge({
  minWidth = SIZE_TO_CONTENT
  size = FLEX_H
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    modalWndHeader(loc(getCampaignPresentation(campaign).headerLocId),
      { size = FLEX_H, padding = hdpx(5) })
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      padding = infoBlockPadding
      gap = infoBlockPartsGap
      children = [
        mkMedals(campaign)
        function() {
          let my = unitsStats.get().my[campaign]
          let all = unitsStats.get().all[campaign]
          return {
            watch = unitsStats
            size = FLEX_H
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
          let camp = getCampaignStatsId(campaign)
          let stats = playerStats.get()?[camp] ?? {}
          return {
            watch = playerStats
            size = FLEX_H
            valign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            gap = hdpx(5)
            children = [mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)]
              .extend(viewStats.map(@(conf) mkStatRow(stats, conf, camp, mkMarqueeRow)))
          }
        }
      ]
    }
  ]
})

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
      if (id not in releasedUnits.get())
        continue
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
    size = FLEX_H
    padding = const [0, 0, hdpx(40), 0]
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = campaignsList.get()
      .map(@(v) mkInfo(v, unitsStats))
  }
}
