from "%globalsDarg/darg_library.nut" import *
import "regexp2" as regexp2
from "%sqstd/math.nut" import roundToDigits, lerpClamped
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/config/hudCustomRulesPresentation.nut" import getCtfFlagPresentation
from "%appGlobals/config/subsPresentation.nut" import mkSubsIcon
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/timeToText.nut" import preciseSecondsToString
from "%appGlobals/unitPresentation.nut" import getUnitName, unitClassFontIcons
from "%rGui/components/gradTexts.nut" import mkGradRankSmall
from "%rGui/components/masteryTierComp.nut" import mkMasteryTierColorIcon
from "%rGui/components/playerPlaceIcon.nut" import playerPlaceIconSize, mkPlaceIcon
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/hud/raceState.nut" import raceTotalLaps, raceTotalCheckpoints
from "%rGui/mpStatistics/playersSortFunc.nut" import getScoreFull
from "%rGui/mpStatistics/viewProfile.nut" import selectedPlayerForInfo
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdColors.nut" import premiumTextColor, collectibleTextColor, selectColor
from "%rGui/style/teamColors.nut" import teamBlueLightColor, teamRedLightColor, mySquadLightColor
from "%rGui/textFormatByLang.nut" import decimalFormat


let STICKY_UPPER = 0x01
let STICKY_BELOW = 0x02

let cellTextColor = Color(255, 255, 255)
let unitDeadTextColor = Color(56, 56, 56, 56)
let rowBgLocalPlayerColor = selectColor
let rowStickyBgLocalPlayerColor = selectColor
let rowBgOddColor = Color(20, 20, 20, 20)
let rowBgEvenColor = Color(0, 0, 0, 0)

let tableWidth = hdpx(1000)
let oneTeamBattleTableWidth = hdpx(1200)
let rowHeight = hdpx(76)
let rowHeadIconSize = hdpx(44)
let avatarHeight = rowHeight - hdpx(2)
let squadLabelWidth = hdpx(34)
let squadLabelHeight = hdpx(41)

let singleMasteryTierSize = hdpxi(29)

let notAvailableTxt = loc("ui/mdash")

let cellTextProps = {
  rendObj = ROBJ_TEXT
  color = cellTextColor
}.__update(fontTinyAccentedShaded)

let mkCellIcon = @(icon) {
  size = [ rowHeadIconSize, rowHeadIconSize ]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"{icon}:{rowHeadIconSize}:{rowHeadIconSize}:P")
}

let mkCellFontIcon = @(icon) {
  size = [ rowHeadIconSize, rowHeadIconSize ]
  rendObj = ROBJ_TEXT
  text = loc(icon)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}.__update(fontMedium)


let premIconSize = hdpx(30)
let premiumMark = @(player) !player.hasPremium ? null
  : mkSubsIcon(
    player.hasVip ? "vip"
      : player.hasPrem ? "prem"
      : "prem_deprecated",
    premIconSize,
  )

function getUnitNameText(unitId, unitClass, halign = null) {
  let name = getUnitName(unitId)
  let icon = unitClassFontIcons?[unitClass] ?? ""
  let ordered = halign != ALIGN_RIGHT ? [ icon, name ] : [ name, icon ]
  return " ".join(ordered, true)
}

let function getColorUnitName(player){
  if(player.isDead && !player.isTemporary)
    return unitDeadTextColor
  else if(player?.isUnitCollectible)
    return collectibleTextColor
  else if(player?.isUnitPremium || player?.isUnitUpgraded)
    return premiumTextColor
  return cellTextColor
}

function mkSquadLabel(player, color){
  let res = {
    rendObj = ROBJ_BOX
    size = [squadLabelWidth, FLEX]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
  }
  if ((player?.squadLabel ?? -1) == -1)
    return res
  return res.__update({
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [squadLabelWidth, squadLabelHeight]
        image = Picture($"ui/gameuiskin#icon_leaderboard_squad.svg:{squadLabelWidth}:{squadLabelHeight}:P")
      }
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_RIGHT
        text = player.squadLabel
        color
      }
    ]
  })
}

let mkPlayerName = @(player, teamColor, halign = null) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    premiumMark(player)
    cellTextProps.__merge({
      maxWidth = pw(100)
      halign
      color = player.isLocal ? cellTextColor : teamColor
      text = player.name
    })
  ]
}

let mkUnitName = @(player, halign = null) {
  size = FLEX
  halign
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    mkGradRankSmall(player.mRank)
    player.rewardedMasteryTier > 0 ? mkMasteryTierColorIcon(singleMasteryTierSize, player.rewardedMasteryTier) : null
    cellTextProps.__merge({
      halign
      valign = ALIGN_CENTER
      maxWidth = pw(100)
      size = FLEX
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(30)
      color = getColorUnitName(player)
      text = getUnitNameText(player.unitName, player.unitClass)
    })
  ].filter(@(v) v != null)
}

let mkAvatar = @(player) {
  size = [avatarHeight, avatarHeight]
  rendObj = ROBJ_IMAGE
  image = Picture($"{getAvatarImage(player?.decorators.avatar)}:{avatarHeight}:{avatarHeight}:P")
}

function mkNameContent(player, teamColor, halign) {
  let nameColor = player.isLocal ? cellTextColor : teamColor
  let nameCell = mkPlayerName(player, teamColor, halign)
  let unitCell = mkUnitName(player, halign)
  let res = {
    size = FLEX
    halign
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(4)
    children = [
      mkAvatar(player)
      mkSquadLabel(player, nameColor)
      {
        size = FLEX
        halign
        valign = ALIGN_CENTER
        gap = hdpx(-5)
        flow = FLOW_VERTICAL
        children = [
          nameCell
          unitCell
        ]
      }
    ]
  }
  if (halign == ALIGN_RIGHT) {
    nameCell.children.reverse()
    res.children.reverse()
    unitCell.children.reverse()
  }
  return res
}

let mkPlaceContent = @(player, _teamColor, _halign)
  (player?.place ?? 0) > 0 ? mkPlaceIcon(player.place) : null

let cellDefaults = { width = rowHeight, halign = ALIGN_CENTER }
function mirrorColumn(column) {
  if (column.halign != ALIGN_CENTER)
    column.halign = column.halign == ALIGN_LEFT ? ALIGN_RIGHT : ALIGN_LEFT
  return column
}

let mkColumnsCfg = @(columns) [
  {
    columns = columns.map(@(c) cellDefaults.__merge(c)),
    getRowOvr = @(isTeamBattle) !isTeamBattle ? { padding = 0, halign = ALIGN_CENTER, hplace = ALIGN_CENTER }
      : { padding = [ 0, 0, 0, saBordersRv[1] ], halign = ALIGN_RIGHT, hplace = ALIGN_RIGHT }
  }
  {
    columns = columns.map(@(c) mirrorColumn(cellDefaults.__merge(c))).reverse(),
    getRowOvr = @(isTeamBattle) !isTeamBattle ? null
      : { padding = [ 0, saBordersRv[1], 0, 0 ], halign = ALIGN_LEFT}
  }
]

let KG_TO_TONS = 0.001
let damageZoneMission = regexp2(@"_GS(_|$)")
let columnsByCampaign = {
  ships = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = FLEX, halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat(getScoreFull(p).tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { headerIcon = "ui/gameuiskin#stats_ships_destroyed.svg", getText = @(p) decimalFormat(p.navalKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
  ]

  tanks = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = FLEX, halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat(getScoreFull(p).tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { headerIcon = "ui/gameuiskin#tanks_destroyed_icon.svg", getText = @(p) decimalFormat(p.groundKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills)
      isVisible = @(_, cr) cr?.useKillStreaks ?? false }
  ]

  air = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = FLEX, halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat(getScoreFull(p).tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { width = hdpx(100), fontIcon = "icon/mpstats/damageZone", getText = @(p) roundToDigits(p.damageZone * KG_TO_TONS, 2),
      isVisible = @(missionName, _) damageZoneMission.match(missionName) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills)
      isVisible = @(_, cr) (cr?.missionProgressType ?? "") != "airGS" }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills - (p?.bomberKills ?? 0)),
      isVisible = @(_, cr) (cr?.missionProgressType ?? "") == "airGS" }
    { headerIcon = "ui/gameuiskin#stats_bomber_destroyed.svg", getText = @(p) p?.bomberKills ?? 0,
      isVisible = @(_, cr) (cr?.missionProgressType ?? "") == "airGS" }
    { headerIcon = "ui/gameuiskin#air_defence_destroyed_icon.svg", getText = @(p) decimalFormat(p.aiGroundKills + p.aiNavalKills) }
  ]
}

let ffaColumns = [
  { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
  { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = @(p, _, _) mkAvatar(p) }
  { width = FLEX, halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkPlayerName }
  { width = FLEX, halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = @(p, _, h) mkUnitName(p, h) }
]

let columnsByGameType = {
  [GT_RACE] = (clone ffaColumns).append(
    { width = hdpx(160), valign = ALIGN_CENTER, headerIcon = "ui/gameuiskin#icon_checkpoints_percent.svg",
      function getText(p) {
        let { raceFinishTime = -1.0, raceLap = 0, raceLastCheckpoint = 0 } = p
        if (raceFinishTime > 0)
          return preciseSecondsToString(raceFinishTime, false)
        let total = raceTotalLaps.get() * raceTotalCheckpoints.get()
        if (total == 0)
          return notAvailableTxt
        let passed = max(0, raceLap - 1) * raceTotalCheckpoints.get() + raceLastCheckpoint
        return $"{(100 * passed / total).tointeger()}%"
      }
    }),
  [GT_LAST_MAN_STANDING] = (clone ffaColumns).append(
    { width = hdpx(120), valign = ALIGN_CENTER,
      headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat((100 * p.score).tointeger()) },
    { width = hdpx(120), valign = ALIGN_CENTER,
      headerIcon = "ui/gameuiskin#timer_icon.svg", getText = @(p) decimalFormat(p?.missionAliveTime ?? 0) },
    { width = hdpx(120), valign = ALIGN_CENTER,
      headerIcon = "ui/gameuiskin#tanks_destroyed_icon.svg", getText = @(p) decimalFormat(p.groundKills) })
}

let gtCfgMask = columnsByGameType.reduce(@(res, _, gt) res | gt, 0)
let getColumnsByCampaignCommon = @(campaign, gt)
  columnsByGameType?[gt & gtCfgMask]
    ?? columnsByCampaign?[campaign]
    ?? columnsByCampaign?[getCampaignPresentation(campaign).campaign]
    ?? columnsByCampaign.air

function getColumnsByCampaign(campaign, missionName, gt, hCustomRules) {
  let { ctfFlagPreset = "" } = hCustomRules
  if (ctfFlagPreset != "") {
    let columns = clone getColumnsByCampaignCommon(campaign, gt)
    let { mpStatIcon } = getCtfFlagPresentation(ctfFlagPreset)
    columns.append({ width = hdpx(120), valign = ALIGN_BOTTOM, headerIcon = mpStatIcon, getText = @(p) p?.flagsDelivered ?? 0 })
    return mkColumnsCfg(columns.filter(@(c) c?.isVisible(missionName, hCustomRules) ?? true))
  }
  return mkColumnsCfg(getColumnsByCampaignCommon(campaign, gt)
    .filter(@(c) c?.isVisible(missionName, hCustomRules) ?? true))
}


function mkPlayerRow(columnCfg, player, teamColor, idx, isTeamBattle, bgColorOvr = null, ovr = {}) {
  let { columns, getRowOvr = @() {} } = columnCfg
  let rowOvr = getRowOvr(isTeamBattle)

  let playerColor = player?.isInHeroSquad ? mySquadLightColor : teamColor
  let isCurrent = Computed(@() player != null && selectedPlayerForInfo.get()?.player.userId == player?.userId)
  return @() {
    watch = isCurrent
    size = [ FLEX, rowHeight ]
    rendObj = player?.isLocal ? ROBJ_IMAGE : ROBJ_SOLID
    image = simpleHorGrad
    color = isCurrent.get() ? 0xA0000000
      : bgColorOvr != null ? bgColorOvr
      : (player?.isLocal ?? false) ? rowBgLocalPlayerColor
      : idx % 2 != 0 ? rowBgOddColor
      : rowBgEvenColor
    children = {
      key = player?.userId
      behavior = Behaviors.Button
      onClick = player == null ? null
        : function() {
            if (isCurrent.get())
              selectedPlayerForInfo.set(null)
            else
              selectedPlayerForInfo.set({player, campaign = curCampaign.get()})
          }
      sound = { click = "click" }
      size = [ FLEX, rowHeight ]
      maxWidth = isTeamBattle ? tableWidth : oneTeamBattleTableWidth
      flow = FLOW_HORIZONTAL
      children = player == null ? null : columns.map(function(c) {
        let { width, halign, valign = null, contentCtor = null, getText = null } = c
        return {
          size = [width, rowHeight]
          halign = halign
          valign = valign ?? ALIGN_BOTTOM
          padding = const [hdpx(5), 0]
          children = contentCtor != null ? contentCtor(player, playerColor, halign)
            : cellTextProps.__merge({ text = getText?(player) })
        }
      })
    }
  }.__update(rowOvr, ovr)
}

function mkTeamHeaderRow(columnCfg, isTeamBattle) {
  let { columns, getRowOvr = @() {} } = columnCfg
  let rowOvr = getRowOvr(isTeamBattle)
  return {
    size = [ FLEX, rowHeight ]
    maxWidth = isTeamBattle ? tableWidth : oneTeamBattleTableWidth
    color = cellTextColor
    flow = FLOW_HORIZONTAL
    children = columns.map(@(c) {
      size = [c.width, rowHeight]
      halign = c.halign
      valign = ALIGN_CENTER
      children = "headerIcon" in c ? mkCellIcon(c.headerIcon)
        : "fontIcon" in c ? mkCellFontIcon(c.fontIcon)
        : null
    })
  }.__update(rowOvr)
}

let scrollHandler = ScrollHandler()

function mkMpStatsTable(columnsCfg, teams, statsWithScrollHeight = null) {
  let isTeamBattle = teams.len() > 1
  return {
    size = FLEX_H
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    onDetach = @() selectedPlayerForInfo.set(null)
    children = teams.map(function(team, teamIdx) {
      let teamColor = isTeamBattle && teamIdx == 0 ? teamBlueLightColor : teamRedLightColor
      let columnCfg = columnsCfg[teamIdx % columnsCfg.len()]
      let headerRow = mkTeamHeaderRow(columnCfg, isTeamBattle)
      if (statsWithScrollHeight == null)
        return {
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [headerRow].extend(team.map(@(player, idx) mkPlayerRow(columnCfg, player, teamColor, idx, isTeamBattle, null, {})))
        }

      let localPlayerIdx = team.findindex(@(p) p.isLocal) ?? 0
      let localPlayerPosY = localPlayerIdx * rowHeight
      let curY = Computed(@() scrollHandler.elem?.getScrollOffsY() ?? 0)
      let localPosState = Computed(@() curY.get() >= localPlayerPosY ? STICKY_UPPER
          : curY.get() + statsWithScrollHeight - rowHeight <= localPlayerPosY + rowHeight ? STICKY_BELOW
          : 0)

      function getOpacity(p, idx) {
        if (p?.isLocal && localPosState.get() != 0)
          return 0
        let currentY = curY.get()
        let rHeight = rowHeight.tofloat()
        if (localPosState.get() == STICKY_UPPER) {
          let startFadeY = (idx - 1.0) * rHeight
          let endFadeY = idx * rHeight - rHeight / 2.0

          return lerpClamped(startFadeY, endFadeY, 1.0, 0.0, currentY)
        }

        if (localPosState.get() == STICKY_BELOW) {
          let startFadeY = currentY + statsWithScrollHeight.tofloat() - rHeight * 2.0
          let endFadeY = (idx + 1) * rHeight

          return lerpClamped(startFadeY, startFadeY + rHeight / 2, 1.0, 0.0, endFadeY)
        }

        return 1
      }

      let playerRows = team.map(@(player, idx) mkPlayerRow(columnCfg, player, teamColor, idx, isTeamBattle, null,
        {
          behavior = Behaviors.RtPropUpdate,
          update = @() { opacity = getOpacity(player, idx) }
        }))

      let getYOffset = @() localPosState.get() == STICKY_BELOW ? statsWithScrollHeight - rowHeight * 2
        : 0

      return {
        size = [FLEX, statsWithScrollHeight]
        children = [
          {
            size = FLEX
            flow = FLOW_VERTICAL
            children = [
              headerRow
              makeVertScroll(
                {
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  children = playerRows
                },
                { isBarOutside = true, scrollHandler })
            ]
          }
          localPlayerIdx not in team ? null
            : {
                size = [FLEX, SIZE_TO_CONTENT]
                behavior = Behaviors.RtPropUpdate,
                update = @() {
                  opacity = localPosState.get() != 0 ? 1 : 0
                  transform = {
                    translate = [0, getYOffset()]
                  }
                }
                pos = [0, rowHeight]
                children = mkPlayerRow(columnCfg, team[localPlayerIdx], teamColor, localPlayerIdx, isTeamBattle,
                  rowStickyBgLocalPlayerColor, {})
              }
        ]
      }
    })
  }
}

return {
  mkMpStatsTable
  getColumnsByCampaign
  cellTextProps
}
