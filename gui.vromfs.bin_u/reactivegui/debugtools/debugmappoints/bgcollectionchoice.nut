from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { bgCollection } = require("%rGui/debugTools/debugMapPoints/mapEditorState.nut")

let imgSize = evenPx(180)
let gap = hdpxi(10)
let borderWidth = hdpxi(2)
let cardSize = imgSize + 2 * borderWidth
let maxColumns = (sw(100).tointeger() - gap) / (cardSize + gap)
let minWndWidth = hdpx(500)

function mkCard(id, elem, onSelect) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    key = id
    size = [cardSize, cardSize]
    padding = borderWidth
    rendObj = ROBJ_BOX
    fillColor = stateFlags.get() & S_HOVER ? 0xFF000010 : 0xFF8080A0
    borderColor = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
    borderWidth

    behavior = Behaviors.Button
    onElemState = withTooltip(stateFlags, id, @() id)
    onDetach = tooltipDetach(stateFlags)
    onClick = @() onSelect(elem)

    children = {
      size = [imgSize, imgSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{elem.img}:0:P")
      keepAspect = true
    }
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
    size = [max(minWndWidth, columns * cardSize + (columns + 1) * gap), SIZE_TO_CONTENT]
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