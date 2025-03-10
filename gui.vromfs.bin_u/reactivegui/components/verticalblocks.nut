from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { makeVertScroll, scrollbarWidth } = require("%rGui/components/scrollbar.nut")
let { selectedLineHorUnits } = require("%rGui/components/selectedLineUnits.nut")

let contentGap = hdpx(20)

let contentBlockScrollHandler = ScrollHandler()

let activeBlockBgGradient = mkBitmapPicture(
  gradTexSize,
  gradTexSize / 4,
  mkGradientCtorRadial(0xFF50C0FF, 0, 20, 22, 31,-22))

let notActiveBlockBgGradient = mkBitmapPicture(
  gradTexSize,
  gradTexSize / 4,
  mkGradientCtorRadial(0xFF50C0FF, 0, 5, 22, 31,-22))

let mkBlockRadialGradient = @(isActive) isActive ? activeBlockBgGradient : notActiveBlockBgGradient

function mkBlock(content, idx, activeBlockIdx, mkBlockContent, onClick) {
  let isSelected = Computed(@() idx == activeBlockIdx.get() )
  return @() {
    watch = isSelected
    behavior = Behaviors.Button
    sound = { click = "choose" }
    rendObj = ROBJ_SOLID
    color = 0xFF383B3E
    onClick = @() onClick(idx)
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = mkBlockRadialGradient(isSelected.get())
      }
      mkBlockContent(content, idx)
      {
        size = flex()
        valign = ALIGN_TOP
        pos = [0, 0]
        children = selectedLineHorUnits(isSelected)
      }
    ]
  }
}

let mkBlocksContainer = @(contentList, activeIdx, mkBlockContent, onClick, blockWidth, blockHeight, containerHeight, scrollOvr = {}) {
  size = [blockWidth + scrollbarWidth, containerHeight]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = makeVertScroll(@(){
    watch = contentList
    flow = FLOW_VERTICAL
    gap = contentGap
    onAttach = @() contentBlockScrollHandler.scrollToY((blockHeight + contentGap) * activeIdx.get())
    children = contentList.get().map(@(v, idx) mkBlock(v, idx, activeIdx, mkBlockContent, onClick))
  }, { scrollHandler = contentBlockScrollHandler }.__merge(scrollOvr))
}

return {
  mkBlocksContainer
}
