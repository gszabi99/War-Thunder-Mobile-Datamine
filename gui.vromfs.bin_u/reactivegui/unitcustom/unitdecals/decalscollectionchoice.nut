from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/foldableSelector.nut" import mkFoldableList
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/unitCustom/unitCustomComps.nut" import gamercardHeight
from "%rGui/unitCustom/unitDecals/unitDecalsComps.nut" import mkDecalCard, decalCardWidth, commonBgColor, decalsGap
from "%rGui/unitCustom/unitDecals/unitDecalsState.nut" import decalsCfg
from "%rGui/unitCustom/unitDecals/unseenDecals.nut" import markDecalsSeen


let pannableHeight = saSize[1] - (gamercardHeight + decalCardWidth + (decalsGap * 4 + saBorders[1] * 2))

function hasUnseen(decalsList, unseenListDecals) {
  foreach (row in decalsList)
    foreach (decal in row)
      if (decal in unseenListDecals)
        return true
  return false
}

let mkDecalRow = @(row, availableDecals, selectedDecal, unseenDecals, onSelect) @() {
  watch = decalsCfg
  flow = FLOW_HORIZONTAL
  gap = decalsGap
  children = row.map(@(id)
    mkDecalCard(Computed(@() decalsCfg.get()?[id]), availableDecals, selectedDecal, unseenDecals, onSelect))
}

function mkFoldableHeader(unseenDecals, category) {
  let { locName = "", decals = [], subCategories = [] } = category
  let hasUnseenContent = Computed(@() hasUnseen(decals, unseenDecals.get())
    || subCategories.findvalue(@(sCat) hasUnseen(sCat?.decals ?? [], unseenDecals.get()) && (sCat?.category ?? "") != "") != null)

  return @() {
    watch = hasUnseenContent
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(15)
    children = [
      {
        rendObj = ROBJ_TEXT,
        text = locName
      }.__update(fontTinyAccented)
      hasUnseenContent.get() ? priorityUnseenMark : null
    ]
  }
}

function mkFoldableContent(decals, availableDecals, selectedDecal, unseenDecals, onSelect) {
  return {
    size = const [FLEX, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = decalsGap
    children = decals == null ? null
      : decals.map(@(row) mkDecalRow(row, availableDecals, selectedDecal, unseenDecals, onSelect))
  }
}

function mkDecalsCollectionChoice(decalsCollection, availableDecals, selectedDecal, unseenDecals, onSelect) {
  let openedSubCategoryId = Watched(null)
  let openedCategoryId = Watched(null)
  local prevOpenedCategoryId = null
  local prevOpenedSubCategoryId = null

  function markSeenCategory(id) {
    if (id == null || id == "" || unseenDecals.get().len() == 0)
      return
    markDecalsSeen((decalsCollection.get().findvalue(@(v) v.category == id)?.decals ?? [])
      .reduce(@(acc, list) acc.extend(list), []))
  }

  function markSeenSubCategory(id) {
    if (id == null || id == "" || unseenDecals.get().len() == 0)
      return
    let globalCat = decalsCollection.get().findvalue(@(cat) cat.subCategories.len() > 0
      && cat.subCategories.findindex(@(v) v.category == id) != null)
    markDecalsSeen((globalCat?.subCategories.findvalue(@(v) v.category == id)?.decals ?? [])
      .reduce(@(acc, list) acc.extend(list), []))
  }

  openedCategoryId.subscribe(function(v) {
    if (prevOpenedCategoryId != null)
      markSeenCategory(prevOpenedCategoryId)
    prevOpenedCategoryId = v
  })

  openedSubCategoryId.subscribe(function(v) {
    if (prevOpenedSubCategoryId != null)
      markSeenSubCategory(prevOpenedSubCategoryId)
    prevOpenedSubCategoryId = v
  })

  return @() {
    watch = decalsCollection
    key = decalsCollection
    size = FLEX_H

    function onDetach() {
      let id = openedCategoryId.get()
      let subId = openedSubCategoryId.get()
      let cat = decalsCollection.get().findvalue(@(v) v.category == id)
      let { decals = [] } = cat?.subCategories.findvalue(@(v) v.category == subId) ?? cat
      markDecalsSeen(decals.reduce(@(res, l) res.extend(l), []))
    }

    halign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    children = decalsCollection.get().len() == 0 ? null
      : makeVertScroll({
          size = FLEX_H
          flow = FLOW_VERTICAL
          gap = decalsGap
          children = decalsCollection.get().map(@(category) mkFoldableList(
            category.subCategories.len() > 0
              ? category.subCategories.map(@(sCat) mkFoldableList(
                  mkFoldableContent(sCat.decals, availableDecals, selectedDecal, unseenDecals, onSelect),
                  mkFoldableHeader(unseenDecals, sCat),
                  openedSubCategoryId,
                  sCat?.category))
              : mkFoldableContent(category.decals, availableDecals, selectedDecal, unseenDecals, onSelect),
            mkFoldableHeader(unseenDecals, category),
            openedCategoryId,
            category?.category))
        },
        {
          size = [FLEX, pannableHeight]
          isBarOutside = true
          barStyleCtor = @(hasScroll) !hasScroll ? {}
            : {
                pos = [decalsGap, 0]
                rendObj = ROBJ_SOLID
                color = commonBgColor
              }
        })
  }
}


return { mkDecalsCollectionChoice }
