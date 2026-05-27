from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToLower
from "%appGlobals/permissions.nut" import allow_clusters_selection
from "%appGlobals/clustersState.nut" import OPTIMAL_RTT_LIMIT_MS, selClusters, clusterStats, userPreferredClusters, saveUserClusters
from "%appGlobals/config/clusterPresentation.nut" import getClusterName, getClusterFullName
from "%rGui/navState.nut" import registerScene
from "%rGui/options/optCtrlType.nut" import OCT_LIST
import "%rGui/options/mkOption.nut" as mkOption
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/infoButton.nut" import infoTooltipButton
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdColors.nut" import goodTextColor2, badTextColor

let warnTextColor = 0xFFFFD93E

let bgPanelPadding = hdpx(30)
let buttonsGap = hdpx(150)
let buttonsMinWidth = hdpx(600)

let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened.set(false)
allow_clusters_selection.subscribe(@(v) v ? null : onClose())


let clustersOrder = Watched([])
let updateClustersOrder = @(isOpen) clustersOrder.set(isOpen
  ? clusterStats.get().map(@(v) v.clusterId)
  : [])
let clusterStatsFixedOrder = Computed(@() clustersOrder.get()
  .map(@(id) clusterStats.get()?.findvalue(@(v) v.clusterId == id))
  .filter(@(v) v != null))
let canDisableClusters = Computed(@() clustersOrder.get()
  .reduce(@(res, id) res + (userPreferredClusters.get()?[id] != false ? 1 : 0), 0) > 1)

isOpened.subscribe(function(v) {
  updateClustersOrder(v)
  if (!v)
    saveUserClusters()
})
updateClustersOrder(isOpened.get())

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmall, ovr)

let mkTextarea = @(text, ovr = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontSmall, ovr)

let clusterOptList = [ false, null, true ]
let clusterOptValToString = @(v) loc(v == null ? "cluster/multi" : v ? "options/on" : "options/off")
let clusterOptValToDescMap = {
  [false] = @() loc("clusters/mode/off"),
  [null]  = @() "".concat(
      loc("clusters/mode/auto", { rttLimit = nbsp.concat(OPTIMAL_RTT_LIMIT_MS, loc("measureUnits/milliseconds")) }),
      loc("ui/parentheses/space", { text = utf8ToLower(loc("mainmenu/recommended")) })
    ),
  [true]  = @() loc("clusters/mode/on"),
}

let buttonsTextsWidth = clusterOptList.map(@(v) calc_comp_size(mkText(clusterOptValToString(v), fontSmall))[0])
  .reduce(@(res, v) max(res, v)) * clusterOptList.len()
let buttonsWidth = max(buttonsMinWidth, buttonsTextsWidth + hdpx(80))

let columnsCfg = [
  {
    relWidth = 1.7
    titleLocId = "clusters/cluster"
    halign = ALIGN_LEFT
    mkCell = @(c, v, _) {
      size = [c.width, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(8)
      children = [
        mkText(getClusterName(v.clusterId))
        mkTextarea(getClusterFullName(v.clusterId), fontVeryTiny)
      ]
    }
  }
  {
    relWidth = 1.0
    titleLocId = "clusters/reachability"
    halign = ALIGN_RIGHT
    mkCell = @(c, v, _) mkText("".concat(v.availablePercent, "%"), {
        size = [c.width, SIZE_TO_CONTENT]
        halign = c.halign
        color = v.availablePercent == 100 ? goodTextColor2
          : v.availablePercent == 0 ? badTextColor
          : warnTextColor
      })
  }
  {
    relWidth = 1.0
    titleLocId = "clusters/averageRTT"
    halign = ALIGN_RIGHT
    mkCell = @(c, v, _) mkText(v.hostsRTT != null
        ? nbsp.concat(v.hostsRTT, loc("measureUnits/milliseconds"))
        : loc("leaderboards/notAvailable"),
      {
        size = [c.width, SIZE_TO_CONTENT]
        halign = c.halign
        color = v.hostsRTT == null ? badTextColor
          : v.hostsRTT <= OPTIMAL_RTT_LIMIT_MS ? goodTextColor2
          : warnTextColor
      })
  }
  {
    width = buttonsGap + buttonsWidth
    titleLocId = "mode"
    halign = ALIGN_RIGHT
    mkCell = @(_, __, valueW) {
        size = [buttonsWidth, SIZE_TO_CONTENT]
        margin = [0, 0, 0, buttonsGap]
        hplace = ALIGN_RIGHT
        children = mkOption({
          ctrlType = OCT_LIST
          value = valueW
          list = clusterOptList
          valToString = clusterOptValToString
          function setValue(v) {
            if (v == false && !canDisableClusters.get())
              return openMsgBox({ text = loc("clusters/cantDisableLastCluster") })
            valueW.set(v)
          }
        })
      }
    hintTextCtor = @() "\n".join(clusterOptList.map(@(v) " ".concat(
      colorize("@darken", clusterOptValToString(v)),
      loc("ui/ndash"),
      clusterOptValToDescMap[v]())))
  }
]

let columnsWidth = saSize[0] - (2 * bgPanelPadding) - columnsCfg.reduce(@(acc, v) acc + (v?.width ?? 0), 0)
let columnsWidthUnits = columnsWidth * 1.0 / columnsCfg.reduce(@(acc, v) acc + (v?.relWidth ?? 0), 0)
columnsCfg.each(@(c) c.width <- c?.width ?? (c.relWidth * columnsWidthUnits).tointeger())

let wndHeader = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backButton(onClose)
    {
      hplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("options/cluster")
    }.__update(fontBig)
  ]
}

let bgPanel = {
  size = FLEX_H
  rendObj = ROBJ_SOLID
  color = 0x990C1113
  padding = bgPanelPadding
  valign = ALIGN_CENTER
}

let currentClustersComp = bgPanel.__merge({
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(16)
  children = [
    mkText("".concat(loc("clusters/clustersInUse"), loc("ui/colon")))
    @() mkText(comma.join(selClusters.get().map(@(id) getClusterName(id))), fontBig.__merge({
        watch = selClusters
        transform = {}
        animations = [
          { prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3],
              duration = 0.75, easing = CosineFull, play = true }
        ]
      }))
  ]
})

let mkHeaderRow = @() {
  size = FLEX_H
  padding = [hdpx(16), bgPanelPadding]
  flow = FLOW_HORIZONTAL
  children = columnsCfg.map(@(c) {
    size = [c.width, SIZE_TO_CONTENT]
    halign = c.halign
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = [
      mkText(loc(c.titleLocId), fontTiny)
      infoTooltipButton(
        c?.hintTextCtor ?? @() loc($"{c.titleLocId}/desc"),
        { flow = FLOW_VERTICAL, valign = ALIGN_TOP })
    ]
  })
}

function mkClusterRow(cluster, userPrefClustersW) {
  let { clusterId } = cluster
  let valueW = Watched(userPrefClustersW.get()?[clusterId])
  valueW.subscribe(@(v) userPrefClustersW.mutate(@(o) o[clusterId] <- v))
  return bgPanel.__merge({
    padding = const [hdpx(0), hdpx(30)]
    flow = FLOW_HORIZONTAL
    children = columnsCfg.map(@(col) col.mkCell(col, cluster, valueW))
  })
}

let clustersOptionsScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    wndHeader
    @() {
      watch = [clusterStatsFixedOrder, userPreferredClusters]
      size = flex()
      flow = FLOW_VERTICAL
      gap = hdpx(30)
      children = [
        currentClustersComp
        {
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [ mkHeaderRow() ]
            .extend(clusterStatsFixedOrder.get().map(@(v) mkClusterRow(v, userPreferredClusters)))
        }
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("clustersOptionsScene", clustersOptionsScene, onClose, isOpened)

return {
  openClustersOptions = @() isOpened.set(true)
}
