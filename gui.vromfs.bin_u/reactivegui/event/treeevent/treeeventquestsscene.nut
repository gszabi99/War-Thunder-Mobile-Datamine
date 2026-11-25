from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%rGui/event/treeEvent/treeEventState.nut" import openedTreeEventId, openedQuestsNodeId, curEventMapNodes,
  curEventMapStatus, nodeViewTypes, isPurchased, mkNodeAllQuestsDone, mkNodeQuestCurrencies
from "%rGui/event/treeEvent/treeEventNodeInfo.nut" import mkNodeQuestsList, mkNodePurchaseBtn, getNodeTitle
from "%rGui/event/treeEvent/treeEventComps.nut" import mkLockIcon
from "%rGui/event/treeEvent/treeEventWnd.nut" import contentOverlayShadeColor
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock, headerGradientPaddingY
from "%rGui/components/imagePreviewWnd.nut" import openImagePreview
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate


const SCENE_ID = "treeEventQuestsScene"

const artBgColor = 0xFF000000
const descBgColor = 0xA0000000
const lockedArtShadeColor = 0x80000000

const blurredArtTexWidth = 32

const artWidth = hdpx(600)
const artHeight = hdpx(338)
const artBorderWidth = hdpx(4)
const artLockIconSize = hdpxi(80)
const artColumnGap = hdpx(40)
const zoomIconSize = hdpxi(50)
const zoomIconMargin = hdpx(10)
const columnsGap = hdpx(100)
const contentTopGap = hdpx(60)

let descPos = [-saBorders[0], 0]
let descPadding = [headerGradientPaddingY, columnsGap, headerGradientPaddingY, saBorders[0]]

let close = @() openedQuestsNodeId.set(null)
let isSceneOpened = keepref(Computed(@() curEventMapNodes.get()?[openedQuestsNodeId.get()] != null))
let sceneBg = keepref(Computed(function() {
  let presentation = getEventPresentation(openedTreeEventId.get())
  let { mapSceneBg = null } = presentation
  return mapSceneBg == null ? presentation : { ...presentation, bg = mapSceneBg }
}))

let getQuestsLocId = @(clusterId, suffix) $"treeEvent/quests/{clusterId}/{suffix}"

let contentOverlay = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = contentOverlayShadeColor
}

let lockedArtShade = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = lockedArtShadeColor
}

let artFrame = {
  size = const [artWidth, artHeight]
  padding = artBorderWidth
  rendObj = ROBJ_BOX
  fillColor = artBgColor
  borderColor = selectColor
  borderWidth = artBorderWidth
}

let mkArtImage = @(image, texWidth) {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{texWidth}:P")
  keepAspect = KEEP_ASPECT_FILL
}

let mkLockedArt = @(image) {
  ...artFrame
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkArtImage(image, blurredArtTexWidth)
    lockedArtShade
    mkLockIcon(artLockIconSize)
  ]
}

let mkUnlockedArt = @(image) {
  ...artFrame
  behavior = Behaviors.Button
  onClick = @(evt) openImagePreview(image, evt.targetRect)
  sound = const { click = "click" }
  children = [
    mkArtImage(image, 0)
    {
      size = zoomIconSize
      margin = zoomIconMargin
      vplace = ALIGN_BOTTOM
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#btn_search.svg:{zoomIconSize}:{zoomIconSize}:P")
      keepAspect = true
    }
  ]
}

let mkArtDesc = @(text) {
  pos = descPos
  padding = descPadding
  rendObj = ROBJ_IMAGE
  image = simpleHorGrad
  flipX = true
  color = descBgColor
  children = {
    size = const [artWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text,
    ...fontTinyShaded
  }
}

let mkTitle = @(id, clusterId) function() {
  let nameLocId = getQuestsLocId(clusterId.get(), "name")
  return {
    watch = [clusterId, nodeViewTypes]
    rendObj = ROBJ_TEXT
    text = doesLocTextExist(nameLocId)
      ? loc(nameLocId)
      : getNodeTitle(id, nodeViewTypes.get())
    ...fontBigShaded
  }
}

let mkArtColumn = @(clusterId, art, isArtUnlocked) function() {
  let descLocId = getQuestsLocId(clusterId.get(), "desc")
  let isUnlocked = isArtUnlocked.get()
  let { image = null } = art.get()
  let hasDesc = isUnlocked && doesLocTextExist(descLocId)

  let watch = [art, clusterId, isArtUnlocked]

  if (image == null && !hasDesc)
    return { watch }

  return {
    watch
    size = const [artWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = artColumnGap
    children = [
      image == null ? null
        : isUnlocked ? mkUnlockedArt(image)
        : mkLockedArt(image)
      hasDesc ? mkArtDesc(loc(descLocId)) : null
    ]
  }
}

function mkHeaderCurrencies(id) {
  let currencies = mkNodeQuestCurrencies(id)
  return @() {
    watch = currencies
    children = mkCurrenciesBtns(currencies.get(), const {}, const { size = SIZE_TO_CONTENT })
  }
}

function mkSceneContent(id) {
  let clusterId = Computed(@() curEventMapNodes.get()?[id].meta.quests)
  let art = Computed(@() getEventPresentation(openedTreeEventId.get()).mapQuestsArt?[clusterId.get()])
  let allQuestsDone = mkNodeAllQuestsDone(id)
  let isArtUnlocked = Computed(@() isPurchased(curEventMapStatus.get()?[id]) && allQuestsDone.get())

  return {
    size = FLEX
    padding = saBordersRv
    flow = FLOW_VERTICAL
    children = [
      headerGradientWithRightBlock([backButton(close), mkTitle(id, clusterId)], mkHeaderCurrencies(id))
      {
        size = FLEX
        padding = const [contentTopGap, 0, 0, 0]
        flow = FLOW_HORIZONTAL
        gap = columnsGap
        children = [
          mkArtColumn(clusterId, art, isArtUnlocked)
          {
            size = FLEX
            flow = FLOW_VERTICAL
            children = [
              makeVertScroll(mkNodeQuestsList(id), { isBarOutside = true })
              mkNodePurchaseBtn(id)
            ]
          }
        ]
      }
    ]
  }
}

let questsScene = @() {
  watch = openedQuestsNodeId
  key = SCENE_ID
  size = FLEX
  children = [
    contentOverlay
    openedQuestsNodeId.get() == null ? null : mkSceneContent(openedQuestsNodeId.get())
  ]
  animations = wndSwitchAnim
}

registerScene(SCENE_ID, questsScene, close, isSceneOpened)
setSceneBg(SCENE_ID, sceneBg.get()?.bg, sceneBg.get()?.bgColor, sceneBg.get()?.dimColor)
sceneBg.subscribe(@(v) setSceneBg(SCENE_ID, v?.bg, v?.bgColor, v?.dimColor))
registerUnlocksSceneToUpdate(SCENE_ID)
