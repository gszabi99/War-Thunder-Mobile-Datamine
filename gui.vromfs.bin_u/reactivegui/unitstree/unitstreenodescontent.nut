from "%globalsDarg/darg_library.nut" import *
let { PI, sin } = require("math")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { flagsWidth, bgLight, mkTreeNodesFlag, flagTreeOffset, gamercardOverlap
} = require("unitsTreeComps.nut")
let { unitsTreeOpenRank, isUnitsTreeOpen } = require("%rGui/unitsTree/unitsTreeState.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { curSelectedUnit, curUnitName, availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { isSlotsAnimActive, selectedSlotIdx } = require("%rGui/slotBar/slotBarState.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { doubleSidePannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { unseenArrowsBlockCtor, scrollHandler, scrollPos, startAnimScroll, interruptAnimScroll
} = require("unitsTreeScroll.nut")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { mkTreeNodesUnitPlate } = require("mkUnitPlate.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitPlateTiny } = require("%rGui/unit/components/unitPlateComp.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { unseenUnits, markUnitSeen } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { selectedCountry, mkVisibleNodes, mkFilteredNodes, mkCountryNodesCfg, mkCountries,
  setResearchedUnitsSeen, currentResearch, researchCountry, unitsResearchStatus, unseenResearchedUnits,
  setUnitToScroll, unitToScroll, unitInfoToScroll
} = require("unitsTreeNodesState.nut")
let { slotBarUnitsTree, slotBarTreeHeight } = require("%rGui/slotBar/slotBar.nut")
let { curCampaign, isCampaignWithSlots } = require("%appGlobals/pServer/campaign.nut")
let { rankBlockOffset } = require("unitsTreeConsts.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { animUnitWithLink, animNewUnitsAfterResearch, isBuyUnitWndOpened,
  animUnitAfterResearch, canPlayAnimUnitWithLink, hasAnimDarkScreen, resetAnim,
  animBuyRequirementsUnitId, animBuyRequirements, animResearchRequirementsUnitId, animResearchRequirements
  animResearchRequirementsAncestors, animNewUnitsAfterResearchTrigger
} = require("animState.nut")
let { attractColor } = require("treeAnimConsts.nut")

let aTimeAppearLink = 1
let aTimeChangeLink = 0.5
let aTimeDimmingScreen = 0.4
let aTimeShowRequirements = 1
let darkScreenAnim = [
  { play = true, prop = AnimProp.opacity, from = 0, to = 1,
    duration = aTimeDimmingScreen, onFinish = @() hasAnimDarkScreen.set(false) }
]

let lineWidth = evenPx(4)
let nodePlatesSize = unitPlateTiny
let nodePlatesGap = [(hdpx(84) / 6 + 0.5).tointeger() * 6, evenPx(56)]
let nodeBlockSize = [nodePlatesSize[0] + nodePlatesGap[0], nodePlatesSize[1] + nodePlatesGap[1]]
let calcAreaSize = @(hasSlotbar) [
  sw(100) - 2 * saBorders[0] - flagsWidth - flagTreeOffset,
  sh(100) - 2 * saBorders[1] - gamercardHeight + gamercardOverlap - (hasSlotbar ? slotBarTreeHeight : 0)
]
let gradientOffsetX = [hdpx(120), hdpx(120)]
let gradientOffsetY = [hdpx(3), hdpx(50)]
let linkColor = 0xFFC0C0C0
let linkColorGrey = 0xFF808080
let linkColorLocked = 0xFFC03030

let gapLineX3 = nodePlatesGap[0] / 3
let gapLineX2 = nodePlatesGap[0] / 2
let halfSizeX = nodePlatesSize[0] / 2
let halfSizeY = nodePlatesSize[1] / 2

let flagBtnHeightMax = evenPx(120)
let flagBtnHeightMin = evenPx(70)
let flagBtnGapMax = evenPx(44)
let flagBtnGapMin = evenPx(4)

let isTreeNodesAttached = Watched(false)

let startResearchedAnimData = keepref(Computed(@()
  hasModalWindows.get() || !isTreeNodesAttached.get() || animNewUnitsAfterResearch.get().len() == 0 ? null
    : animNewUnitsAfterResearch.get()))

function startResearchedAnimIfNeed() {
  if (startResearchedAnimData.get() != null)
    anim_start(animNewUnitsAfterResearchTrigger)
}
startResearchedAnimData.subscribe(@(_) resetTimeout(0.05, startResearchedAnimIfNeed))

function getFlagBtnSizes(areaHeight, btnCount) {
  local flagBtnHeight = flagBtnHeightMax
  local flagBtnGap = flagBtnGapMax
  let maxHeight = flagBtnHeight * btnCount + flagBtnGap * (btnCount + 1)
  if (maxHeight > areaHeight) {
    flagBtnHeight = max(flagBtnHeightMin, flagBtnHeightMax - 2 * ((maxHeight - areaHeight) / btnCount * 0.6 / 2))
    flagBtnGap = max(flagBtnGapMin, (areaHeight - btnCount * flagBtnHeight) / (btnCount + 1))
  }
  return { flagBtnHeight, flagBtnGap }
}

let mkRanksCfg = @(countryNodesCfg) Computed(function() {
  let res = {}
  foreach (node in countryNodesCfg.get().nodes) {
    let { x, name } = node
    let rank = campUnitsCfg.get()[name]?.rank ?? 0
    if (rank not in res)
      res[rank] <- { from = x, to = x }
    else {
      if (res[rank].from > x)
        res[rank].from = x
      if (res[rank].to < x)
        res[rank].to = x
    }
  }
  return res
})

let mkUnseenNodesIndex = @(ranksCfg) Computed(function(prev) {
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

let needShowArrowL = @(curCountry, unseenNodesIndex) Computed(function() {
  let offsetIdx = (scrollPos.get() - flagTreeOffset + nodeBlockSize[0]).tofloat() / nodeBlockSize[0] - 1
  return null != unseenNodesIndex.get()?[curCountry.get()].findvalue(@(index) offsetIdx > index)
})

let needShowArrowR = @(curCountry, unseenNodesIndex, areaSize) Computed(function() {
  let offsetIdx = (scrollPos.get() + areaSize.get()[0] + saBorders[0]).tofloat() / nodeBlockSize[0] - 1
  return null != unseenNodesIndex.get()?[curCountry.get()].findvalue(@(index) offsetIdx < index)
})

isUnitsTreeOpen.subscribe(@(v) v || currentResearch.get() == null ? null : selectedCountry.set(null))

function getUnitCoordsRange(names, nodeList) {
  local x1 = null
  local x2 = null
  local y1 = null
  local y2 = null
  foreach(name in names) {
    let node = nodeList?[name]
    if (node == null)
      continue
    let { x, y } = node
    x1 = min(x1 ?? x, x)
    x2 = max(x2 ?? x, x)
    y1 = min(y1 ?? y, y)
    y2 = max(y2 ?? y, y)
  }
  return x1 == null ? null : { x1, x2, y1, y2 }
}

function calcBoundaries(names, nodeList, areaSizeV) {
  let coords = getUnitCoordsRange(names, nodeList)
  if (coords == null)
    return null
  let { x1, y1, x2, y2 } = coords
  let minX = x2 * nodeBlockSize[0] + 0.5 * flagTreeOffset - areaSizeV[0] + statsWidth
  let minY = y2 * nodeBlockSize[1] - areaSizeV[1]
  let maxX = (x1 - 1) * nodeBlockSize[0] + 0.8 * flagTreeOffset
  let maxY = (y1 - 1) * nodeBlockSize[1]
  return { minX, minY, maxX, maxY }
}

function scrollAnimToUnitGroup(names, nodeList, areaSize) {
  let curX = scrollHandler.elem?.getScrollOffsX() ?? 0
  let curY = scrollHandler.elem?.getScrollOffsY() ?? 0
  let boundaries = calcBoundaries(names, nodeList, areaSize.get())
  if (boundaries == null)
    return
  let { minX, minY, maxX, maxY } = boundaries
  startAnimScroll([
    maxX <= minX ? maxX : clamp(curX, minX, maxX),
    maxY <= minY ? maxY : clamp(curY, minY, maxY)
  ])
}

function scrollToUnitGroupRight(names, nodeList, areaSize) {
  let boundaries = calcBoundaries(names, nodeList, areaSize.get())
  if (boundaries == null)
    return
  interruptAnimScroll()
  let { minX, minY, maxX, maxY } = boundaries
  scrollHandler.scrollToX(max(minX, maxX))
  scrollHandler.scrollToY((minY + maxY) / 2)
}

function scrollToUnitGroupBottom(names, nodeList, areaSize) {
  let boundaries = calcBoundaries(names, nodeList, areaSize.get())
  if (boundaries == null)
    return
  interruptAnimScroll()
  let { minX, minY, maxX, maxY } = boundaries
  scrollHandler.scrollToX((minX + maxX) / 2)
  scrollHandler.scrollToY(min(minY, maxY))
}

curSelectedUnit.subscribe(function(v) {
  if (isTreeNodesAttached.get() && v)
    setUnitToScroll(v, true)
})

function scrollToRank(rank, ranksCfg) {
  interruptAnimScroll()
  let scrollPosX = nodeBlockSize[0] * ((ranksCfg?[rank].from ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

let mkLinks = @(linksCfg) function() {
  let { linesFrom, linesTo } = linksCfg
  let own = campMyUnits.get()
  let status = unitsResearchStatus.get()
  let animUnlockUnit = animUnitWithLink.get()
  let animLockUnit = animBuyRequirementsUnitId.get() ?? animResearchRequirementsUnitId.get()
  let animLockReq = animBuyRequirements.get().len() > 0 ? animBuyRequirements.get() : animResearchRequirements.get()
  let animLockAncs = animResearchRequirementsAncestors.get()
  let canPlayAnim = canPlayAnimUnitWithLink.get()
  let commands = []
  let animUnlockCommands = []
  let animLockCommands = []

  foreach(reqNames, cmds in linesFrom) {
    let isStr = type(reqNames) == "string"
    let hasAccess = isStr ? reqNames in own : null == reqNames.findvalue(@(name) name not in own)
    if (hasAccess && (isStr ? animUnlockUnit == reqNames : reqNames.contains(animUnlockUnit))) {
      if (canPlayAnim)
        animUnlockCommands.extend(cmds)
      else {
        commands.append([VECTOR_COLOR, linkColorLocked])
        commands.extend(cmds)
      }
    }
    else if (!hasAccess && (isStr ? reqNames in animLockReq : null != reqNames.findvalue(@(n) n in animLockReq)))
      animLockCommands.extend(cmds)
    else {
      commands.append([VECTOR_COLOR, hasAccess ? linkColor : linkColorLocked])
      commands.extend(cmds)
    }
  }

  foreach(cfg in linesTo) {
    let { name, reqUnits, cmd } = cfg
    let isList = type(name) == "array"
    let hasAccess = (status?[name].canBuy ?? !isList)
      || (null == reqUnits.findvalue(@(n) n not in own))

    if (hasAccess && reqUnits.contains(animUnlockUnit)) {
      if (canPlayAnim)
        animUnlockCommands.append(cmd)
      else
        commands.append([VECTOR_COLOR, linkColorLocked], cmd)
    }
    else if (!hasAccess
        && (name == animLockUnit
          || (!animLockAncs?[name] && name in animLockReq)
          || (isList && name.contains(animLockUnit))
          || (isList && null != name.findvalue(@(n) n in animLockReq)
            && null != reqUnits.findvalue(@(n) n in animLockReq))))
      animLockCommands.append(cmd)
    else
      commands.append([VECTOR_COLOR, hasAccess ? linkColor : linkColorLocked], cmd)
  }

  return {
    watch = [unitsResearchStatus, campMyUnits, animUnitWithLink, canPlayAnimUnitWithLink,
      animBuyRequirementsUnitId, animBuyRequirements, animResearchRequirements, animResearchRequirementsUnitId,
      animResearchRequirementsAncestors
    ]
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth
    commands
    children = animUnlockCommands.len() != 0
        ? {
          key = animUnitWithLink
          size = flex()
          rendObj = ROBJ_VECTOR_CANVAS
          lineWidth
          commands = animUnlockCommands
          color = linkColor
          animations = [
            {
              prop = AnimProp.color, duration = aTimeAppearLink, easing = @(x) sin(2 * PI * x),
              from = linkColorLocked, to = linkColorGrey, play = true
            }
            {
              prop = AnimProp.color, duration = aTimeChangeLink, delay = aTimeAppearLink, easing = OutQuad,
              from = linkColorLocked, to = linkColor, play = true,
              function onFinish() {
                animUnitWithLink.set(null)
                canPlayAnimUnitWithLink.set(false)
                hasAnimDarkScreen.set(true)
              }
            }
          ]
        }
      : animLockCommands.len() != 0
        ? {
          key = animBuyRequirementsUnitId
          size = flex()
          rendObj = ROBJ_VECTOR_CANVAS
          lineWidth
          commands = animLockCommands
          color = linkColorLocked
          animations = [{
            prop = AnimProp.color, duration = aTimeShowRequirements, easing = CosineFull,
            to = attractColor, play = true, loop = true
          }]
        }
      : null
  }
}

function getNodesMinX(nodes, positions) {
  local res = null
  foreach(node in nodes) {
    let pos = positions[node.name][0]
    if (res == null || res > pos)
      res = pos
  }
  return res
}

function getReqMaxX(reqUnits, positions) {
  local res = null
  foreach(name in reqUnits) {
    let pos = positions[name][0]
    if (res == null || res < pos)
      res = pos
  }
  return res
}

function fillComplexLineTo(x, posListTo, reqUnits, addLineTo) {
  posListTo.sort(@(a, b) a.y <=> b.y)
  local prevY = posListTo[0].y
  local isMiddleFound = false
  local prevNames = {}
  foreach(pInfo in posListTo) {
    let { y, name = null } = pInfo
    if (y != prevY)
      addLineTo(prevNames.keys(), reqUnits, x, prevY, x, y)

    prevY = y
    if (name == null) {
      prevNames = posListTo.reduce(@(res, n) n?.name == null || n.name in prevNames ? res : res.$rawset(n.name, true), {})
      isMiddleFound = true
    }
    else if (!isMiddleFound)
      prevNames[name] <- true
    else if (name in prevNames)
      prevNames.$rawdelete(name)
  }
}

function genLinks(nodes, positions, size) {
  let groups = {}
  foreach (node in nodes) {
    let { reqUnits } = node
    if (reqUnits.len() == 0)
      continue
    let uid = ";".join(reqUnits.sort())
    if (uid not in groups)
      groups[uid] <- { reqUnits, tgtNodes = [] }
    groups[uid].tgtNodes.append(node)
  }

  let mulX = 100.0 / size[0]
  let mulY = 100.0 / size[1]
  let linesFrom = {}
  function addLineFrom(name, x1, y1, x2, y2) {
    if (name not in linesFrom)
      linesFrom[name] <- []
    linesFrom[name].append([VECTOR_LINE, x1 * mulX, y1 * mulY, x2 * mulX, y2 * mulY])
  }
  let linesTo = []
  let addLineTo = @(name, reqUnits, x1, y1, x2, y2) linesTo.append({
    name, reqUnits
    cmd = [VECTOR_LINE, x1 * mulX, y1 * mulY, x2 * mulX, y2 * mulY]
  })

  foreach (group in groups) {
    let { reqUnits, tgtNodes } = group
    let reqWithPos = reqUnits.filter(@(u) u in positions)

    //******************** No reqUnits with known position ********************//
    if (reqWithPos.len() == 0) {
      foreach(node in tgtNodes) {
        let pos = positions[node.name]
        let y = pos[1] + halfSizeY
        addLineTo(node.name, reqUnits, pos[0] - gapLineX2, y, pos[0], y)
      }
      continue
    }

    if (reqWithPos.len() == 1) { //******************** only 1 reqUnits with known position ********************//
      let reqName = reqWithPos[0]
      let reqPos = positions[reqName]

      if (tgtNodes.len() == 1) {
        let { name } = tgtNodes[0]
        let pos = positions[name]
        if (pos[0] == reqPos[0]) {
          let x = pos[0] + halfSizeX
          let y1 = reqPos[1] + nodePlatesSize[1]
          let yMid = (y1 + pos[1]) / 2
          addLineFrom(reqName, x, y1, x, yMid)
          addLineTo(name, reqUnits, x, yMid, x, pos[1])
        }
        else {
          let isSameY = pos[1] == reqPos[1]
          let y1 = reqPos[1] + halfSizeY
          let y2 = pos[1] + halfSizeY
          let x1 = reqPos[0] + nodePlatesSize[0]
          let xMid = isSameY ? (x1 + pos[0]) / 2 : pos[0] - gapLineX2
          addLineFrom(reqName, x1, y1, xMid, y1) //--param-pos
          if (!isSameY)
            addLineFrom(reqName, xMid, y1, xMid, y2)
          addLineTo(name, reqUnits, xMid, y2, pos[0], y2) //--param-pos
        }
        continue
      }

      let xMid = getNodesMinX(tgtNodes, positions) - gapLineX2
      let reqY = reqPos[1] + halfSizeY
      let posListTo = [{ y = reqY }]
      foreach(node in tgtNodes) {
        let pos = positions[node.name]
        let y = pos[1] + halfSizeY
        posListTo.append({ y, name = node.name })
        addLineTo(node.name, reqUnits, xMid, y, pos[0], y)
      }
      addLineFrom(reqName, reqPos[0] + nodePlatesSize[0], reqY, xMid, reqY)
      fillComplexLineTo(xMid, posListTo, reqUnits, addLineTo)
      continue
    }

    //******************** several reqUnits with known position ********************//
    let isSingleTgt = tgtNodes.len() == 1
    let xMid1 = isSingleTgt ? getReqMaxX(reqWithPos, positions) + nodePlatesSize[0] + gapLineX2
      : getNodesMinX(tgtNodes, positions) - 2 * gapLineX3
    let xMid2 = isSingleTgt ? xMid1 : xMid1 + gapLineX3
    let yMid = halfSizeY + tgtNodes.reduce(@(res, n) res + positions[n.name][1], 0) / tgtNodes.len()

    let toName = isSingleTgt ? tgtNodes[0].name : tgtNodes.map(@(n) n.name)
    addLineTo(toName, reqUnits, xMid1, yMid, xMid2, yMid)

    let posListTo = [{ y = yMid }]
    foreach(node in tgtNodes) {
      let { name } = node
      let pos = positions[name]
      let y = pos[1] + halfSizeY
      posListTo.append({ y, name = node.name })
      addLineTo(name, reqUnits, xMid2, y, pos[0], y)
    }
    fillComplexLineTo(xMid2, posListTo, reqUnits, addLineTo)

    let posListFrom = [{ y = yMid }]
    foreach(reqName in reqWithPos) {
      let pos = positions[reqName]
      let y = pos[1] + halfSizeY
      posListFrom.append({ y, name = reqName })
      addLineFrom(reqName, pos[0] + nodePlatesSize[0], y, xMid1, y)
    }

    posListFrom.sort(@(a, b) a.y <=> b.y)
    local prevY = posListFrom[0].y
    local isMiddleFound = false
    local prevReq = {}
    foreach(pInfo in posListFrom) {
      let { y, name = null } = pInfo
      if (y != prevY) {
        let req = prevReq.keys()
        addLineFrom(req.len() == 1 ? req[0] : req, xMid1, prevY, xMid1, y)
      }

      prevY = y
      if (name == null) {
        prevReq = reqWithPos.reduce(@(res, n) n in prevReq ? res : res.$rawset(n, true), {})
        isMiddleFound = true
      }
      else if (!isMiddleFound)
        prevReq[name] <- true
      else if (name in prevReq)
        prevReq.$rawdelete(name)
    }
  }

  return { linesFrom, linesTo }
}

let function mkUnitsNode(name, pos, hasDarkScreenV) {
  let xmbNode = XmbNode()
  let unit = Computed(@() campMyUnits.get()?[name] ?? campUnitsCfg.get()?[name])
  let watch = unit
  return function() {
    let curUnit = unit.get()
    return curUnit == null ? { watch }
      : {
          watch
          children = mkTreeNodesUnitPlate(
            curUnit,
            xmbNode,
            {
              pos,
              onClick = function() {
                if (hasDarkScreenV && !currentResearch.get() && !unitsResearchStatus.get()?[name].canResearch)
                  return
                curSelectedUnit.set(name)
                markUnitSeen(curUnit)
                if(name in unseenResearchedUnits.get()?[selectedCountry.get()])
                  setResearchedUnitsSeen({ [name] = true })
              }
            })
        }
  }
}

let function selectCountryByCurResearch() {
  let lastResUnitName = servProfile.get()?.levelInfo[curCampaign.get()].lastResearchedUnit ?? ""
  let lastResUnit = unitsResearchStatus.get()?[lastResUnitName]
  selectedCountry.set(researchCountry.get() ?? lastResUnit?.country )
}

let getCardPos = @(node) [
  nodeBlockSize[0] * (node.x - 1) + nodePlatesGap[0] / 2 + flagTreeOffset,
  nodeBlockSize[1] * (node.y - 1) + (node.y == 0 ? 0 : nodePlatesGap[1] / 2)
]

function mkHasDarkScreen() {
  let isPlayingAnyAnim = Computed(@() animUnitWithLink.get() != null
    || animNewUnitsAfterResearch.get().len() > 0
    || animUnitAfterResearch.get() != null
    || isBuyUnitWndOpened.get())
  return Computed(@() !currentResearch.get() && !isSlotsAnimActive.get() && !isPlayingAnyAnim.get()
    && unitsResearchStatus.get().filter(@(val) val.canResearch == true).len() > 0)
}

let mkDarkScreen = @(size, positions) function() {
  let boxes = positions.reduce(@(res, pos, name)
    !unitsResearchStatus.get()?[name].canResearch ? res
      : res.append({
        l = pos[0], r = pos[0] + nodePlatesSize[0],
        t = pos[1], b = pos[1] + nodePlatesSize[1]
      }), [])
  return {
    size = flex()
    watch = unitsResearchStatus
    children = {
      size = flex()
      children = mkCutBg(boxes, { l = -sw(50), r = size[0] + sw(50), t = -sh(50), b = size[1] + sh(50) })
      animations = hasAnimDarkScreen.get() ? darkScreenAnim : null
    }
  }
}

let mkUnitsTree = @(countryNodesCfg, hasDarkScreenV) function() {
  let { xMax, yMax, nodes } = countryNodesCfg.get()
  let size = [
    xMax * nodeBlockSize[0] + saBorders[0] + flagTreeOffset,
    yMax * nodeBlockSize[1] + nodePlatesGap[1] + gradientOffsetY[1]
      + saBorders[1]  + gamercardHeight - gamercardOverlap
  ]
  let positions = nodes.map(getCardPos)
  return {
    watch = countryNodesCfg
    size
    children = [
      mkLinks(genLinks(nodes, positions, size))
    ]
      .extend(nodes.values().map(@(n) mkUnitsNode(n.name, positions[n.name], hasDarkScreenV)))
      .append(hasDarkScreenV ? mkDarkScreen(size, positions) : null)
  }
}

let mkUnitsTreeFull = @(countryNodesCfg, hasDarkScreenV, areaSizeV) {
  minWidth = areaSizeV[0]
  minHeight = areaSizeV[1]
  behavior = Behaviors.Button
  function onClick() {
    if (!isLvlUpAnimated.get()) {
      curSelectedUnit.set(null)
      selectedSlotIdx.set(null)
    }
  }
  children = [
    {
      size = [flex(), nodeBlockSize[1]]
      minWidth = areaSizeV[0]
    }.__merge(bgLight)
    {
      flow = FLOW_HORIZONTAL
      children = [
        mkUnitsTree(countryNodesCfg, hasDarkScreenV)
        @() {
          watch = curSelectedUnit
          size = [(curSelectedUnit.get() == null ? 0 : statsWidth + nodePlatesGap[0]), 0]
        }
      ]
    }
  ]
}

function onUnitNodesAppear(prevCountry, nodes, areaSize) {
  let unitExists = @(name) name != null && nodes?[name] != null
  let hasSelectedUnit = curSelectedUnit.get() != null
  let uToScroll = hasSelectedUnit ? curSelectedUnit.get() : unitToScroll.get()

  if (unitExists(uToScroll)) {
    scrollToUnitGroupBottom([uToScroll], nodes, areaSize)
    return
  }

  let resCountry = researchCountry.get()
  let canScrollToActiveResearch = resCountry != null && prevCountry == resCountry

  let unitNames = nodes
    .filter(function(n) {
      let { canResearch = false, isCurrent = false } = unitsResearchStatus.get()?[n.name]
      return canScrollToActiveResearch ? isCurrent : canResearch
    })
    .keys()
  if (unitNames.len() != 0) {
    if (canScrollToActiveResearch || unitNames.len() == 1)
      scrollToUnitGroupBottom(unitNames, nodes, areaSize)
    else
      scrollToUnitGroupRight(unitNames, nodes, areaSize)
    return
  }

  let curSelectedU = curSelectedUnit.get()
  if (unitExists(curSelectedU)) {
    scrollToUnitGroupBottom([curSelectedU], nodes, areaSize)
    return
  }
  let curHangarU = curUnitName.get()
  if (unitExists(curHangarU))
    scrollToUnitGroupBottom([curHangarU], nodes, areaSize)
}

let onAnimChange = @(unitId, nodes, areaSize) @(v) scrollAnimToUnitGroup(
  v.keys()
    .filter(@(name) name not in campMyUnits.get())
    .append(unitId),
  nodes,
  areaSize
)

let mkFlagButtons = @(allCountries, curCountry, areaSize, unseenNodesIndex) function() {
  let { flagBtnHeight, flagBtnGap } = getFlagBtnSizes(areaSize.get()[1], allCountries.get().len())
  return {
    watch = [allCountries, researchCountry, areaSize]
    pos = [saBorders[0], gamercardHeight + saBorders[1] - gamercardOverlap + flagBtnGap]
    flow = FLOW_VERTICAL
    gap = flagBtnGap
    children = allCountries.get()
      .map(@(country) mkTreeNodesFlag(
        flagBtnHeight
        country,
        curCountry,
        function () {
          setResearchedUnitsSeen(unseenResearchedUnits.get()?[selectedCountry.get()] ?? {})
          selectedCountry.set(country)
        },
        Computed(@() (unseenResearchedUnits.get()?[country].len() ?? 0) > 0 || country in unseenNodesIndex.get()),
        researchCountry.get()
      ))
  }
}

function getLightBox(areaSizeV) {
  let offsetX = saBorders[0] + flagsWidth
  let offsetY = saBorders[1] + gamercardHeight - gamercardOverlap + rankBlockOffset
  return { l = offsetX, r = offsetX + areaSizeV[0], t = offsetY, b = offsetY + areaSizeV[1] }
}

let mkAreaPannable = @(areaSize) doubleSidePannableAreaCtor(
  areaSize[0],
  areaSize[1],
  gradientOffsetX,
  gradientOffsetY)
let pannableArea = mkAreaPannable(calcAreaSize(false))
let pannableAreaWithSlobar = mkAreaPannable(calcAreaSize(true))

let contentKey = {}
let pannableKey = {}
let function mkUnitsTreeNodesContent() {
  let visibleNodes = mkVisibleNodes()
  let filteredNodes = mkFilteredNodes(visibleNodes)
  let allCountries = mkCountries(filteredNodes)
  let curCountry = Computed(@() allCountries.get().contains(selectedCountry.get())
    ? selectedCountry.get()
    : allCountries.get()?[0])
  let countryNodesCfg = mkCountryNodesCfg(filteredNodes, curCountry)
  let ranksCfg = mkRanksCfg(countryNodesCfg)
  let unseenNodesIndex = mkUnseenNodesIndex(ranksCfg)
  let hasDarkScreen = mkHasDarkScreen()
  let areaSize = Computed(@() calcAreaSize(isCampaignWithSlots.get()))

  function onUnitToScrollChange(v) {
    if (v == null)
      return
    let { isAnimated = false } = unitInfoToScroll.get()
    if (isAnimated)
      scrollAnimToUnitGroup([v], countryNodesCfg.get().nodes, areaSize)
    else
      scrollToUnitGroupBottom([v], countryNodesCfg.get().nodes, areaSize)
    deferOnce(@() setUnitToScroll(null))
  }
  let onAnimBuyChange = onAnimChange(animBuyRequirementsUnitId.get(), countryNodesCfg.get().nodes, areaSize)
  let onAnimResearchChange = onAnimChange(animResearchRequirementsUnitId.get(), countryNodesCfg.get().nodes, areaSize)
  let onCountryChange = @(val) onUnitNodesAppear(val, countryNodesCfg.get().nodes, areaSize)
  return [
    @() {
      watch = areaSize
      key = contentKey
      size = areaSize.get()
      pos = [
        saBorders[0] + flagsWidth,
        saBorders[1] + gamercardHeight - gamercardOverlap + rankBlockOffset]
      function onAttach() {
        unitToScroll.subscribe(onUnitToScrollChange)
        animBuyRequirements.subscribe(onAnimBuyChange)
        animResearchRequirements.subscribe(onAnimResearchChange)
        selectedCountry.subscribe(onCountryChange)
        if (unitToScroll.get() == null && selectedCountry.get() == null)
          selectCountryByCurResearch()
        deferOnce(@() unitToScroll.get() != null ? onUnitToScrollChange(unitToScroll.get())
          : unitsTreeOpenRank.get() != null ? scrollToRank(unitsTreeOpenRank.get(), ranksCfg.get())
          : onUnitNodesAppear(selectedCountry.get(), countryNodesCfg.get().nodes, areaSize))
        isTreeNodesAttached.set(true)
      }
      function onDetach() {
        isTreeNodesAttached.set(false)
        unitToScroll.unsubscribe(onUnitToScrollChange)
        animBuyRequirements.unsubscribe(onAnimBuyChange)
        animResearchRequirements.unsubscribe(onAnimResearchChange)
        selectedCountry.unsubscribe(onCountryChange)
        resetAnim()
        setResearchedUnitsSeen(unseenResearchedUnits.get().reduce(function(res, units) {
          foreach (unit, _ in units)
            res[unit] <- true
          return res
        }, {}))
      }
      children = [
        @() (isCampaignWithSlots.get() ? pannableAreaWithSlobar : pannableArea)(
          mkUnitsTreeFull(countryNodesCfg, hasDarkScreen.get(), areaSize.get()),
          {
            key = pannableKey
            watch = [hasDarkScreen, areaSize, isCampaignWithSlots]
            rendObj = !hasDarkScreen.get() ? ROBJ_MASK : null
          },
          {
            behavior = [Behaviors.Pannable, Behaviors.ScrollEvent]
            scrollHandler
            kineticAxisLockAngle = 30
            xmbNode = XmbContainer()
          })
        unseenArrowsBlockCtor(
          needShowArrowL(curCountry, unseenNodesIndex),
          needShowArrowR(curCountry, unseenNodesIndex, areaSize),
          { pos = [0, hdpx(5)] })
      ]
    }
    @() {
      size = [sw(100), sh(100)]
      watch = [hasDarkScreen, isCampaignWithSlots]
      children = hasDarkScreen.get()
          ? @() {
              watch = areaSize
              size = [sw(100), sh(100)]
              children = [
                mkCutBg([getLightBox(areaSize.get())])
                {
                  key = "chooseNextUnit"
                  size = [flex(), slotBarTreeHeight]
                  padding = saBordersRv
                  vplace = ALIGN_BOTTOM
                  color = 0x40000000
                  rendObj = ROBJ_SOLID
                  valign = ALIGN_CENTER
                  children = {
                    pos = [flagsWidth + flagTreeOffset, 0]
                    rendObj = ROBJ_TEXT
                    text = utf8ToUpper(loc("unitsTree/chooseNextUnit"))
                  }.__update(fontSmall)
                }
              ]
              animations = hasAnimDarkScreen.get() ? darkScreenAnim : null
            }
        : isCampaignWithSlots.get() ? slotBarUnitsTree
        : null
    }
    mkFlagButtons(allCountries, curCountry, areaSize, unseenNodesIndex)
  ]
}

return {
  mkUnitsTreeNodesContent
  mkHasDarkScreen
}
