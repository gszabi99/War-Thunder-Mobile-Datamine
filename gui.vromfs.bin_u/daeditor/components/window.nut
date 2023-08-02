from "%darg/ui_imports.nut" import *
let cursors = require("cursors.nut")

let mkWindow = kwarg(function(id, content,
      onAttach=null, initialSize = [sw(40), sh(65)], minSize = [sw(14), sh(25)], maxSize = [sw(80), sh(90)],
      windowStyle = null, saveState = false
  ) {
  let initialState = {
    pos = [sw(50)-initialSize[0]/2, sh(46)-initialSize[1]/2]
    size = initialSize
  }
  let windowState = saveState ? mkWatched(persist, $"{id}_state", initialState) : Watched(initialState)

  let function onMoveResize(dx, dy, dw, dh) {
    let w = windowState.value
    let pos = clone w.pos
    let size = clone w.size
    pos[0] = clamp(pos[0]+dx, -size[0]/2, (sw(100)-size[0]/2))
    pos[1] = clamp(pos[1]+dy, 0, (sh(100)-size[1]/2))
    size[0] = clamp(size[0]+dw, minSize[0], maxSize[0])
    size[1] = clamp(size[1]+dh, minSize[1], maxSize[1])
    w.pos = pos
    w.size = size
    return w
  }
  return @() {
    onAttach
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(150,150,150,250)
    moveResizeModes = MR_AREA | MR_L | MR_R | MR_T | MR_B
    onMoveResize = onMoveResize
    size = windowState.value.size
    pos = windowState.value.pos
    moveResizeCursors = cursors.moveResizeCursors
    behavior = [Behaviors.MoveResize]
    key = id
    padding = fsh(0.5)
    gap = fsh(0.5)
    watch = [windowState]
    stopMouse = true
    children = content
  }.__update(windowStyle ?? {})

})
return mkWindow