from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPicture
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, buy_event_map_node, receive_event_map_node_reward
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullIdOnlyActive
from "%rGui/event/treeEvent/treeEventState.nut" import curEventMapNodes, curEventUnlocks, selectedPointId,
  getEventNodeType, getClusterQuests, NODE_QUESTS, NODE_REWARD, NODE_INTERMEDIATE, curEventMapStatus, isUnlocked,
  openedTreeEventId, eventMapNodeInProgress, isPurchased, isRewardsReceived, nodeViewTypes, pageStartNodes
from "%rGui/event/treeEvent/treeEventUtils.nut" import VIEW_START, VIEW_REWARD, VIEW_QUESTS, VIEW_NEXT_PAGE
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonInactive, textButtonPricePurchase
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_COMMON, CS_INACTIVE_ICON
from "%rGui/quests/questBar.nut" import mkQuestBar
from "%rGui/quests/questsState.nut" import mkHasReceivedAllRewards
from "%rGui/quests/questsWndPage.nut" import mkQuestBtn
from "%rGui/quests/questsPkg.nut" import btnSize
from "%rGui/unlocks/unlocks.nut" import unlockProgress
from "%rGui/quests/rewardsComps.nut" import mkRewardsPreview, questItemsGap, getRewardsPreviewInfo, getEventCurrencyReward,
  rewardsBtnSize
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/modalWnd.nut" import modalWndHeaderWithClose
from "%rGui/shop/bqPurchaseInfo.nut" import mkBqPurchaseInfo, PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, gradTexSize
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin


const infoPanelWidth = hdpx(550)
const questPopupWidth = hdpx(1300)
const questLockIconSize = hdpxi(60)
const purchaseBtnPadding = [hdpx(16), 0, hdpx(20), 0]
let bgNodeCardGrad = mkColoredGradientY(0xFF304453, 0xFF030C13)
let nodeInfoPanelSize = [infoPanelWidth, SIZE_TO_CONTENT]

let questScrollMaxHeight = saSize[1] - headerHeightInSafeArea - headerMargin
  - buttonStyles.defButtonHeight - purchaseBtnPadding[0] - purchaseBtnPadding[2]
let lineGradientHor = mkBitmapPicture(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80777777, 0.25))

const defNodeTitleLocId = "treeEvent/nodeTitle/point"
const defNodeDescLocId = "treeEvent/nodeDesc/openNeighbors"

let nodeTitleLocId = {
  [VIEW_START] = "treeEvent/nodeTitle/start",
  [VIEW_REWARD] = "treeEvent/nodeTitle/reward",
  [VIEW_QUESTS] = "treeEvent/nodeTitle/task",
  [VIEW_NEXT_PAGE] = "treeEvent/nodeTitle/travel",
}

let nodeDescLocId = {
  [VIEW_REWARD] = "treeEvent/nodeDesc/unlockToReceive",
  [VIEW_NEXT_PAGE] = "treeEvent/nodeDesc/openNextPage",
}

let closeModal = @(_) selectedPointId.set(null)
let getNodeTitle = @(id, viewTypes) loc(nodeTitleLocId?[viewTypes?[id]] ?? defNodeTitleLocId)
let getNodeDesc = @(id, viewTypes) loc(nodeDescLocId?[viewTypes?[id]] ?? defNodeDescLocId)
let getNodeBlockedDesc = @(id, pageStarts) loc(pageStarts?[id]
  ? "treeEvent/nodeDesc/blockedStart"
  : "treeEvent/nodeDesc/blocked")
let getNodeName = @(id, node) loc(node?.meta.lang_id ?? id)

registerHandler("closeNodeInfoModal", @(res) res?.error == null ? selectedPointId.set(null) : null)

let nodeById = memoize(@(id) Computed(@() curEventMapNodes.get()?[id]))
let nodeStatusById = memoize(@(id) Computed(@() curEventMapStatus.get()?[id]))

function openNodePurchase(id, eventId, node) {
  let { price, currencyId } = node
  let currencyFullId = currencyToFullIdOnlyActive.get()?[currencyId] ?? currencyId
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getNodeName(id, node)) })
    price = { price, currencyId = currencyFullId }
    purchase = @() buy_event_map_node(eventId, id, currencyFullId, price, "closeNodeInfoModal")
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_MINI_EVENT, id)
  })
}

let separator = {
  size = const [FLEX, hdpxi(3)]
  margin = hdpx(20)
  rendObj = ROBJ_IMAGE
  image = lineGradientHor
}

function mkNodePurchaseBtn(id) {
  let node = nodeById(id)
  let nodeStatus = nodeStatusById(id)

  return function() {
    let n = node.get()
    let price = n?.price ?? 0
    let currencyId = n?.currencyId ?? ""
    let eventId = openedTreeEventId.get()
    let needPurchase = price > 0 && currencyId != ""
    let canBuy = isUnlocked(nodeStatus.get()) && eventMapNodeInProgress.get() == null

    return {
      watch = [node, nodeStatus, eventMapNodeInProgress, openedTreeEventId]
      hplace = ALIGN_CENTER
      children = isPurchased(nodeStatus.get())
          ? {
              padding = purchaseBtnPadding
              rendObj = ROBJ_TEXT
              text = utf8ToUpper(loc("quests/completed"))
            }.__update(fontTinyAccented)
        : !needPurchase
          ? null
        : {
            hplace = ALIGN_CENTER
            padding = purchaseBtnPadding
            children = textButtonPricePurchase(utf8ToUpper(loc("mainmenu/btnBuy")),
              mkCurrencyComp(price, currencyId, canBuy ? CS_COMMON : CS_INACTIVE_ICON),
              canBuy ? @() openNodePurchase(id, eventId, n) : @() null,
              canBuy ? { hotkeys = ["^J:X"] } : buttonStyles.INACTIVE)
          }
    }
  }
}

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = pw(100)
  halign = ALIGN_CENTER
  text
}.__update(ovr)

let chainLockIcon = {
  size = btnSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = questLockIconSize
    image = Picture($"ui/gameuiskin#lock_icon.svg:{questLockIconSize}:P")
    keepAspect = true
  }
}

let isChainReachable = @(q) q?.meta.chain_quest == null
  || (q.meta?.chain_quest && q.requirement == "")
  || (unlockProgress.get()?[q.requirement].isCompleted ?? false)

function mkQuestRow(questName) {
  let quest = Computed(@() curEventUnlocks.get()?[questName])
  let isReachable = Computed(@() isChainReachable(quest.get()))
  let rewardsPreview = Computed(@() getRewardsPreviewInfo(quest.get(), serverConfigs.get()))
  let eventCurrencyReward = Computed(@() getEventCurrencyReward(rewardsPreview.get()))
  let hasReceivedAllRewards = mkHasReceivedAllRewards(quest, rewardsPreview)
  return @() {
    watch = [quest, isReachable, rewardsPreview, eventCurrencyReward, hasReceivedAllRewards]
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = questItemsGap
    children = quest.get() == null ? null : [
      {
        size = FLEX_H
        minHeight = rewardsBtnSize
        flow = FLOW_VERTICAL
        gap = hdpx(6)
        children = [
          mkText(loc($"{quest.get()?.meta.lang_id ?? quest.get().name}/desc"), { halign = ALIGN_LEFT }.__update(fontTiny))
          { size = FLEX_V }
          mkQuestBar(quest.get())
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        gap = questItemsGap
        children = mkRewardsPreview(rewardsPreview.get(), quest.get()?.isFinished)
      }
      isReachable.get()
        ? mkQuestBtn(quest.get(), eventCurrencyReward.get(), rewardsPreview.get(), hasReceivedAllRewards.get())
        : chainLockIcon
    ]
  }
}

let mkNodeInfoPanel = @(title, id, content) {
  children = {
    stopMouse = true
    rendObj = ROBJ_IMAGE
    image = bgNodeCardGrad
    flow = FLOW_VERTICAL
    margin = hdpxi(2)
    children = [
      modalWndHeaderWithClose(title, closeModal)
      content
      mkNodePurchaseBtn(id)
    ]
  }
  transform = {}
  animations = wndSwitchAnim
}

function mkQuestsInfo(title, node, id) {
  let clusterId = node?.meta.quests
  if (clusterId == null)
    return null

  return mkNodeInfoPanel(title, id, {
    size = [questPopupWidth, SIZE_TO_CONTENT]
    children = makeVertScroll({
      size = [questPopupWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      padding = hdpx(20)
      gap = separator
      children = getClusterQuests(clusterId).keys().sort().map(mkQuestRow)
    }, { size = SIZE_TO_CONTENT, maxHeight = questScrollMaxHeight, isBarOutside = true })
  })
}

function mkClaimBtn(id) {
  let node = nodeById(id)
  let nodeStatus = nodeStatusById(id)

  return function() {
    let eventId = openedTreeEventId.get()
    let isClaimable = isPurchased(nodeStatus.get()) && !isRewardsReceived(nodeStatus.get())
    let isInProgress = eventMapNodeInProgress.get() != null
    return {
      watch = [nodeStatus, node, eventMapNodeInProgress, openedTreeEventId]
      children = !isClaimable ? null
        : isInProgress || eventId == null ? textButtonInactive(utf8ToUpper(loc("btn/receive")), @() null)
        : textButtonPrimary(utf8ToUpper(loc("btn/receive")), @() receive_event_map_node_reward(eventId, id))
    }
  }
}

let mkNodeInfoBody = @(id, viewTypes, pageStarts, isNodeUnlocked, content = null, footer = null) [
  mkText(getNodeDesc(id, viewTypes), fontSmall)
  content
  isNodeUnlocked ? null
    : mkText(getNodeBlockedDesc(id, pageStarts), fontTiny)
  footer
]

function mkRewardInfo(title, node, id) {
  let rewards = getRewardsViewInfo(node?.rewards).sort(sortRewardsViewInfo)
  if (rewards.len() == 0)
    return null

  let nodeStatus = nodeStatusById(id)

  return mkNodeInfoPanel(title, id, @() {
    watch = [nodeStatus, nodeViewTypes, pageStartNodes]
    size = nodeInfoPanelSize
    padding = const [hdpx(20), hdpx(10)]
    flow = FLOW_VERTICAL
    gap = hdpx(16)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkNodeInfoBody(id, nodeViewTypes.get(), pageStartNodes.get(), isUnlocked(nodeStatus.get()), {
      flow = FLOW_HORIZONTAL
      gap = questItemsGap
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkRewardsPreview(rewards, false)
    }, mkClaimBtn(id))
  })
}

function mkStepInfo(title, _node, id) {
  let nodeStatus = nodeStatusById(id)

  return mkNodeInfoPanel(title, id, @() {
    watch = [nodeStatus, nodeViewTypes, pageStartNodes]
    size = nodeInfoPanelSize
    padding = const [hdpx(20), hdpx(10)]
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    halign = ALIGN_CENTER
    children = mkNodeInfoBody(id, nodeViewTypes.get(), pageStartNodes.get(), isUnlocked(nodeStatus.get()))
  })
}

let nodeInfoByType = {
  [NODE_QUESTS] = mkQuestsInfo,
  [NODE_REWARD] = mkRewardInfo,
  [NODE_INTERMEDIATE] = mkStepInfo,
}

let mkNodeInfoWnd = @(id, node)
  (nodeInfoByType?[getEventNodeType(node)] ?? mkStepInfo)(getNodeTitle(id, nodeViewTypes.get()), node, id)

return {
  mkNodeInfoWnd
}
