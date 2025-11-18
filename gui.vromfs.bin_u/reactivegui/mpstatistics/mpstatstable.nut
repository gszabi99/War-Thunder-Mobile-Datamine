from "%globalsDarg/darg_library.nut" import *
let regexp2 = require("regexp2")
let { roundToDigits } = require("%sqstd/math.nut")
let { preciseSecondsToString } = require("%appGlobals/timeToText.nut")
let { getUnitLocId, unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { mkSubsIcon } = require("%appGlobals/config/subsPresentation.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")
let { premiumTextColor, collectibleTextColor, selectColor } = require("%rGui/style/stdColors.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { playerPlaceIconSize, mkPlaceIcon } = require("%rGui/components/playerPlaceIcon.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { selectedPlayerForInfo } = require("%rGui/mpStatistics/viewProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { backButtonWidth } = require("%rGui/components/backButton.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { raceTotalLaps, raceTotalCheckpoints } = require("%rGui/hud/raceState.nut")


let STICKY_UPPER = 0x01
let STICKY_BELOW = 0x02

let cellTextColor = Color(255, 255, 255)
let unitDeadTextColor = Color(56, 56, 56, 56)
let rowBgLocalPlayerColor = selectColor
let rowStickyBgLocalPlayerColor = selectColor
let rowBgOddColor = Color(20, 20, 20, 20)
let rowBgEvenColor = Color(0, 0, 0, 0)

let rowHeight = hdpx(76)
let rowHeadIconSize = hdpx(44)
let avatarHeight = rowHeight - hdpx(2)
let squadLabelWidth = hdpx(34)
let squadLabelHeight = hdpx(41)

let notAvailableTxt = loc("ui/mdash")

let cellTextProps = {
  rendObj = ROBJ_TEXT
  fontFx = FFT_GLOW
  fontFxFactor = 48
  fontFxColor = Color(0, 0, 0)
  color = cellTextColor
}.__update(fontTinyAccented)

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
  let name = loc(getUnitLocId(unitId), unitId)
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
    size = [squadLabelWidth, flex()]
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
  size = flex()
  halign
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    mkGradRankSmall(player.mRank)
    cellTextProps.__merge({
      halign
      valign = ALIGN_CENTER
      maxWidth = pw(100)
      size = flex()
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(30)
      color = getColorUnitName(player)
      text = getUnitNameText(player.unitName, player.unitClass)
    })
  ]
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
    size = flex()
    halign
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(4)
    children = [
      mkAvatar(player)
      mkSquadLabel(player, nameColor)
      {
        size = flex()
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
    rowOvr = { padding = [ 0, 0, 0, saBordersRv[1] ] }
  }
  {
    columns = columns.map(@(c) mirrorColumn(cellDefaults.__merge(c))).reverse(),
    rowOvr = { padding = [ 0, saBordersRv[1], 0, 0 ] }
  }
]

let KG_TO_TONS = 0.001
let damageZoneMission = regexp2(@"_GS(_|$)")
let columnsByCampaign = {
  ships = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = flex(), halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat(p.damage.tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { headerIcon = "ui/gameuiskin#stats_ships_destroyed.svg", getText = @(p) decimalFormat(p.navalKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
  ]

  tanks = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = flex(), halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat((100 * p.score).tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { headerIcon = "ui/gameuiskin#tanks_destroyed_icon.svg", getText = @(p) decimalFormat(p.groundKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
  ]

  air = [
    { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
    { width = flex(), halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkNameContent }
    { width = hdpx(120), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat((100 * p.score).tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_assist.svg", getText = @(p) p?.assists ?? 0 }
    { width = hdpx(100), fontIcon = "icon/mpstats/damageZone", getText = @(p) roundToDigits(p.damageZone * KG_TO_TONS, 2),
      isVisible = @(missionName) damageZoneMission.match(missionName) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
    { headerIcon = "ui/gameuiskin#air_defence_destroyed_icon.svg", getText = @(p) decimalFormat(p.aiGroundKills + p.aiNavalKills) }
  ]
}

let ffaColumns = [
  { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = mkPlaceContent }
  { width = playerPlaceIconSize, valign = ALIGN_CENTER, contentCtor = @(p, _, _) mkAvatar(p) }
  { width = flex(), halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = mkPlayerName }
  { width = flex(), halign = ALIGN_LEFT, valign = ALIGN_CENTER, contentCtor = @(p, _, h) mkUnitName(p, h) }
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
let getColumnsByCampaign = @(campaign, missionName, gt)
  mkColumnsCfg((columnsByGameType?[gt & gtCfgMask]
    ?? columnsByCampaign?[campaign]
    ?? columnsByCampaign?[getCampaignPresentation(campaign).campaign]
    ?? columnsByCampaign.air
  ).filter(@(c) c?.isVisible(missionName) ?? true))

function mkPlayerRow(columnCfg, player, teamColor, idx, bgColorOvr = null, ovr = {}) {
  let { columns, rowOvr = {} } = columnCfg

  let playerColor = player?.isInHeroSquad ? mySquadLightColor : teamColor
  let isCurrent = Computed(@() player != null && selectedPlayerForInfo.get()?.player.userId == player?.userId)
  return @() {
    watch = isCurrent
    size = [ flex(), rowHeight ]
    rendObj = ROBJ_SOLID
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
      size = [ flex(), rowHeight ]
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

function mkTeamHeaderRow(columnCfg) {
  let { columns, rowOvr = {} } = columnCfg
  return {
    size = [ flex(), rowHeight ]
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

let mkMpStatsTable = @(columnsCfg, teams, statsWithScrollHeight = null) {
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  onDetach = @() selectedPlayerForInfo.set(null)
  children = teams.map(function(team, teamIdx) {
    let teamColor = teams.len() > 1 && teamIdx == 0 ? teamBlueLightColor : teamRedLightColor
    let columnCfg = columnsCfg[teamIdx % columnsCfg.len()]
    let headerRow = mkTeamHeaderRow(columnCfg)
    let playerRows = team.map(@(player, idx) mkPlayerRow(columnCfg, player, teamColor, idx))
    if (statsWithScrollHeight == null)
      return {
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = [headerRow].extend(playerRows)
      }

    let localPlayerIdx = team.findindex(@(p) p.isLocal) ?? 0
    let localPlayerPosY = localPlayerIdx * rowHeight
    let localPosState = Computed(function() {
      let curY = scrollHandler.elem?.getOverScrollOffsY() ?? 0
      return curY > localPlayerPosY ? STICKY_UPPER
        : curY + statsWithScrollHeight - rowHeight < localPlayerPosY + rowHeight ? STICKY_BELOW
        : 0
    })
    return {
      size = [flex(), statsWithScrollHeight]
      padding = [0, saBorders[0] + backButtonWidth]
      children = [
        {
          size = flex()
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
          : @() {
              watch = localPosState
              size = [flex(), SIZE_TO_CONTENT]
              pos = [0, rowHeight]
              children = localPosState.get() & STICKY_UPPER
                  ? mkPlayerRow(columnCfg, team[localPlayerIdx], teamColor, localPlayerIdx,
                      rowStickyBgLocalPlayerColor, { pos = [0, 0] })
                : localPosState.get() & STICKY_BELOW
                  ? mkPlayerRow(columnCfg, team[localPlayerIdx], teamColor, localPlayerIdx,
                      rowStickyBgLocalPlayerColor, { pos = [0, statsWithScrollHeight - rowHeight * 2] })
                : null
            }
      ]
    }
  })
}

return {
  mkMpStatsTable
  getColumnsByCampaign
  cellTextProps
}
