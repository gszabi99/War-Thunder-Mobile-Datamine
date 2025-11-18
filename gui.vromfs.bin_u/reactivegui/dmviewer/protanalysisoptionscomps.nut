from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitPresentation.nut" import getUnitLocId, getUnitName
from "%appGlobals/config/bulletsPresentation.nut" import getBulletImage, getBulletTypeIcon
from "%rGui/components/foldableSelector.nut" import mkFoldableSelector, mkListItem
from "%rGui/components/gradTexts.nut" import mkGradRank, mkGradRankLarge
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitInfo
from "%rGui/weaponry/weaponsVisual.nut" import getAmmoNameShortText, getAmmoTypeShortText
from "%rGui/unitMods/modsComps.nut" import mkBulletTypeIcon
from "%rGui/dmViewer/protectionAnalysisState.nut" import isProtectionAnalysisActive

let itemSize = hdpx(120)
let slotWidth = hdpx(248)
let flagSize = hdpx(68)
let flagSizeHeader = hdpx(54)

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmall, ovr)

let mkIconWithLabel = @(iconComp, text) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    iconComp
    mkText(text)
  ]
}

let mkImage = @(w, h, imgPath, ovr = {}) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  image = Picture(imgPath)
  keepAspect = true
}.__update(ovr)

let mkFlagImage = @(countryId, sz) mkImage(sz, sz, $"ui/gameuiskin#{countryId}.svg:{sz}:{sz}:P")

let mkUnitPlate = @(unit, isSelectedW) {
  size = [slotWidth, itemSize]
  children = [
    mkUnitBg(unit)
    mkUnitSelectedGlow(unit, isSelectedW)
    mkUnitImage(unit)
    mkUnitTexts(unit, getUnitName(unit, loc))
    mkUnitInfo(unit)
  ]
}

function mkBulletPlate(bData) {
  let { bSet = null, tags = null } = bData
  let { image = null, icon = null } = tags
  let imageBulletName = getBulletImage(image, bSet?.bullets ?? [])
  let ammoTypeName = getAmmoTypeShortText(bSet?.bullets[0] ?? "")
  let iconBulletType = getBulletTypeIcon(icon, bSet)
  return {
    size = [slotWidth, itemSize]
    children = [
      mkImage(slotWidth, itemSize, imageBulletName, { imageHalign = ALIGN_LEFT })
      mkBulletTypeIcon(iconBulletType, ammoTypeName)
      mkText(getAmmoNameShortText(bSet), fontVeryTinyAccentedShaded.__merge({ margin = hdpx(5) }))
    ]
  }
}

let curOpenedSelector = Watched("")
isProtectionAnalysisActive.subscribe(@(v) v ? null : curOpenedSelector.set(""))

let mkCountryHeadItem = @(v) mkIconWithLabel(mkFlagImage(v, flagSizeHeader), loc(v))
let mkCountryListItem = @(v, isSelectedW, onClick) mkListItem(v, isSelectedW, onClick, itemSize, itemSize, mkFlagImage(v, flagSize))
let mkSelectorCountry = @(countriesList, country) mkFoldableSelector(countriesList, country, 4,
  mkCountryListItem, mkCountryHeadItem, curOpenedSelector, "country")

let mkMRankHeadItem = mkGradRank
let mkMRankListItem = @(v, isSelectedW, onClick) mkListItem(v, isSelectedW, onClick, itemSize, itemSize, mkGradRankLarge(v))
let mkSelectorMRank = @(mRanksList, mRank) mkFoldableSelector(mRanksList, mRank, 4,
  mkMRankListItem, mkMRankHeadItem, curOpenedSelector, "mRank")

let mkUnitHeadItem = @(v) mkText(loc(getUnitLocId(v?.name ?? "")))
let mkUnitListItem = @(v, isSelectedW, onClick) mkListItem(v, isSelectedW, onClick, slotWidth, itemSize, mkUnitPlate(v, isSelectedW))
let mkSelectorUnit = @(unitsList, unit) mkFoldableSelector(unitsList, unit, 2,
  mkUnitListItem, mkUnitHeadItem, curOpenedSelector, "unit")

let mkBulletHeadItem = @(v) mkText(getAmmoNameShortText(v?.bSet))
let mkBulletListItem = @(v, isSelectedW, onClick) mkListItem(v, isSelectedW, onClick, slotWidth, itemSize, mkBulletPlate(v))
let mkSelectorBullet = @(bDataList, bData) mkFoldableSelector(bDataList, bData, 2,
  mkBulletListItem, mkBulletHeadItem, curOpenedSelector, "bullet")

return {
  curOpenedSelector
  mkSelectorCountry
  mkSelectorMRank
  mkSelectorUnit
  mkSelectorBullet
  mkUnitPlate
}
