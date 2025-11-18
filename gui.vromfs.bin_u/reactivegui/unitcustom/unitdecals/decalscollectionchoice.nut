from "%globalsDarg/darg_library.nut" import *
let { mkDecalCard, decalCardWidth, commonBgColor, decalsGap } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let { decalsCfg } = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { gamercardHeight } = require("%rGui/unitCustom/unitCustomCompsNew.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let pannableHeight = saSize[1] - (gamercardHeight + decalCardWidth + (decalsGap * 4 + saBorders[1] * 2))

let mkDecalRow = @(row, availableDecals, selectedDecal, onSelect) @() {
  watch = decalsCfg
  flow = FLOW_HORIZONTAL
  gap = decalsGap
  children = row.map(@(id)
    mkDecalCard(Computed(@() decalsCfg.get()?[id]), availableDecals, selectedDecal, onSelect))
}

let mkDecalsCollectionChoice = @(decalsCollection, availableDecals, selectedDecal, onSelect) @() {
  watch = decalsCollection
  size = FLEX_H
  padding = decalsGap
  halign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  fillColor = commonBgColor
  children = decalsCollection.get().len() == 0 ? null
    : makeVertScroll({
        flow = FLOW_VERTICAL
        gap = decalsGap
        children = decalsCollection.get().map(@(category) {
          flow = FLOW_VERTICAL
          gap = decalsGap
          children = category?.decals.map(@(row) mkDecalRow(row, availableDecals, selectedDecal, onSelect))
        })
      },
      {
        size = [SIZE_TO_CONTENT, pannableHeight]
        isBarOutside = true
        barStyleCtor = @(hasScroll) !hasScroll ? {}
          : {
              pos = [decalsGap, 0]
              rendObj = ROBJ_SOLID
              color = commonBgColor
            }
        })
}

return { mkDecalsCollectionChoice }
