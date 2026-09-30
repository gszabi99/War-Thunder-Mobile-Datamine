from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import G_LOOTBOX, G_PIECE_UNIQ, G_PIECE
from "%rGui/components/gradTexts.nut" import mkGradGlowText
from "%rGui/collections/collectionsState.nut" import isAllCollectionPiecesReceived
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsStates.nut" import ALL_PURCHASED
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize,
  mkSquareIconBtn, mkGoodsTimeLeftText, mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles,
  underConstructionBg, mkGoodsLimitText, mkBorderByCurrency,
  titleFontGradGold, titleFontGradCommon, titlePadding, numberToTextForWtFont, mkCommonGoodsIcon


const fonticonPreview = "⌡"
const contentMargin = hdpx(20)
let textMargin = [hdpx(15), contentMargin]

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

const emptyPiecesInfo = { isUniq = false, count = 0, id = "" }
function getPiecesInfo(rewards, sConfigs) {
  foreach (r in rewards)
    if (r.gType == G_PIECE_UNIQ)
      return { isUniq = true, count = r.count, id = r.id }
    else if (r.gType == G_PIECE)
      return { isUniq = false, count = r.count, id = r.id }
    else if (r.gType == G_LOOTBOX) {
      let { lootboxesCfg = {}, rewardsCfg = {} } = sConfigs
      foreach (rId, _ in lootboxesCfg?[r.id].rewards ?? {})
        if (rId in rewardsCfg) {
          let res = getPiecesInfo(rewardsCfg[rId], sConfigs)
          if (res != emptyPiecesInfo)
            return r.count == 1 ? res : res.__merge({ count = res.count * r.count })
        }
    }
  return emptyPiecesInfo
}

function getLocNamePuzzlePiece(goods, sConfigs = null) {
  let { isUniq, count } = getPiecesInfo(goods.rewards, sConfigs ?? serverConfigs.get())
  return loc(isUniq ? "collection/uniqPiecesCount" : "collection/piecesCount", { count })
}

function mkGoodsPuzzlePiece(goods, onClick, state, animParams, addChildren) {
  let { isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let info = Computed(@() getPiecesInfo(goods.rewards, serverConfigs.get()))
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)
  let amount = @() info.get().count == 1 ? { watch = info }
    : mkGradGlowText(numberToTextForWtFont(info.get().count), fontWtLarge, titleFontGradGold,
        { watch = info, margin = [titlePadding - fontWtLarge.fontSize * 0.25, titlePadding], hplace = ALIGN_RIGHT })
  let goodsLimit = mkGoodsLimitText(goods, titleFontGradCommon, { margin = textMargin })
  let timeLeft = mkGoodsTimeLeftText(goods, { vplace = ALIGN_BOTTOM, margin = textMargin })
  let icon = mkCommonGoodsIcon(goods.id)
  let previewBtn = mkSquareIconBtn(fonticonPreview, @() openGoodsPreview(goods.id), { vplace = ALIGN_BOTTOM, margin = contentMargin })
  let stateExt = Computed(@() state.get()
    | (isAllCollectionPiecesReceived(info.get().id, serverConfigs.get(), servProfile.get()) ? ALL_PURCHASED : 0))
  return mkGoodsWrap(
    goods,
    @() isAllCollectionPiecesReceived(info.get().id, serverConfigs.get(), servProfile.get()) ? null : onClick(),
    @(sf, canPurchase) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      icon
      amount
      goodsLimit
      !canPurchase ? null : previewBtn
      timeLeft
    ].extend(mkGoodsCommonParts(goods, stateExt), addChildren),
    mkPricePlate(goods, stateExt, animParams), { size = goodsSmallSize })
}

return {
  mkGoodsPuzzlePiece
  getLocNamePuzzlePiece
  getPiecesInfo
}