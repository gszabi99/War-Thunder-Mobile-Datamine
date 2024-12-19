from "%globalsDarg/darg_library.nut" import *

let selectorBtnW = hdpx(465)
let widthImgMax = saSize[0] - saBordersRv[1]*2 - selectorBtnW
let insideBlockPadding = [hdpx(10), hdpx(20)]
let insideBlockWidthMax = widthImgMax - insideBlockPadding[1]*3

let unknownTag = @(...) {rendObj=ROBJ_SOLID opacity=0.2 size=[flex(), hdpx(2)], margin=[0, hdpx(5)], color = Color(255,120,120)}
function defTextArea(params, _formatAstFunc, style={}){
  return {
    rendObj = ROBJ_TEXTAREA
    text = params?.v
    behavior = Behaviors.TextArea
    color = style?.defTextColor
    size = [flex(), SIZE_TO_CONTENT]
  }.__update(params)
}

let defFormatters = {
  string = @(text, formatAstFunc, style={}) defTextArea({v=text}, formatAstFunc, style)
  def = defTextArea
}

let defStyle = {
  lineGaps = hdpx(5)
}

function collapsibleBlock(res) {
  let isExpanded = Watched(false)
  let isHover = Watched(false)
  let button = @() {
    watch = [isExpanded, isHover]
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_BOX
    fillColor = isHover.get() ? 0xFF00ff00 : 0xFFff0000
    onClick = @() isExpanded(!isExpanded.get())
    onHover = @(sf) isHover(sf)
    behavior = Behaviors.Button
    children = {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = !isExpanded.get() ? loc("ui/expand") : loc("ui/collapse")
    }.__update(fontSmall)
  }
  return {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_BOX
    flow = FLOW_VERTICAL
    padding = insideBlockPadding
    fillColor = isHover.get() ? 0xFF00ff00 : 0xFFff0000//0xFF32501E
    children = [
      button,
      @() {
        watch = isExpanded
        rendObj = ROBJ_BOX
        flow = FLOW_VERTICAL
        children = isExpanded.get() ? res : null
      }
    ]
  }
}

let mkFormatAst = kwarg(function mkFormatAstImpl(formatters = defFormatters, filter = @(_obj) false, style = defStyle){
  if (formatters != defFormatters)
    formatters=defFormatters.__merge(formatters)
  if (style != defStyle)
    style = defStyle.__merge(style)

  return function formatAst(object, params={}){
    let formatAstFunc = callee()
    if (type(object) == "string")
      return formatters["string"](object, formatAstFunc, style)
    if (object==null)
      return null

    if (type(object) == "table") {
      if (filter(object))
        return null

      let tag = object?.t ?? object?.tag
      if (!("v" in object))
        object = object.__merge({v=null})

      if (tag==null)
        return formatters["def"](object, formatAstFunc, style)
      if (tag == "spoiler"){
        let res = []
        res.append(formatters["string"](object.summary, formatAstFunc, style))
        foreach(item in object.v)
          res.append(formatters[item.t](item, formatAstFunc, {
            size = item?.width == null || item?.height == null ? [flex(), SIZE_TO_CONTENT]
              : item.width > insideBlockWidthMax ? [insideBlockWidthMax, insideBlockWidthMax * (item.height.tofloat() / item.width.tofloat())]
              : [item.width, item.height]
            }))
        return collapsibleBlock(res)
      }
      if (tag in formatters){
        return formatters[tag](object, formatAstFunc, style)}
      return unknownTag(object)
    }
    let ret = []
    if (type(object) == "array") {
      foreach (t in object)
        ret.append(formatAstFunc(t))
    }
    return {
      children = ret
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = style?.lineGaps
    }.__update(params ?? {})
  }
})

return {
  mkFormatAst
  selectorBtnW
  widthImgMax
}