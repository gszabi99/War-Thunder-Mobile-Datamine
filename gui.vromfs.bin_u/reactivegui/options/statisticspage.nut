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
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { backButtonHeight } = require("%rGui/components/backButton.nut")

let infoBlockPadding = [hdpx(5), hdpx(50), hdpx(10), hdpx(50)]
let scrollMedalsPadding = [hdpx(20), hdpx(20), 0, hdpx(10)]
let medalsGap = hdpx(25)
let infoBlockPartsGap = hdpx(50)
let infoBlockParts = 3
let gapBackButton = hdpx(50)

let medalsBlockWidth = (contentWidthFull - infoBlockPadding[1] * 2 - ((infoBlockParts - 1) * infoBlockPartsGap)) / infoBlockParts
let scrollPaddingsWidth = scrollMedalsPadding[1] + scrollMedalsPadding[3]

let minMedalsInRow = 4
let columns = max(((medalsBlockWidth - scrollPaddingsWidth) / (medalsGap + levelHolderSize)).tointeger(), minMedalsInRow)
let playerStats = Computed( @() userstatStats.get()?.stats["global"])

let pannableArea = verticalPannableAreaCtor(sh(100) - backButtonHeight - gapBackButton,
  [hdpx(50), hdpx(50)])
let scrollHandler = ScrollHandler()

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

let premIcon = {
  size = iconSize
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#icon_premium.svg:{iconSize[0]}:{iconSize[1]}:P")
  vplace = ALIGN_CENTER
}

let mkInfo = @(campaign, unitsStats) modalWndBg.__merge({
  minWidth = SIZE_TO_CONTENT
  size = FLEX_H
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  stopMouse = false
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
          let { myResearch = 0, allResearch = 0, myMaxLevel = 0, my = 0, myPremium = 0,
            allPremium = 0, mySeasonPrem = 0, myCollectible = 0, myOther = 0,
            allBlueprint = 0, myBlueprint = 0
          } = unitsStats.get()?[campaign]
          return {
            watch = unitsStats
            size = FLEX_H
            valign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            children = [
              mkText(loc("lobby/vehicles"), hlColor).__update(fontTinyAccented)
              mkMarqueeRow(loc("stats/maxLevel"), $"{myMaxLevel}/{my}")
              mkMarqueeRow(loc("stats/research"), $"{myResearch}/{allResearch}")
              mkMarqueeRow(loc("stats/blueprint"), $"{myBlueprint}/{allBlueprint}")
              mkMarqueeRow(loc("stats/premium"), $"{myPremium}/{allPremium}", premIcon)
              mySeasonPrem == 0 ? null
                : mkMarqueeRow(loc("stats/seasonPremium"), $"{mySeasonPrem}", premIcon)
              myCollectible == 0 ? null
                : mkMarqueeRow(loc("stats/rare"), $"{myCollectible}")
              myOther == 0 ? null
                : mkMarqueeRow(loc("stats/other"), $"{myOther}")
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
            children = [mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)]
              .extend(viewStats.map(@(conf) mkStatRow(stats, conf, camp, mkMarqueeRow)))
          }
        }
      ]
    }
  ]
})

let inc = @(res, key) res.$rawset(key, (res?[key] ?? 0) + 1)

return function() {
  let unitsStats = Computed(function() {
    let { unitLevels = {}, allUnits = {}, unitResearchExp = {}, allBlueprints = {} } = serverConfigs.get()
    let { units = {} } = servProfile.get()
    let res = {}
    foreach (name, u in allUnits) {
      let { levelPreset = "0", campaign = "", isCollectible = false, isHidden = false, isPremium = false } = u
      if (name in unreleasedUnits.get())
        continue
      let counts = getSubTable(res, campaign)
      let listId = name in unitResearchExp ? "Research"
        : name in allBlueprints ? "Blueprint"
        : isPremium && !isHidden ? "Premium"
        : isPremium ? "SeasonPrem"
        : isCollectible ? "Collectible"
        : "Other"
      inc(counts, "all")
      inc(counts, $"all{listId}")

      if (name not in units)
        continue
      inc(counts, "my")
      inc(counts, $"my{listId}")
      let { level } = units[name]
      let maxLevel = unitLevels?[levelPreset].len() ?? 0
      if (level >= maxLevel)
        inc(counts, "myMaxLevel")
    }
    return res
  })

  return {
    onAttach = actualizeStats
    watch = campaignsList
    size = flex()
    children = [
      pannableArea(
        {
          flow = FLOW_VERTICAL
          size = FLEX_H
          gap = hdpx(10)
          children = campaignsList.get()
            .map(@(v) mkInfo(v, unitsStats))},
        {},
        { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler }
      )
      {
        size = flex()
        hplace = ALIGN_CENTER
        children = [
          mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
          mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
        ]
      }
    ]
  }
}
