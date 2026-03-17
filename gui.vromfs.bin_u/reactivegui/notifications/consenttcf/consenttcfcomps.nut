from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
import "%darg/helpers/mkTextareaBlock.nut" as mkTextareaBlock
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader, wndHeaderHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn, closeWndBtnSize

const wndW = hdpx(1300)
const wndH = saSize[1]

let fontTitle = fontSmallAccented
let fontDefault = fontTiny
let fontMinor = fontVeryTiny
let textGap = fontDefault.fontSize

let fadedTextColor = 0x80808080
let separatorColor = 0x60606060
let linkColor = 0xFF1697E1

let mkTextarea = @(text, ovr = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontDefault, ovr)

let mkTitle = @(text) mkTextarea(text, { margin = [hdpx(50), 0] }.__update(fontTitle))

let urlUnderline = {
  size = [flex(), hdpx(1)]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = linkColor
}

function mkLink(text, onClick, ovr = {}) {
  let stateFlags = Watched(0)
  return @() {
    key = text
    watch = stateFlags
    rendObj = ROBJ_TEXT
    text

    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags.set(v)
    sound = { click = "click" }

    color = linkColor
    children = urlUnderline
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }.__update(fontDefault, ovr)
}

let separatorLine = {
  size = [flex(), textGap]
  valign = ALIGN_CENTER
  children = {
    size = [flex(), hdpx(2)]
    rendObj = ROBJ_SOLID
    color = separatorColor
  }
}

let backBtnH = closeWndBtnSize
let backBtnW  = (78.0 / 59 * backBtnH).tointeger()

function mkBackBtn(onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [backBtnW, backBtnH]
    margin = closeWndBtnSize / 2
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#back_icon.svg:{backBtnW}:{backBtnH}:P")

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    sound = { click  = "click" }
    onClick
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }.__update(override)
}

let gapAbove = freeze({ margin = [textGap, 0, 0, 0] })
let gapBelow = freeze({ margin = [0, 0, textGap, 0] })
let gapAboveAndBelow = freeze({ margin = [textGap, 0] })
let fadedAndMinor = freeze({ color = fadedTextColor }.__update(fontMinor))

const descPadding = hdpx(50)
const footerBtnsPadding = hdpx(50)
const wndFooterH = defButtonHeight + (2 * footerBtnsPadding)
const wndDescH = wndH - wndHeaderHeight - wndFooterH
const wndContentWidth = wndW - (2 * descPadding)

let mkStatusContent = @(text) {
  size = [flex(), wndDescH]
  valign = ALIGN_CENTER
  children = mkTextarea(text, { halign = ALIGN_CENTER })
}

function mkContent(titleStr, descChildren, footerBtnsChildren, onClose, isRootWnd = false, lastScrollPosY = null) {
  let scrollHandler = ScrollHandler()
  local scrollPosY = 0
  return modalWndBg.__merge({
    key = titleStr
    size = [wndW, wndH]
    onAttach = @() scrollHandler.scrollToY(lastScrollPosY?.get() ?? 0)
    onDetach = @() lastScrollPosY?.set(scrollPosY)
    flow = FLOW_VERTICAL
    children = [
      {
        size = [wndW, wndHeaderHeight]
        valign = ALIGN_CENTER
        children = [
          modalWndHeader(titleStr)
          onClose == null ? null : (isRootWnd ? closeWndBtn : mkBackBtn)(onClose, { hotkeys = [btnBEscUp] })
        ]
      }
      {
        size = [wndW, wndDescH + (footerBtnsChildren == null ? wndFooterH : 0)]
        children = makeVertScroll(
          {
            size = FLEX_H
            padding = descPadding
            flow = FLOW_VERTICAL
            children = type(descChildren) == "function" ? descChildren() : descChildren
          },
          {
            rootBase = {
              behavior = [Behaviors.Pannable, Behaviors.ScrollEvent]
              touchMarginPriority = TOUCH_BACKGROUND
              onScroll = function(elem) { scrollPosY = elem?.getScrollOffsY() ?? 0 }
            }
            scrollHandler
          }
        )
      }
      footerBtnsChildren == null ? null : {
        size = [wndW, wndFooterH]
        padding = footerBtnsPadding
        vplace = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = footerBtnsChildren
      }
    ]
  })
}

let openUrl = @(baseUrl) eventbus_send("openUrl", { baseUrl })

let mkTextareaProps = @(ovr) mkTextarea("", { size = [wndContentWidth, SIZE_TO_CONTENT] }.__update(ovr))
let mkTextareaWithLinks = @(text, links, ovr = {}) mkTextareaBlock(text, mkTextareaProps(ovr), links)

return {
  openUrl
  fontDefault
  fontMinor
  textGap

  mkTextarea
  mkTextareaWithLinks
  mkTitle
  mkLink
  separatorLine

  gapAbove
  gapBelow
  gapAboveAndBelow
  fadedAndMinor

  mkContent
  mkStatusContent
}
