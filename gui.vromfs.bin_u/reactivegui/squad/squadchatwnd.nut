from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%rGui/chat/chatPkg.nut" import mkChatTextInput, mkChatLog, msgListGap
from "%rGui/components/animGrowLines.nut" import mkAnimGrowLinesFromRectToWnd
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/squad/squadChatState.nut" import squadChatId


const WND_UID = "squad_chat_wnd"

let wndSize = [hdpx(1150), hdpx(800)]
const wndMargin = hdpx(40)

let openParams = mkWatched(persist, "openParams", null)
let wndAABB = Watched(null)

let close = @() openParams.set(null)
openParams.subscribe(@(_) wndAABB.set(null))
squadChatId.subscribe(@(v) v == null ? close() : null)

let wndKey = {}
let window = @() {
  watch = squadChatId
  key = wndKey
  size = wndSize
  padding = [0, msgListGap, msgListGap, msgListGap]

  onAttach = @() defer(@() wndAABB.set(gui_scene.getCompAABBbyKey(wndKey)))
  stopMouse = true
  rendObj = ROBJ_SOLID
  color = 0x80202020

  flow = FLOW_VERTICAL
  children = [
    mkChatLog(squadChatId.get(), wndSize[0] - 2 * msgListGap, loc("squad/chat"))
    mkChatTextInput(squadChatId.get(), close)
  ]
}

function content() {
  if (openParams.get() == null)
    return { watch = openParams }

  let { rect } = openParams.get()
  let { r, l, t, b } = rect
  let isFitTop = t - saBorders[0] - wndSize[1] >= 0
  let wndPos = [
    isFitTop ? (l + r) / 2 - wndSize[0] / 2
      : l - wndMargin - wndSize[0],
    isFitTop ? t - wndMargin - wndSize[1]
      : (b + t) / 2 - wndSize[1] / 2
  ]

  return {
    watch = openParams
    size = FLEX
    children = mkAnimGrowLinesFromRectToWnd(rect, wndAABB, wndPos, window)
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = FLEX
  children = content
  onClick = close
})

if (openParams.get() != null)
  openImpl()
openParams.subscribe(@(v) v != null ? openImpl() : removeModalWindow(WND_UID))


return @(rect) openParams.set({ rect })