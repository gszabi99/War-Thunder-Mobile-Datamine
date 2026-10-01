from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import number_of_set_bits
from "%sqstd/string.nut" import isStringInteger
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation
from "%appGlobals/pServer/pServerApi.nut" import collectionInProgress, receive_collection_reward
from "%rGui/collections/collectionComps.nut" import mkProgress, mkPuzzleBgExtensions, mkConvertionInfoBlock, infoGap,
  mkGetRewardButton
from "%rGui/collections/collectionsState.nut" import curCollectionCfg, curCollectionId, curCollection, openPuzzle,
  loadCollectionPresetOnce, curUnseenPiecesMasks, curRewardsToReceive
from "%rGui/collections/rewardProgressCtors.nut" import getRewardCtor
from "%rGui/components/gradientDefComps.nut" import headerMargin
from "%rGui/components/infoButton.nut" import infoEllipseButton
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader
from "%rGui/components/timerBlock.nut" import mkTimerBlock
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch
from "%rGui/event/treeEvent/eventMapLoader.nut" import mkEmptyPreset
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardReceivedMark
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_SMALL
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/style/stdColors.nut" import commonTextColor
from "%rGui/style/gradients.nut" import simpleHorGrad


let cardsStyle = REWARD_STYLE_SMALL
let { boxSize, boxGap } = cardsStyle
let leftBlockWidth = 3 * boxSize + 2 * boxGap
let mainProgressWidth = 2 * boxSize + boxGap

const minBgElemSizeSqForComplexView = hdpx(200) * hdpx(200)


let bleedBlockSize = [leftBlockWidth + saBorders[0], SIZE_TO_CONTENT]
let bleedBlockPos = [-saBorders[0], 0]
let bleedBlockPadding = [0, 0, 0, saBorders[0]]

let titleGradientBg = @(children, ovr = {}) {
  pos = [-saBorders[0], 0]
  rendObj = ROBJ_IMAGE
  padding = [hdpx(10), hdpx(10), hdpx(10), saBorders[0]]
  image = simpleHorGrad
  color = 0xAA000000
  valign = ALIGN_CENTER
  flipX = true
  children = children
}.__update(ovr)

function collectionMainRewardBlock() {
  let vInfo = getRewardsViewInfo(curCollectionCfg.get()?.finalRewards ?? [])
    .sort(sortRewardsViewInfo)
  let { puzzles  = [] } = curCollectionCfg.get()
  let { isFinalReceived = false, puzzlePiecesMasks = [] } = curCollection.get()
  let totalPieces = puzzles.reduce(@(res, p) res + p.pieces.len(), 0)
  return {
    watch = [curCollectionCfg, curCollection]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = boxGap
    children = [
      titleGradientBg({
          rendObj = ROBJ_TEXT
          text = loc("collection/mainPrize")
        }.__update(fontSmallShaded))
      {
        flow = FLOW_HORIZONTAL
        gap = boxGap
        children = vInfo.map(@(vi) !isFinalReceived ? mkRewardPlate(vi, cardsStyle)
          : {
              children = [
                mkRewardPlate(vi, cardsStyle)
                mkRewardReceivedMark(cardsStyle)
              ]
            })
      }
      isFinalReceived ? null
        : mkProgress(
            puzzlePiecesMasks.reduce(@(res, m, i) res + number_of_set_bits(m & (puzzles?[i].piecesMask ?? 0)), 0),
            totalPieces,
            mainProgressWidth)
    ]
  }
}

let convertionInfoBlock = @()
  mkConvertionInfoBlock(curCollectionId.get(), curCollectionCfg.get(), curCollection.get()?.curDblProgress ?? 0,
    { watch = [curCollectionCfg, curCollection, curCollectionId] })

let openDuplicatesInfo = @() addModalWindowWithHeader("duplicates_info",
  loc("collection/duplicatesInfo/header"),
  {
    padding = infoGap
    flow = FLOW_VERTICAL
    gap = infoGap
    halign = ALIGN_CENTER
    children = [
      convertionInfoBlock
      {
        size = [hdpx(800), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = commonTextColor
        text = loc("collection/duplicatesInfo/description")
        halign = ALIGN_CENTER
      }.__update(fontSmallShaded)
    ]
  })

function duplicatesBlock() {
  let { dblRewardProgress = 0, dblRewards = [] } = curCollectionCfg.get()
  if (dblRewardProgress == 0 || dblRewards.len() == 0)
    return { watch = curCollectionCfg }
  let vInfo = getRewardsViewInfo(dblRewards).sort(sortRewardsViewInfo)
  let { isFinalReceived = false, curDblProgress = 0 } = curCollection.get()
  return {
    watch = [curCollectionCfg, curCollection]
    size = bleedBlockSize
    pos = bleedBlockPos
    padding = bleedBlockPadding
    behavior = isFinalReceived ? null : Behaviors.Button
    onClick = isFinalReceived ? null : openDuplicatesInfo
    flow = FLOW_VERTICAL
    gap = boxGap
    children = isFinalReceived ? null
      : [
          titleGradientBg([
            {
              rendObj = ROBJ_TEXT
              text = loc("collection/duplicatesCount")
            }.__update(fontSmallShaded)
            infoEllipseButton(openDuplicatesInfo)
          ], { flow = FLOW_HORIZONTAL, gap = headerMargin, padding = [0, hdpx(10), 0, saBorders[0]] })
          {
            flow = FLOW_HORIZONTAL
            gap = boxGap
            children = vInfo.map(@(vi) mkRewardPlate(vi, cardsStyle))
          }
          mkProgress(curDblProgress, dblRewardProgress, mainProgressWidth)
        ]
  }
}

function leftBlock() {
  let cId = curCollectionId.get()
  let { puzzles = [] } = curCollectionCfg.get()
  let { isFinalReceived = false, puzzleRewardsMask = 0 } = curCollection.get()
  let fullMask = (1 << puzzles.len()) - 1
  let isCompleted = fullMask != 0 && (puzzleRewardsMask & fullMask) == fullMask
  let needRewardButton = isCompleted && !isFinalReceived
  return {
    watch = [curCollectionId, curCollectionCfg, curCollection]
    size = [leftBlockWidth, FLEX]
    flow = FLOW_VERTICAL
    children = [
      mkTimerBlock(Computed(@() curCollectionCfg.get()?.timeRange.end ?? 0))
      { size = FLEX }
      collectionMainRewardBlock
      needRewardButton ? { size = boxGap } : null
      !needRewardButton ? null
        : mkGetRewardButton(Computed(@() collectionInProgress.get() != null), @() receive_collection_reward(cId))
      { size = FLEX }
      needRewardButton ? null : duplicatesBlock
      { size = flex(2) }
    ]
  }
}

function mkBgElementImg(img, size, ovr = {}) {
  if ((img ?? "") == "")
    return { size }.__update(ovr)
  let isComplexView = size[0] * size[1] <= minBgElemSizeSqForComplexView
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture(isComplexView ? $"{img}:{size[0]}:{size[1]}:P" : $"{img}:0:P", { sampler = getconsttable()?.SAMPLER_LINEAR_CLAMP })
    keepAspect = true
  }.__update(ovr)
}

let scaleTransitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]


function getPuzzleStateFlags(stateFlagsByIdx, idx) {
  if (idx not in stateFlagsByIdx)
    stateFlagsByIdx[idx] <- Watched(0)
  return stateFlagsByIdx[idx]
}

function mkBgElement(bgElem, stateFlagsByIdx) { 
  let { id = "", img, size, pos, rotate, flipX = false, flipY = false, needShadow = false, shadowPos = [0, 0] } = bgElem
  let sizePx = size.map(hdpx)
  let idx = isStringInteger(id) ? id.tointeger() : null

  let root = {
    pos = pos.map(hdpx)
    size = sizePx
    transform = { rotate }
  }
  if (idx == null)
    return root.__merge({
      children = mkBgElementImg(img, sizePx, { flipX, flipY })
    })

  let isCompleted = Computed(function() {
    let { piecesMask = 0 } = curCollectionCfg.get()?.puzzles[idx]
    return (piecesMask & (curCollection.get()?.puzzlePiecesMasks[idx] ?? 0)) == piecesMask
  })
  let hasUnseen = Computed(@() idx in curUnseenPiecesMasks.get() || idx in (curRewardsToReceive.get()?.puzzles ?? {}))
  let unseenMark = mkPriorityUnseenMarkWatch(hasUnseen, { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })
  let stateFlags = getPuzzleStateFlags(stateFlagsByIdx, idx)
  return @() root.__merge({
    watch = [isCompleted, stateFlags]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() openPuzzle(idx)
    children = [
      !needShadow ? null
        : mkBgElementImg(img, sizePx,
          {
            color = 0x70000000,
            pos = shadowPos.map(hdpx),
            flipX,
            flipY,
            transform = stateFlags.get() & S_ACTIVE ? const { scale = [0.9, 0.9] }
              : stateFlags.get() & S_HOVER ? const { scale = [1.02, 1.02] }
              : const { scale = [1, 1] },
            transitions = scaleTransitions
          })
      mkBgElementImg(img, sizePx, { flipX, flipY, picSaturate = isCompleted.get() ? 1 : 0 })
      unseenMark
    ]
    transform = stateFlags.get() & S_ACTIVE ? const { scale = [0.98, 0.98] }
      : stateFlags.get() & S_HOVER ? const { scale = [1.02, 1.02] }
      : const { scale = [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  })
}

let mkBgElements = @(bgElements, stateFlagsByIdx) {
  size = FLEX
  children = bgElements.map(@(b) mkBgElement(b, stateFlagsByIdx))
}

function mkReward(rCfg, id, stateFlagsByIdx) {
  let { pos, view = "" } = rCfg
  let idx = id.startswith("reward_") ? id.slice(7).tointeger() : null
  let puzzleCfg = Computed(@() curCollectionCfg.get()?.puzzles[idx])
  let ctor = getRewardCtor(view)
  let posPx = pos.map(hdpx)
  let stateFlags = idx == null ? Watched(0) : getPuzzleStateFlags(stateFlagsByIdx, idx)
  return @() {
    watch = [puzzleCfg, curCollection, stateFlags]
    pos = posPx
    children = ctor(
      puzzleCfg.get()?.rewards ?? [],
      number_of_set_bits((puzzleCfg.get()?.piecesMask ?? 0) & (curCollection.get()?.puzzlePiecesMasks[idx] ?? 0)),
      puzzleCfg.get()?.pieces.len() ?? 0,
      idx != null && ((curCollection.get()?.puzzleRewardsMask ?? 0) & (1 << idx)) != 0)
    transform = stateFlags.get() & S_ACTIVE ? const { scale = [0.98, 0.98] }
      : stateFlags.get() & S_HOVER ? const { scale = [1.02, 1.02] }
      : const { scale = [1, 1] }
    transitions = scaleTransitions
  }
}

let mapRewards = @(rewards, stateFlagsByIdx) {
  size = FLEX
  children = rewards.map(@(r, id) mkReward(r, id, stateFlagsByIdx)).values()
}

function mapContainer(mapPreset) {
  let { bgElements, rewards } = mapPreset
  let stateFlagsByIdx = {}
  return {
    size = FLEX
    children = [
      mkBgElements(bgElements.filter(@(v) !v?.isOnTop), stateFlagsByIdx)
      mkBgElements(bgElements.filter(@(v) v?.isOnTop), stateFlagsByIdx)
      mapRewards(rewards, stateFlagsByIdx)
    ]
  }
}

function collectionBlock() {
  if (curCollectionId.get() == null)
    return { watch = curCollectionId }

  let mapPreset = mkEmptyPreset().__update(loadCollectionPresetOnce(curCollectionId.get()) ?? {})
  let { mapSize, bg } = mapPreset
  let mapSizeFinal = mapSize.map(hdpx)
  let presentation = getCollectionPresentation(curCollectionId.get())

  return {
    watch = curCollectionId
    size = FLEX
    children = {
      size = mapSizeFinal
      pos = presentation.mainScreenOffset.map(hdpx)
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{bg}:0:P")
      keepAspect = true
      children = [
        mkPuzzleBgExtensions(presentation)
        mapContainer(mapPreset)
      ]
    }
  }
}

let collectionScene = {
  size = FLEX
  padding = [0, saBorders[0]]
  flow = FLOW_HORIZONTAL
  children = [
    leftBlock
    collectionBlock
  ]
}

return collectionScene