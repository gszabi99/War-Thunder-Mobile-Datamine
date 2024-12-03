from "%globalsDarg/darg_library.nut" import *

let minKnobSizePart = 0.005

let defStyle = {
  scrollbarWidth = hdpxi(10)
  barStyleCtor = @(has_scroll) !has_scroll ? {}
    : {
        rendObj = ROBJ_SOLID
        color = Color(40, 40, 40, 160)
      }
  knobStyle = {
    rendObj = ROBJ_SOLID
    colorCalc = @(sf) (sf & S_ACTIVE) ? Color(255, 255, 255)
                    : (sf & S_HOVER)  ? Color(110, 120, 140, 80)
                                      : Color(110, 120, 140, 160)
  }

  rootBase = {
    size = flex()
    behavior = Behaviors.Pannable
  }
}

let calcBarSize = @(scrollbarWidth, isVertical) isVertical ? [scrollbarWidth, flex()] : [flex(), scrollbarWidth]

function scrollbar(scroll_handler, options = {}) {
  let stateFlags = Watched(0)
  let {
    knobStyle = defStyle.knobStyle,
    barStyleCtor = defStyle.barStyleCtor,
    scrollbarWidth = defStyle.scrollbarWidth,
    orientation = O_VERTICAL,
    needReservePlace = true,
  } = options

  let isVertical = orientation == O_VERTICAL
  let elemSize = isVertical
    ? Computed(@() (scroll_handler.elem?.getHeight() ?? 0))
    : Computed(@() (scroll_handler.elem?.getWidth() ?? 0))
  let maxV = isVertical
    ? Computed(@() (scroll_handler.elem?.getContentHeight() ?? 0) - elemSize.get())
    : Computed(@() (scroll_handler.elem?.getContentWidth() ?? 0) - elemSize.get())
  let fValue = isVertical
    ? Computed(@() scroll_handler.elem?.getScrollOffsY() ?? 0)
    : Computed(@() scroll_handler.elem?.getScrollOffsX() ?? 0)
  let isElemFit = Computed(@() maxV.get() <= 0)
  let knob = @() {
    watch = stateFlags
    key = "knob"
    size = [flex(), flex()]
    rendObj = ROBJ_SOLID
    color = knobStyle?.colorCalc(stateFlags.get()) ?? knobStyle?.color
  }

  function view() {
    let sizeMul = elemSize.get() == 0 || maxV.get() == 0 ? 1
      : elemSize.get() <= minKnobSizePart * maxV.get() ? 1.0 / maxV.get() / minKnobSizePart
      : 1.0 / elemSize.get()
    return {
      watch = [elemSize, maxV, fValue]
      size = flex()
      flow = isVertical ? FLOW_VERTICAL : FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER

      children = [
        { size = array(2, flex(fValue.get() * sizeMul)) }
        knob
        { size = array(2, flex((maxV.get() - fValue.get()) * sizeMul)) }
      ]
    }
  }

  return {
    isElemFit
    function scrollComp() {
      if (isElemFit.get())
        return barStyleCtor(false).__merge({
          watch = isElemFit
          size = needReservePlace ? calcBarSize(scrollbarWidth, isVertical) : null
          key = scroll_handler
          behavior = Behaviors.Slider
        })
      return barStyleCtor(true).__merge({
        watch = [isElemFit, maxV, elemSize]
        key = scroll_handler
        size = calcBarSize(scrollbarWidth, isVertical)

        behavior = Behaviors.Slider
        orientation
        fValue = fValue.get()
        knob
        min = 0
        max = maxV.get()
        unit = 1
        pageScroll = (isVertical ? 1 : -1) * maxV.get() / 100.0 // TODO probably needed sync with container wheelStep option
        onChange = @(val) isVertical ? scroll_handler.scrollToY(val)
          : scroll_handler.scrollToX(val)
        onElemState = @(sf) stateFlags.set(sf)

        children = view
      })
    }
  }
}

let DEF_SIDE_SCROLL_OPTIONS = defStyle.__merge({ //const
  scrollAlign = ALIGN_RIGHT
  orientation = O_VERTICAL
  size = flex()
  maxWidth = null
  maxHeight = null
  needReservePlace = true //need reserve place for scrollbar when it not visible
  clipChildren  = true
  joystickScroll = true
})

function makeSideScroll(content, options = DEF_SIDE_SCROLL_OPTIONS) {
  options = DEF_SIDE_SCROLL_OPTIONS.__merge(options)

  let scrollHandler = options?.scrollHandler ?? ScrollHandler()
  let { rootBase, size, orientation, joystickScroll, maxHeight, maxWidth, clipChildren
  } = options
  let scrollAlign = options.scrollAlign

  let rootBhv = [Behaviors.WheelScroll, Behaviors.ScrollEvent]
  if (type(rootBase?.behavior) == "array")
    rootBhv.extend(rootBase.behavior)
  else if (rootBase?.behavior != null)
    rootBhv.append(rootBase.behavior)
  let contentRoot = rootBase.__merge({
    size
    behavior = rootBhv
    scrollHandler
    wheelStep = 0.8
    orientation
    joystickScroll
    maxHeight
    maxWidth
    children = content
  })

  let { isElemFit, scrollComp } = scrollbar(scrollHandler, options)

  let childrenContent = scrollAlign == ALIGN_LEFT || scrollAlign == ALIGN_TOP
    ? [scrollComp, contentRoot]
    : [contentRoot, scrollComp]

  return @() {
    watch = isElemFit
    size
    maxHeight
    maxWidth
    flow = orientation == O_VERTICAL ? FLOW_HORIZONTAL : FLOW_VERTICAL
    clipChildren

    children = childrenContent
  }
}


function makeHVScrolls(content, options = {}) {
  let { rootBase = defStyle.rootBase, scrollHandler = ScrollHandler() } = options

  let rootBhv = [Behaviors.WheelScroll, Behaviors.ScrollEvent]
  if (type(rootBase?.behavior) == "array")
    rootBhv.extend(rootBase.behavior)
  else if (rootBase?.behavior != null)
    rootBhv.append(rootBase.behavior)
  let contentRoot = rootBase.__merge({
    behavior = rootBhv
    scrollHandler
    joystickScroll = true

    children = content
  })

  return {
    size = flex()
    flow = FLOW_VERTICAL

    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        clipChildren = true
        children = [
          contentRoot
          scrollbar(scrollHandler, options.__merge({ orientation = O_VERTICAL })).scrollComp
        ]
      }
      scrollbar(scrollHandler, options.__merge({ orientation = O_HORIZONTAL })).scrollComp
    ]
  }
}


function makeVertScroll(content, options = {}) {
  let o = clone options
  o.orientation <- O_VERTICAL
  o.scrollAlign <- o?.scrollAlign ?? ALIGN_RIGHT
  return makeSideScroll(content, o)
}


function makeHorizScroll(content, options = {}) {
  let o = clone options
  o.orientation <- O_HORIZONTAL
  o.scrollAlign <- o?.scrollAlign ?? ALIGN_BOTTOM
  return makeSideScroll(content, o)
}


return {
  scrollbarWidth = defStyle.scrollbarWidth

  makeHorizScroll
  makeVertScroll
  makeHVScrolls
  makeSideScroll
}
