from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { debugModes } = require("gameModeState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndUid = "debugGameModes"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(10)

let noGameModes = {
  size = [ hdpx(500), SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
  text = "No debug game modes at this moment"
}.__update(fontMedium)

function gameModesList() {
  let res = {
    watch = debugModes
    size = [flex(), SIZE_TO_CONTENT]
    padding = gap
    children = noGameModes
  }

  if (debugModes.value.len() == 0)
    return res

  let modes = debugModes.value.values()
    .sort(@(a, b) (a?.name ?? "") <=> (b?.name ?? ""))
    .map(@(m) textButtonCommon(m?.name ?? m?.gameModeId ?? "!!!ERROR!!!",
      function() {
        eventbus_send("queueToGameMode", { modeId = m?.gameModeId })
        close()
      },
      { ovr = { size = [flex(), hdpx(100)] } }))
  let rows = arrayByRows(modes, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  })
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close }]]
  children = {
    size = [sh(130), sh(90)]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug game modes"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      makeVertScroll(
        gameModesList,
        { rootBase = { behavior = Behaviors.Pannable } })
    ]
  }
})