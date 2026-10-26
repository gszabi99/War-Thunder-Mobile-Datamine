from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
from "%rGui/clans/components/clanComps.nut" import mkButtonText
import "%rGui/components/listButton.nut" as listButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const btnGap = hdpx(30)
const contentPadding = hdpx(60)

function mkChooseValueContent(cfg, currentW, ovr = {}, close = null) {
  let { values = [], ctor = null, selected = Watched(currentW.get()), setValue = @(_) null, padding = null,
    textToUpper = true
  } = cfg
  let columns = cfg?.col ?? cfg?.values.len() ?? 0
  return @() {
    minWidth = cfg.btnMinWidth * columns + btnGap * (columns - 1) + (padding ?? contentPadding) * 2
    halign = ALIGN_CENTER
    onAttach = @() selected.set(currentW.get())
    padding = padding ?? contentPadding
    flow = FLOW_VERTICAL
    gap = btnGap
    children = arrayByRows(values.map(@(v) listButton(
        ctor?(v) ?? mkButtonText(v, cfg, textToUpper),
        Computed(@() selected.get() == v),
        function() {
          setValue(v)
          selected.set(v)
          if (close)
            close()
        }
        { minWidth = cfg.btnMinWidth, size = SIZE_TO_CONTENT, hasBorderSelection = cfg?.withBorder })), columns).map(@(r) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = btnGap
      children = r
    })
  }.__update(ovr)
}

function openChooseValueWnd(cfg, currentW, setValue) {
  let { values = [], locTitle, fullLocTitle = null } = cfg
  if (values.len() == 0)
    return
  let selected = Watched(currentW.get())

  function closeModal() {
    if (values.contains(selected.get()))
      setValue(selected.get())
    removeModalWindow(locTitle)
  }

  addModalWindow(bgShaded.__merge({
    key = locTitle
    size = FLEX
    onClick = closeModal
    children = @() modalWndBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        modalWndHeaderWithClose(loc(fullLocTitle ?? locTitle), closeModal)
        mkChooseValueContent(cfg.__merge({ selected }), currentW, {}, closeModal)
      ]
    })
    animations = wndSwitchAnim
  }))
}

return { openChooseValueWnd, mkChooseValueContent, btnGap }