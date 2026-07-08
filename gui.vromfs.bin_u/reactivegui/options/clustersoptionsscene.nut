from "%globalsDarg/darg_library.nut" import *
from "string" import format
from "dagor.time" import get_time_msec
from "%sqstd/string.nut" import utf8ToUpper, utf8ToLower
from "%appGlobals/permissions.nut" import allow_clusters_selection
from "%appGlobals/clustersState.nut" import OPTIMAL_RTT_LIMIT_MS, CAN_USER_DISABLE_FASTEST_CLUSTER, selClusters, clusterStats, fastestClusterId, userPreferredClusters, isWaitingManualRefresh, clustersRefreshNow, saveUserClusters
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, serverTime, gameStartServerTimeMsec
from "%appGlobals/config/clusterPresentation.nut" import getClusterName, getClusterFullName
from "%rGui/navState.nut" import registerScene
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/infoButton.nut" import infoTooltipButton
from "%rGui/components/toggle.nut" import toggleWithLabel, toggle
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth, defButtonHeight
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdColors.nut" import goodTextColor2, badTextColor, tabBgColor

const MANUAL_REFRESH_COOLDOWN_SEC = 60

let warnTextColor = 0xFFFFD93E

let bgPanelPadding = hdpx(30)

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
let cooldownEndTime = mkWatched(persist, "cooldownEndTime", 0)

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

function mkClusterToggle(clusterId, valueW, isAvailable) {
  let sf = Watched(0)
  return toggleWithLabel(sf, valueW, toggle(valueW, sf.get()), {
    opacity = isAvailable ? 1 : 0.2
    function onClick() {
      let v = !valueW.get()
      if (!v && !CAN_USER_DISABLE_FASTEST_CLUSTER && fastestClusterId.get() == clusterId)
        return openMsgBox({ text = loc("clusters/cantDisableFastestCluster") })
      if (!v && !canDisableClusters.get())
        return openMsgBox({ text = loc("clusters/cantDisableLastCluster") })
      valueW.set(v)
    }
  })
}

let clusterOptHintCfg = [
  [ "options/on", @() "".concat(
      loc("clusters/mode/auto", { rttLimit = nbsp.concat(OPTIMAL_RTT_LIMIT_MS, loc("measureUnits/milliseconds")) }),
      loc("ui/parentheses/space", { text = utf8ToLower(loc("mainmenu/recommended")) })
    ) ],
  [ "options/off", @() loc("clusters/mode/off") ],
]

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
    mkCell = @(c, v, _) @() mkText("".concat(v.reachability, "%"), {
        watch = isWaitingManualRefresh
        size = [c.width, SIZE_TO_CONTENT]
        halign = c.halign
        color = v.reachability == 100 ? goodTextColor2
          : v.reachability == 0 ? badTextColor
          : warnTextColor
        opacity = isWaitingManualRefresh.get() ? 0.5 : 1
      })
  }
  {
    relWidth = 1.0
    titleLocId = "clusters/averageRTT"
    halign = ALIGN_RIGHT
    mkCell = @(c, v, _) @() mkText(v.hostsRTT != null
        ? nbsp.concat(v.hostsRTT, loc("measureUnits/milliseconds"))
        : loc("leaderboards/notAvailable"),
      {
        watch = isWaitingManualRefresh
        size = [c.width, SIZE_TO_CONTENT]
        halign = c.halign
        color = v.hostsRTT == null ? badTextColor
          : v.hostsRTT <= OPTIMAL_RTT_LIMIT_MS ? goodTextColor2
          : warnTextColor
        opacity = isWaitingManualRefresh.get() ? 0.5 : 1
      })
  }
  {
    relWidth = 1.0
    titleLocId = "options/enable"
    halign = ALIGN_RIGHT
    mkCell = @(c, v, valueW) @() {
        watch = fastestClusterId
        size = [c.width, SIZE_TO_CONTENT]
        halign = c.halign
        children = mkClusterToggle(v.clusterId, valueW,
          CAN_USER_DISABLE_FASTEST_CLUSTER || v.clusterId != fastestClusterId.get()) 
      }
    hintTextCtor = @() "\n".join(clusterOptHintCfg.map(@(v)
      " ".concat(colorize("@darken", loc(v[0])), loc("ui/ndash"), v[1]())))
  }
]

let columnsWidth = saSize[0] - (2 * bgPanelPadding)
let columnsWidthUnits = columnsWidth * 1.0 / columnsCfg.reduce(@(acc, v) acc + (v?.relWidth ?? 0), 0)
columnsCfg.each(@(c) c.width <- (c.relWidth * columnsWidthUnits).tointeger())

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
  color = tabBgColor
  padding = bgPanelPadding
  valign = ALIGN_CENTER
}

let currentClustersComp = bgPanel.__merge({
  halign = ALIGN_CENTER
  padding = [bgPanelPadding, bgPanelPadding]
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
  padding = [bgPanelPadding, bgPanelPadding, hdpx(8), bgPanelPadding]
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
        { flow = FLOW_VERTICAL, valign = ALIGN_TOP, flowOffset = hdpx(80) })
    ]
  })
}

function mkClusterRow(cluster, userPrefClustersW) {
  let { clusterId } = cluster
  let valueW = Watched(userPrefClustersW.get()?[clusterId] != false)
  valueW.subscribe(@(v) userPrefClustersW.mutate(@(o) v == false
    ? (o[clusterId] <- v)
    : o.$rawdelete(clusterId)))
  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = columnsCfg.map(@(col) col.mkCell(col, cluster, valueW))
  }
}

let enableRefreshBtn = @() cooldownEndTime.set(0)

function onRefreshBtn() {
  if (!isServerTimeValid.get() || isWaitingManualRefresh.get() || cooldownEndTime.get() > serverTime.get())
    return
  cooldownEndTime.set(serverTime.get() + MANUAL_REFRESH_COOLDOWN_SEC)
  clustersRefreshNow(true, true)
}

let cdCircleSz = hdpxi(50)
function mkBtnSizeCooldownProgress(timeLeftSec, timeTotalSec) {
  if (timeLeftSec <= 0 || timeTotalSec == 0)
    return null
  let finishTime = serverTime.get() + timeLeftSec
  let shiftSec = ((gameStartServerTimeMsec.get() + get_time_msec()) % 1000) / 1000.0
  let from = (timeTotalSec - timeLeftSec + shiftSec) * 1.0 / timeTotalSec
  let duration = timeLeftSec - shiftSec
  return {
    size = [defButtonMinWidth, defButtonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      {
        key = "refreshCooldown"
        size = [cdCircleSz, cdCircleSz]
        margin = [0, hdpx(10), 0, 0]
        rendObj = ROBJ_PROGRESS_CIRCULAR
        image = Picture($"ui/gameuiskin#circular_progress_1.svg:{cdCircleSz}:{cdCircleSz}")
        fgColor = 0xFFFFFFFF
        bgColor = 0xFF6A6A6A
        fValue = 1
        animations = [
          { prop = AnimProp.fValue, from, to = 1.0, duration, onFinish = enableRefreshBtn, play = true }
        ]
      }
      @() mkText(format("%02d", max(0, finishTime - serverTime.get())), { watch = serverTime }.__merge(fontMonoSmall))
      mkText(loc("measureUnits/seconds"))
    ]
  }
}

let footer = @() {
  watch = cooldownEndTime
  size = FLEX_H
  halign = ALIGN_RIGHT
  children = cooldownEndTime.get() <= serverTime.get()
    ? textButtonCommon(utf8ToUpper(loc("mainmenu/btnRefresh")), onRefreshBtn)
    : mkBtnSizeCooldownProgress(cooldownEndTime.get() - serverTime.get(), MANUAL_REFRESH_COOLDOWN_SEC)
}

let clustersOptionsScene = bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    wndHeader
    @() {
      watch = [clusterStatsFixedOrder, userPreferredClusters]
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        currentClustersComp
        mkHeaderRow()
        bgPanel.__merge({
          padding = [bgPanelPadding, bgPanelPadding]
          size = FLEX_H
          flow = FLOW_VERTICAL
          gap = bgPanelPadding
          children = clusterStatsFixedOrder.get().map(@(v) mkClusterRow(v, userPreferredClusters))
        })
      ]
    }
    footer
  ]
  animations = wndSwitchAnim
})

registerScene("clustersOptionsScene", clustersOptionsScene, onClose, isOpened)

return {
  openClustersOptions = @() isOpened.set(true)
}
