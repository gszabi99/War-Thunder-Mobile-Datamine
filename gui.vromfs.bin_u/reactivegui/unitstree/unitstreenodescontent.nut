from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { abs } = require("math")
let { flagsWidth, bgLight, platesGap, mkTreeNodesFlag,
  flagTreeOffset, gamercardOverlap } = require("unitsTreeComps.nut")
let { unitsTreeOpenRank, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { curSelectedUnit, curUnitName, availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { doubleSidePannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { unseenArrowsBlockCtor, scrollHandler, scrollPos } = require("unitsTreeScroll.nut")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { filters, filterCount } = require("%rGui/unit/unitsFilterPkg.nut")
let { mkUnitPlate } = require("mkUnitPlate.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitPlateTiny } = require("%rGui/unit/components/unitPlateComp.nut")
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")


let lineWidth = hdpxi(2)
let nodePlatesSize = unitPlateTiny
let nodePlatesGap = [platesGap[0] * 3, platesGap[1]]
let nodeBlockSize = [nodePlatesSize[0] + nodePlatesGap[0], nodePlatesSize[1] + nodePlatesGap[1]]

let barHeight = hdpx(10)
let rankBlockHeight = hdpxi(60)
let rankBlockWidth = (rankBlockHeight * 3.3).tointeger()
let rankBlockGap = hdpx(40)
let rankBlockOffset = hdpx(15)
let gradientOffsetX = [hdpx(120), hdpx(120)]
let gradientOffsetY = [hdpx(3), hdpx(50)]

let nodes = Computed(@() serverConfigs.get()?.unitTreeNodes[curCampaign.get()])
let selectedCountry = mkWatched(persist, "selectedCountry", null)
let curCountry = Computed(@() nodes.get()?.findindex(@(_, country) country == selectedCountry.get())
  ?? nodes.get()?.keys()[0])

let filteredNodes = Computed(function(prev) {
  local res = nodes.get()?[curCountry.get()] ?? {}

  if (filterCount.get() > 0)
    foreach (f in filters) {
      let value = f.value.get()
      if (value != null)
        res = res.filter(@(node) f.isFit(allUnitsCfg.get()?[node.name], value))
    }

  local prevX = 0
  local xGaps = {}
  foreach (node in res.values().sort(@(a, b) a.x <=> b.x)) {
    node.xMod <- node.x
    if (node.x - prevX > 1)
      xGaps[node.x] <- (node.x - prevX - 1)
    prevX = node.x
    foreach (gapX, gapSize in xGaps)
      if (node.x >= gapX)
        node.xMod = (node?.xMod ?? node.x) - gapSize

  }

  local prevY = 0
  local yGaps = {}
  foreach (node in res.values().sort(@(a, b) a.y <=> b.y)) {
    node.yMod <- node.y
    if (node.y - prevY > 1)
      yGaps[node.y] <- (node.y - prevY - 1)
    prevY = node.y
    foreach (gapY, gapSize in yGaps)
      if (node.y >= gapY)
        node.yMod = (node?.yMod ?? node.y) - gapSize
  }

  return isEqual(prev, res) ? prev : res
})

let ranksCfg = Computed(function() {
  let res = {}
  foreach (node in filteredNodes.get()) {
    let { xMod, name } = node
    let rank = allUnitsCfg.get()[name]?.rank ?? 0
    if (rank not in res)
      res[rank] <- { from = xMod, to = xMod }
    else {
      if (res[rank].from > xMod)
        res[rank].from = xMod
      if (res[rank].to < xMod)
        res[rank].to = xMod
    }
  }
  return res
})

let unseenNodesIndex = Computed(function(prev) {
  let res = {}
  if (!isUnitsTreeOpen.get() || (unseenUnits.get().len() == 0 && unseenSkins.get().len() == 0))
    return res
  foreach (unit in availableUnitsList.get())
    if (unit.campaign in serverConfigs.get()?.unitTreeNodes
        && (unit.name in unseenUnits.get() || unit.name in unseenSkins.get())) {
      if (unit.country not in res)
        res[unit.country] <- {}
      res[unit.country][unit.name] <- ranksCfg.get()?[unit.rank].from ?? 0
    }
  return isEqual(prev, res) ? prev : res
})

let needShowArrowL = Computed(function() {
  let offsetIdx = (scrollPos.get() - flagTreeOffset + nodeBlockSize[0]).tofloat() / nodeBlockSize[0] - 1
  return null != unseenNodesIndex.get()?[curCountry.get()].findvalue(@(index) offsetIdx > index)
})

let needShowArrowR = Computed(function() {
  let offsetIdx = (scrollPos.get() + sw(100) - flagsWidth - flagTreeOffset).tofloat() / nodeBlockSize[0] - 1
  return null != unseenNodesIndex.get()?[curCountry.get()].findvalue(@(index) offsetIdx < index)
})

function scrollToUnit(name) {
  if (!name)
    return
  let { x = 1, y = 0 } = filteredNodes.get()?[name]
  let scrollPosX = nodeBlockSize[0] * (x - 0.5) - (0.2 * (saSize[0] - flagsWidth - flagTreeOffset))
  let scrollPosY = nodeBlockSize[1] * (y + 0.5) - (0.5 * (saSize[1] - gamercardHeight))
  scrollHandler.scrollToX(scrollPosX)
  scrollHandler.scrollToY(scrollPosY)
}

function scrollToRank(rank) {
  let scrollPosX = nodeBlockSize[0] * ((ranksCfg.get()?[rank].from ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

let function mkLinks(links, size) {
  let commands = []
  foreach (link in links) {
    let { x, y, pos } = link
    let height = max(1, abs(y))
    let width = max(1, abs(x))
    let relXStart = pos[0] / size[0] * 100
    let relXEnd = (pos[0] - nodePlatesGap[0] - (width - 1) * nodeBlockSize[0]) / size[0] * 100
    if (y == 0) {
      let relY = (pos[1] + nodePlatesSize[1] * 0.5) / size[1] * 100
      commands.append([VECTOR_LINE, relXStart, relY, relXEnd, relY])
    }
    else {
      let relXMiddle = (pos[0] - nodePlatesGap[0] * 0.5) / size[0] * 100
      let relYStart = (pos[1] + nodePlatesSize[1] * 0.5) / size[1] * 100
      let relYEnd = (pos[1] + nodePlatesSize[1] * 0.5 + height * nodeBlockSize[1] * (y > 0 ? -1 : 1)) / size[1] * 100
      commands.append(
        [VECTOR_LINE, relXStart, relYStart, relXMiddle, relYStart],
        [VECTOR_LINE, relXMiddle, relYStart, relXMiddle, relYEnd],
        [VECTOR_LINE, relXMiddle, relYEnd, relXEnd, relYEnd])
    }
  }

  return {
    size
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth
    commands
  }
}

let ranksBar = @(treeWidth) {
  watch = [scrollPos, ranksCfg]
  size = [SIZE_TO_CONTENT, rankBlockHeight]
  pos = [flagTreeOffset, - rankBlockHeight * 0.5]
  behavior = Behaviors.RtPropUpdate
  update = @() { transform = { translate = [-scrollPos.get(), 0] } }
  children = ranksCfg.get().map(function(cfg, rank) {
    let posX = nodePlatesGap[0] * 0.5 + nodeBlockSize[0] * (cfg.from - 1)
    let barWidth = nodeBlockSize[0] * (cfg.to - cfg.from + 1) - nodePlatesGap[0]
    let halfBar = (barWidth - rankBlockWidth) * 0.5 + hdpx(5)
    let rightBarWidth = scrollPos.get() + treeWidth - posX - halfBar - saBorders[0] - flagTreeOffset - gradientOffsetX[1]
    return @() {
      watch = scrollPos
      size = [barWidth, rankBlockHeight]
      pos = [posX, 0]
      valign = ALIGN_CENTER
      opacity = scrollPos.get() >= (posX + (barWidth - rankBlockWidth) * 0.5)
        || rightBarWidth <= 0
            ? 0.0
          : 1.0
      transitions = [{ prop = AnimProp.opacity, duration = 0.2, easing = InOutQuad }]
      children = [
        {
          size = [halfBar, barHeight]
          hplace = ALIGN_LEFT
          children = {
            hplace = ALIGN_RIGHT
            size = [halfBar - max(scrollPos.get() - posX, 0), barHeight]
            rendObj = ROBJ_SOLID
            color = playerExpColor
          }
        }
        {
          size = [halfBar, barHeight]
          hplace = ALIGN_RIGHT
          children = {
            hplace = ALIGN_LEFT
            size = [min(rightBarWidth, halfBar), barHeight]
            rendObj = ROBJ_SOLID
            color = playerExpColor
          }
        }
        {
          size = [rankBlockWidth, rankBlockHeight]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#header_rank_bg.svg:0:P")
          keepAspect = true
          hplace = ALIGN_CENTER
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = hdpx(8)
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("options/mRank")
            }.__update(fontTinyShaded)
            mkGradRankSmall(rank)
          ]
        }
      ]
    }
  }).values()
}

let function mkUnitsNode(name, pos) {
  let xmbNode = XmbNode()
  return @() {
    watch = allUnitsCfg
    children = mkUnitPlate(allUnitsCfg.get()[name], xmbNode, { pos, size = nodePlatesSize })
  }
}

local listWatches = [curSelectedUnit, filteredNodes, curCountry, filterCount]
foreach (f in filters)
  listWatches.append(f?.value, f?.allValues)
listWatches = listWatches.filter(@(w) w != null)

let function unitsTree() {
  local positions = {}
  local nodesSize = { xMax = 0, yMax = 0 }
  local links = []

  foreach (node in filteredNodes.get()) {
    let { xMod, yMod, name, reqUnits } = node
    let pos = [
      nodeBlockSize[0] * (xMod - 1) + nodePlatesGap[0] * 0.5 + flagTreeOffset,
      nodeBlockSize[1] * yMod + nodePlatesGap[1] * (yMod == 0 ? 0 : 0.5) + rankBlockGap]
    positions[name] <- pos
    if (xMod > nodesSize.xMax)
      nodesSize.xMax = xMod
    if (yMod > nodesSize.yMax)
      nodesSize.yMax = yMod

    foreach (unit in reqUnits) {
      let reqUnitCfg = filteredNodes.get()?[unit]
      if (!reqUnitCfg)
        continue
      links.append({
        x = xMod - reqUnitCfg.xMod
        y = yMod - reqUnitCfg.yMod
        pos
      })
    }
  }

  let size = [
    max(sw(100),
      nodesSize.xMax * nodeBlockSize[0] + (!curSelectedUnit.get() ? 0 : (statsWidth + nodePlatesGap[0] + saBorders[0]))
        + saBorders[0] + flagTreeOffset),
    max(sh(100),
      nodesSize.yMax * nodeBlockSize[1] + nodePlatesGap[1] + gradientOffsetY[1]
        + saBorders[1]  + gamercardHeight - gamercardOverlap + rankBlockHeight * 0.5 - rankBlockOffset)
  ]

  return {
    watch = listWatches
    size
    onAttach = @() defer(@() unitsTreeOpenRank.get() != null
        ? scrollToRank(unitsTreeOpenRank.get())
      : scrollToUnit(curSelectedUnit.get() ?? curUnitName.get()))
    children = [
      {
        size = [size[0], nodeBlockSize[1] + rankBlockGap * 0.5]
      }.__merge(bgLight)
      {
        size = flex()
        pos = [0, rankBlockHeight]
        behavior = Behaviors.Button
        onClick = @() isLvlUpAnimated.get() ? null : curSelectedUnit.set(null)
      }
      mkLinks(links, size)
    ].extend(filteredNodes.get().values().map(@(n) mkUnitsNode(n.name, positions[n.name])) ?? [])
  }
}

let pannableArea = doubleSidePannableAreaCtor(
  sw(100) - saBorders[0] - flagsWidth - flagTreeOffset,
  sh(100) - saBorders[1] - gamercardHeight + gamercardOverlap - rankBlockHeight,
  gradientOffsetX,
  gradientOffsetY)

let function unitsTreeNodesContent() {
  let size = [
    sw(100) - saBorders[0] - flagsWidth - flagTreeOffset,
    sh(100) - saBorders[1] - gamercardHeight + gamercardOverlap - rankBlockHeight]
  return [
    {
      size
      pos = [
        saBorders[0] + flagsWidth,
        saBorders[1] + gamercardHeight - gamercardOverlap + (rankBlockHeight + rankBlockOffset) * 0.5]
      onAttach = @() selectedCountry.set(hangarUnit.get()?.country)
      children = [
        pannableArea(
          unitsTree,
          {},
          {
            behavior = [Behaviors.Pannable, Behaviors.ScrollEvent]
            scrollHandler
            xmbNode = {
              canFocus = false
              scrollSpeed = 2.5
              isViewport = true
              scrollToEdge = false
              screenSpaceNav = true
            }
          })
        @() ranksBar(size[0])
        unseenArrowsBlockCtor(needShowArrowL, needShowArrowR, { pos = [0, hdpx(5)] })
      ]
    }
    @() {
      watch = nodes
      pos = [saBorders[0], rankBlockHeight + gamercardHeight + saBorders[1] - gamercardOverlap]
      flow = FLOW_VERTICAL
      children = nodes.get().keys()
        .map(@(country) mkTreeNodesFlag(
          country,
          curCountry,
          @() selectedCountry.set(country),
          Computed(@() country in unseenNodesIndex.get())
        ))
    }
  ]
}

return unitsTreeNodesContent
