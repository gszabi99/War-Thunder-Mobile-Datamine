from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { curLbCfg, ratingBattlesCount, bestBattles, isLbBestBattlesOpened } = require("lbState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { actualizeStats } = require("%rGui/unlocks/userstat.nut")
let { LOG_TIME } = require("lbCategory.nut")

let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { lbHeaderHeight, lbVGap, lbHeaderRowHeight, lbTableBorderWidth,
  rowBgOddColor, rowBgEvenColor, getRowBgColor
} = require("lbStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkLbHeaderRow } = require("mkLbHeaderRow.nut")
let { makeVertScroll, scrollbarWidth } = require("%rGui/components/scrollbar.nut")

let tableWidth = hdpx(1200)
let rowHeight = evenPx(40)
let maxRowsNoScroll = (saSize[1] - lbHeaderHeight - lbVGap - lbHeaderRowHeight - lbTableBorderWidth) / rowHeight

let defTxtColor = 0xFFD8D8D8
let unratedColor = 0xFFF08466

let close = @() isLbBestBattlesOpened(false)

let mkLbName = @(locId) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "".concat(loc("lb/bestBattles"), colon, loc(locId))
}.__update(fontSmall)

let ratedCountHint = @() {
  watch = ratingBattlesCount
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  valign = ALIGN_CENTER
  color = defTxtColor
  text = ratingBattlesCount.value <= 0 ? null
    : loc("lb/maxRatedBattles/desc", { count = ratingBattlesCount.value })
}.__update(fontVeryTiny)

let header = @() {
  watch = curLbCfg
  size = [flex(), lbHeaderHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = backButton(close)
    }
    {
      size = [tableWidth, flex()]
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      children = [
        curLbCfg.value == null ? null
          : mkLbName(curLbCfg.value.locId)
        ratedCountHint
      ]
    }
    { size = flex() }
  ]
}

let mkTextCell = @(category, text, isRated) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = isRated ? defTxtColor : unratedColor
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text
}.__update(fontTiny)

let mkCell = @(category, rowData, isRated) mkTextCell(category, category.getText(rowData), isRated)

function mkLogTimeCell(category, rowData, isRated) {
  let timeLeft = Computed(@() rowData.timestamp <= 0 ? ""
    : secondsToHoursLoc(serverTime.value - rowData.timestamp))
  return @() mkTextCell(category, timeLeft.value, isRated)
    .__update({ watch = timeLeft })
}

let cellCtorByCategory = {
  [LOG_TIME] = mkLogTimeCell,
}

let mkBattleRow = @(categories, rowData, isRated)
  categories.map(@(c) (cellCtorByCategory?[c] ?? mkCell)(c, rowData, isRated))

function getLasBattleIdx(battles) {
  local time = null
  local res = null
  foreach(idx, b in battles) {
    let t = b.timestamp
    if (t > 0 && (time == null || t < time)) {
      time = t
      res = idx
    }
  }
  return res
}

function content() {
  let categories = curLbCfg.value?.battleCategories ?? curLbCfg.value?.categories
  if (categories == null)
    return { watch = curLbCfg }

  let sortField = curLbCfg.value.sortBy.field
  let ratedCount = ratingBattlesCount.value
  let battles = (clone bestBattles.value)
    .sort(@(a, b) (b?.battle_common[sortField] ?? -1) <=> (a?.battle_common[sortField] ?? -1))
    .map(@(v, idx) (v?.battle_common ?? {})
      .__merge({ idx = idx >= ratedCount ? -1 : idx, timestamp = v?["$timestamp"] ?? -1 }))
  let rows = battles.map(@(row, idx) mkBattleRow(categories, row, ratedCount > idx))
  if (rows.len() > ratedCount)
    rows.insert(ratedCount, null)

  let hasScroll = rows.len() > maxRowsNoScroll
  local lastIdx = getLasBattleIdx(battles)
  if (lastIdx >= ratedCount)
    lastIdx++

  let rowsChildren = rows
    .map(@(children, idx) {
      size = [flex(), rowHeight]
      rendObj = ROBJ_SOLID
      color = getRowBgColor(idx % 2, lastIdx == idx)
      flow = FLOW_HORIZONTAL
      children
    })

  if (!hasScroll)
    rowsChildren.append({
      size = flex()
      rendObj = ROBJ_SOLID
      color = (rowsChildren.len() % 2) ? rowBgOddColor : rowBgEvenColor
    })

  return modalWndBg.__merge({
    watch = [curLbCfg, bestBattles, ratingBattlesCount]
    size = [tableWidth, flex()]
    flow = FLOW_VERTICAL
    children = [
       modalWndHeaderBg.__merge({
         size = [flex(), lbHeaderRowHeight]
         padding = !hasScroll ? lbTableBorderWidth
           : [lbTableBorderWidth, lbTableBorderWidth + scrollbarWidth, lbTableBorderWidth, lbTableBorderWidth]
         flow = FLOW_HORIZONTAL
         valign = ALIGN_CENTER
         children = mkLbHeaderRow(categories)
       })
       {
         size = flex()
         flow = FLOW_VERTICAL
         children = !hasScroll ? rowsChildren
           : makeVertScroll({
               size = [flex(), SIZE_TO_CONTENT]
               flow = FLOW_VERTICAL
               children = rowsChildren
             })
       }
    ]
    animations = wndSwitchAnim
  })
}

let scene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv

  onAttach = actualizeStats

  flow = FLOW_VERTICAL
  gap = lbVGap
  children = [
    header
    content
  ]
  animations = wndSwitchAnim
})

registerScene("lbBestBattlesWnd", scene, close, isLbBestBattlesOpened)
