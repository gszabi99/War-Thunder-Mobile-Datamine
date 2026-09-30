from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
from "%sqstd/underscore.nut" import arrayByRows
from "%rGui/debugTools/debugMapPoints/mapEditorState.nut" import bgCollection
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach


let imgSize = evenPx(180)
const gap = hdpxi(10)
const borderWidth = hdpxi(2)
let footerHeight = hdpx(30)
let cardWidth = imgSize + 2 * borderWidth
let cardHeight = cardWidth + footerHeight
let maxColumns = (sw(100).tointeger() - gap) / (cardWidth + gap)
const minWndWidth = hdpx(500)

let ip2ToArr = @(p) [p.x.tointeger(), p.y.tointeger()]

function mkCard(id, elem, onSelect) {
  let stateFlags = Watched(0)
  let image = Picture($"{elem.img}:0:P")
  return @() {
    watch = stateFlags
    key = id
    size = [cardWidth, cardHeight]

    behavior = Behaviors.Button
    onElemState = withTooltip(stateFlags, id, @() id)
    onDetach = tooltipDetach(stateFlags)
    onClick = @() onSelect(elem, ip2ToArr(image.getLoadedPicSize()))

    flow = FLOW_VERTICAL
    children = [
      {
        size = cardWidth
        padding = borderWidth
        rendObj = ROBJ_BOX
        fillColor = stateFlags.get() & S_HOVER ? 0xFF000010 : 0xFF8080A0
        borderColor = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
        borderWidth
        children = {
          size = imgSize
          rendObj = ROBJ_IMAGE
          image
          keepAspect = true
        }
      }
      {
        size = FLEX
        rendObj = ROBJ_TEXT
        text = id
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
      }.__update(fontVeryVeryTiny)
    ]
  }
}

let mkBgCollectionChoice = @(onSelect, bg) function() {
  let collection = bgCollection.get()
  let total = collection.len()
  local columns = min(total, maxColumns)
  if (columns > 0) {
    let rows = ceil(total.tofloat() / columns).tointeger()
    columns = ceil(total.tofloat() / rows).tointeger()
  }
  let order = collection.keys().sort()
  return bg.__merge({
    watch = bgCollection
    size = [max(minWndWidth, columns * cardWidth + (columns + 1) * gap), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap
    children = arrayByRows(order, columns)
      .map(@(row) {
        flow = FLOW_HORIZONTAL
        gap
        children = row.map(@(id) mkCard(id, collection[id], onSelect))
      })
  })
}

return {
  mkBgCollectionChoice
}