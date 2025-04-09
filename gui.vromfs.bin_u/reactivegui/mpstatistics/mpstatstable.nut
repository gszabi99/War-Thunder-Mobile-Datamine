from "%globalsDarg/darg_library.nut" import *
let regexp2 = require("regexp2")
let { roundToDigits } = require("%sqstd/math.nut")
let { getUnitLocId, unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")
let { premiumTextColor, collectibleTextColor } = require("%rGui/style/stdColors.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { playerPlaceIconSize, mkPlaceIcon } = require("%rGui/components/playerPlaceIcon.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { selectedPlayerForInfo } = require("%rGui/mpStatistics/viewProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let cellTextColor = Color(255, 255, 255)
let unitDeadTextColor = Color(56, 56, 56, 56)
let rowBgLocalPlayerColor = Color(40, 96, 128, 128)
let rowBgOddColor = Color(20, 20, 20, 20)
let rowBgEvenColor = Color(0, 0, 0, 0)

let rowHeight = hdpx(76)
let rowHeadIconSize = hdpx(44)
let avatarHeight = rowHeight - hdpx(2)
let squadLabelWidth = hdpx(34)
let squadLabelHeight = hdpx(41)

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
  image = Picture($"{icon}:{rowHeadIconSize}:{rowHeadIconSize}")
}

let mkCellFontIcon = @(icon) {
  size = [ rowHeadIconSize, rowHeadIconSize ]
  rendObj = ROBJ_TEXT
  text = loc(icon)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
}.__update(fontMedium)


let premIconSize = fontSmall.fontSize
let premiumMark = @(player) !player.hasPremium ? null : {
  size = [premIconSize, premIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = player.hasVip
    ? Picture($"ui/gameuiskin#vip_active.svg:{premIconSize}:{premIconSize}:P")
    : Picture($"ui/gameuiskin#premium_active.svg:{premIconSize}:{premIconSize}:K:P")
}

function getUnitNameText(unitId, unitClass, halign) {
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

function mkNameContent(player, teamColor, halign) {
  let { unitName, name } = player
  let nameColor = player.isLocal ? cellTextColor : teamColor
  let nameCell = {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = [
      premiumMark(player)
      cellTextProps.__merge({
        maxWidth = pw(100)
        halign
        color = nameColor
        text = name
      })
    ]
  }
  let unitCell = {
    size = flex()
    halign
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      mkGradRankSmall(player.mRank)
      cellTextProps.__merge({
        maxWidth = pw(100)
        size = flex()
        halign
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
        color = getColorUnitName(player)
        text = getUnitNameText(unitName, player.unitClass, halign)
      })
    ]
  }

  let res = {
    size = flex()
    halign
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(4)
    children = [
      {
        size = [avatarHeight, avatarHeight]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getAvatarImage(player?.decorators.avatar)}:{avatarHeight}:{avatarHeight}:P")
      }
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

let getColumnsByCampaign = @(campaign, missionName)
  mkColumnsCfg((columnsByCampaign?[campaign] ?? columnsByCampaign.air).filter(@(c) c?.isVisible(missionName) ?? true))

function mkPlayerRow(columnCfg, player, teamColor, idx) {
  let { columns, rowOvr = {} } = columnCfg

  let playerColor = player?.isInHeroSquad ? mySquadLightColor : teamColor
  return {
    size = [ flex(), rowHeight ]
    rendObj = ROBJ_SOLID
    color = player == selectedPlayerForInfo.value ? 0xA0000000
      : (player?.isLocal ?? false) ? rowBgLocalPlayerColor
      : idx % 2 != 0 ? rowBgOddColor
      : rowBgEvenColor
    children = {
      key = player?.userId
      behavior = Behaviors.Button
      onClick = function() {
        if (selectedPlayerForInfo.value == player)
          selectedPlayerForInfo(null)
        else
          selectedPlayerForInfo({player, campaign = curCampaign.get()})
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
          padding = [hdpx(5), 0]
          children = contentCtor != null ? contentCtor(player, playerColor, halign)
            : cellTextProps.__merge({ text = getText?(player) })
        }
      })
    }
  }.__update(rowOvr)
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

let mkMpStatsTable = @(columnsCfg, teams) {
  size = [ flex(), SIZE_TO_CONTENT ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  onDetach = @() selectedPlayerForInfo(null)
  children = teams.map(function(team, teamIdx) {
    let teamColor = teamIdx == 0 ? teamBlueLightColor : teamRedLightColor
    let columnCfg = columnsCfg[teamIdx % columnsCfg.len()]
    return {
      size = [ flex(), SIZE_TO_CONTENT ]
      flow = FLOW_VERTICAL
      children = [mkTeamHeaderRow(columnCfg)]
        .extend(team.map(@(player, idx) @() mkPlayerRow(columnCfg, player, teamColor, idx)))
    }
  })
}

return {
  mkMpStatsTable
  getColumnsByCampaign
}
