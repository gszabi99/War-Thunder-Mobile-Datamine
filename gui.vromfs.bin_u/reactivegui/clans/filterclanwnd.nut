from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
from "%rGui/clans/clanState.nut" import closeClanFilters, isClanFiltersOpen
from "%rGui/clans/components/clanComps.nut" import mkButtonText
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanPropertyBtnWithTitle
from "%rGui/clans/components/chooseValueWnd.nut" import openChooseValueWnd
from "%rGui/clans/filterClanState.nut" import filters, clanFilterComp, mkSetFilterValue, resetFilter
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/textButton.nut" import textButtonPrimary, iconButtonCommon
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const WND_UID = "clan_filters"
const filterColumns = 3
const resetIconSize = hdpxi(80)
const clearIconSize = hdpxi(50)

let close = @() isClanFiltersOpen.set(false)

let btnDefOvr = {
  iconOvr = { size = clearIconSize },
  ovr = {
    size = [resetIconSize, resetIconSize]
    minWidth = resetIconSize
    vplace = ALIGN_CENTER
  }
}

function wndContent() {
  let filterCurrent = {}
  foreach (f in filters)
    filterCurrent[f.id] <- Computed(@() clanFilterComp.get()?[f.id])
  let resetIconBtn = iconButtonCommon("ui/gameuiskin#btn_trash.svg", resetFilter, btnDefOvr)
  let applyBtn = textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), closeClanFilters,
    { ovr = { size = [hdpx(300), hdpx(84)], minWidth = hdpx(300) } } )

  return function() {
    let rows = arrayByRows(filters.map(@(f) mkClanPropertyBtnWithTitle(f,
        mkButtonText(clanFilterComp.get()?[f.id], f),
        @() openChooseValueWnd(f, filterCurrent[f.id], mkSetFilterValue(f.id)))),
      filterColumns)

    return {
      watch = clanFilterComp
      size = const [SIZE_TO_CONTENT, hdpx(500)]
      padding = hdpx(60)
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(60)
      children = rows.map(@(row) {
          flow = FLOW_HORIZONTAL
          gap = hdpx(60)
          children = row
        }).append({ size = FLEX },
          {
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children = [resetIconBtn, applyBtn]
          })
    }
  }
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = FLEX
  onClick = close
  children = @() modalWndBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(loc("filters"), close)
      wndContent()
    ]
  })
  animations = wndSwitchAnim
}))

if (isClanFiltersOpen.get())
  openImpl()
isClanFiltersOpen.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
