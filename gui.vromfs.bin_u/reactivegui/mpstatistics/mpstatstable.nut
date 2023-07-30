from "%globalsDarg/darg_library.nut" import *
let { getUnitLocId, getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")

let cellTextColor = Color(255, 255, 255)
let unitDeadTextColor = Color(56, 56, 56, 56)
let rowBgLocalPlayerColor = Color(40, 96, 128, 128)
let rowBgOddColor = Color(20, 20, 20, 20)
let rowBgEvenColor = Color(0, 0, 0, 0)

let rowHeight = hdpx(76)
let rowHeadIconSize = hdpx(44)
let playerPlaceIconSize = hdpx(90)

let placeBadgeByIdx = [
  Picture("!ui/gameuiskin#player_rank_badge_gold.avif")
  Picture("!ui/gameuiskin#player_rank_badge_silver.avif")
  Picture("!ui/gameuiskin#player_rank_badge_bronze.avif")
]

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

let levelMark = @(text) {
  size = array(2, hdpx(45))
  margin = hdpx(10)
  children = [
    mkLevelBg()
    {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      pos = [0, -hdpx(2)]
      text
    }.__update(fontVeryTiny)
  ]
}

let premIconSize = fontSmall.fontSize
let premiumMark = {
  size = [premIconSize, premIconSize]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconSize}:{premIconSize}:K:P")
}

let function getUnitNameText(unitId, halign, unitCfg) {
  let name = loc(getUnitLocId(unitId), unitId)
  let icon = getUnitClassFontIcon(unitCfg)
  let ordered = halign != ALIGN_RIGHT ? [ icon, name ] : [ name, icon ]
  return " ".join(ordered, true)
}

let function mkNameContent(player, teamColor, halign, unitsCfg, _idx) {
  let unitName = player?.mainUnitName ?? player.aircraftName
  let nameCell = {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = [
      cellTextProps.__merge({
        maxWidth = pw(100)
        halign
        color = player.isLocal ? cellTextColor : teamColor
        text = player.nickname
      })
      player.hasPremium ? premiumMark : null
    ]
  }
  let res = {
    size = flex()
    halign
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      levelMark(player.level.tostring())
      {
        size = flex()
        halign
        valign = ALIGN_CENTER
        gap = hdpx(-5)
        flow = FLOW_VERTICAL
        children = [
          nameCell
          cellTextProps.__merge({
            maxWidth = pw(100)
            halign
            color = player.isDead ? unitDeadTextColor
              : !player?.isUnitPremium ?  cellTextColor
              : premiumTextColor
            text = getUnitNameText(unitName, halign, unitsCfg?[unitName])
          })
        ]
      }
    ]
  }
  if (halign == ALIGN_RIGHT) {
    nameCell.children.reverse()
    res.children.reverse()
  }
  return res
}

let mkPlaceContent = @(_player, _teamColor, _halign, _unitsCfg, idx) {
  size = [playerPlaceIconSize, playerPlaceIconSize]
  rendObj = ROBJ_IMAGE
  image = placeBadgeByIdx?[idx]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = idx + 1
  }.__update(fontTiny)
}

let cellDefaults = { width = rowHeight, halign = ALIGN_CENTER }
let function mirrorColumn(column) {
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

let columnsByCampaign = {
  ships = mkColumnsCfg([
    { width = playerPlaceIconSize, contentCtor = mkPlaceContent }
    { width = flex(), halign = ALIGN_LEFT, contentCtor = mkNameContent }
    { width = hdpx(192), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat(p.damage.tointeger()) }
    { headerIcon = "ui/gameuiskin#stats_ships_destroyed.svg", getText = @(p) decimalFormat(p.navalKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
  ])

  tanks = mkColumnsCfg([
    { width = playerPlaceIconSize, contentCtor = mkPlaceContent }
    { width = flex(), halign = ALIGN_LEFT, contentCtor = mkNameContent }
    { width = hdpx(192), headerIcon = "ui/gameuiskin#score_icon.svg", getText = @(p) decimalFormat((100 * p.score).tointeger()) }
    { headerIcon = "ui/gameuiskin#tanks_destroyed_icon.svg", getText = @(p) decimalFormat(p.groundKills) }
    { headerIcon = "ui/gameuiskin#stats_airplanes_destroyed.svg", getText = @(p) decimalFormat(p.kills) }
  ])
}

let getColumnsByCampaign = @(campaign) columnsByCampaign?[campaign] ?? columnsByCampaign.tanks

let function mkPlayerRow(columnCfg, player, teamColor, idx, unitsCfg) {
  let { columns, rowOvr = {} } = columnCfg
  return {
    size = [ flex(), rowHeight ]
    rendObj = ROBJ_SOLID
    color = (player?.isLocal ?? false) ? rowBgLocalPlayerColor
      : idx % 2 != 0 ? rowBgOddColor
      : rowBgEvenColor
    flow = FLOW_HORIZONTAL
    children = player == null ? null : columns.map(function(c) {
      let { width, halign, contentCtor = null, getText = null } = c
      return {
        size = [width, rowHeight]
        halign = halign
        valign = ALIGN_CENTER
        children = contentCtor != null ? contentCtor(player, teamColor, halign, unitsCfg, idx)
          : cellTextProps.__merge({ text = getText(player) })
      }
    })
  }.__update(rowOvr)
}

let function mkTeamHeaderRow(columnCfg) {
  let { columns, rowOvr = {} } = columnCfg
  return {
    size = [ flex(), rowHeight ]
    color = cellTextColor
    flow = FLOW_HORIZONTAL
    children = columns.map(@(c) {
      size = [c.width, rowHeight]
      halign = c.halign
      valign = ALIGN_CENTER
      children = "headerIcon" in c ? mkCellIcon(c.headerIcon) : null
    })
  }.__update(rowOvr)
}

let mkMpStatsTable = @(columnsCfg, teams, unitsCfg) {
  size = [ flex(), SIZE_TO_CONTENT ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = teams.map(function(team, teamIdx) {
    let teamColor = teamIdx == 0 ? teamBlueColor : teamRedColor
    let columnCfg = columnsCfg[teamIdx % columnsCfg.len()]
    return {
      size = [ flex(), SIZE_TO_CONTENT ]
      flow = FLOW_VERTICAL
      children = [mkTeamHeaderRow(columnCfg)]
        .extend(team.map(@(player, idx) @() mkPlayerRow(columnCfg, player, teamColor, idx, unitsCfg)))
    }
  })
}

return {
  mkMpStatsTable
  getColumnsByCampaign
}
