from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import calc_golden_ratio_columns, ceil
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/clanPresentation.nut" import badgeColors, badgeIcons, badgeFrames, getClanBg, badgeBgOrder
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgePreview, mkBadgePartImg
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanChangeBtn, propertyBtnDefHeight
from "%rGui/clans/components/chooseValueWnd.nut" import mkChooseValueContent, btnGap
from "%rGui/components/modalWindows.nut" import removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const WND_UID = "badge_editor"

const smallBtnGap = hdpx(15)
const addSmallBtnGap = hdpx(27)
const badgeOptionBtnSize = [hdpx(370), propertyBtnDefHeight]

const selectorBtnWidth = hdpxi(100)
const selectorPadding = hdpx(16)
const iconRatio = 0.8
const iconSize = (selectorBtnWidth * iconRatio).tointeger()

let maxAmount = max(badgeColors.len(), badgeIcons.len(), badgeFrames.len())
let cols = clamp(calc_golden_ratio_columns(maxAmount), 3, 7)
let rows = clamp(ceil(maxAmount.tofloat() / cols), 2, 6)

let selectorHeight = selectorBtnWidth * rows + btnGap * (rows - 1) + selectorPadding * 2

let mkColorBox = @(color) {
  size = selectorBtnWidth
  rendObj = ROBJ_IMAGE
  image = getClanBg(color)
}

let mkPartCtor = @(img, color) {
  size = selectorBtnWidth,
  children = mkBadgePartImg(img, iconSize, color)
}

let mkBadgeCfg = @(allState) {
  badge_icon = {
    locTitle = "clans/badge/icon"
    values = badgeIcons
    ctor = @(v) mkPartCtor(v, 0xFFFFFFFF)
  }
  badge_icon_color = {
    locTitle = "clans/badge/iconColor"
    ctor = @(v) mkPartCtor(allState.get().badge_icon, v)
  }
  badge_frame = {
    locTitle = "clans/badge/frame"
    values = badgeFrames
    ctor = @(v) mkPartCtor(v, 0xFFFFFFFF)
  }
  badge_frame_color = {
    locTitle = "clans/badge/frameColor"
    ctor = @(v) mkPartCtor(allState.get().badge_frame, v)
  }
  badge_bg_color = {
    values = badgeBgOrder
    locTitle = "clans/badge/bgColor"
    ctor = mkColorBox
  }
}.map(@(cfg, k) {
  selectorState = Computed(@() allState.get()[k])
  col = cols,
  btnMinWidth = selectorBtnWidth,
  withBorder = true
  setValue = @(value) allState.mutate(@(state) state[k] = value),
  padding = selectorPadding,
  values = badgeColors,
  ...cfg,
})
let badgeOrder = ["badge_icon", "badge_icon_color", "badge_frame", "badge_frame_color", "badge_bg_color"]

let selectedBtn = Watched(badgeOrder.findvalue(@(_) true))

let closeModal = @() removeModalWindow(WND_UID)

let mkSelector = @(badgeCfg, allState) function() {
  let cfg = badgeCfg?[selectedBtn.get()]
  if (cfg == null)
    return { watch = selectedBtn }

  let { selectorState } = cfg
  return {
    watch = [selectedBtn, selectorState, allState]
    children = {
      rendObj = ROBJ_BOX
      fillColor = 0xFF304453
      borderColor = 0xFFEEEEEE
      borderWidth = hdpx(4)
      padding = hdpx(4)
      clipChildren = true
      children = makeVertScroll(
        mkChooseValueContent(cfg,
          selectorState,
          {
            rendObj = ROBJ_BOX
            fillColor = 0xFF304453
            minHeight = selectorHeight
          })
        { size = [SIZE_TO_CONTENT, selectorHeight] }
      )
    }
  }
}

let linesComp = {
  size = const [hdpx(50), FLEX]
  children = function() {
    let idx = badgeOrder.findindex(@(v) v == selectedBtn.get())
    if (idx == null)
      return { watch = selectedBtn }

    let addMargin = (idx / 2) * addSmallBtnGap
    let margin = idx * (propertyBtnDefHeight + smallBtnGap) + propertyBtnDefHeight / 2 + addMargin
    let lineHeight = max(0, margin - selectorHeight)
    return {
      watch = selectedBtn
      size = [hdpx(50), lineHeight]
      margin = [margin - lineHeight, 0, 0, 0]
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = hdpx(4)
      color = 0xFFEEEEEE
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      commands = const [
        [VECTOR_LINE, 0, 100, 50, 100],
        [VECTOR_LINE, 50, 100, 50, 0],
        [VECTOR_LINE, 50, 0, 100, 0]
      ]
    }
  }
}

function badgeEditorWnd(clanBadgeState) {
  let badgeCfg = mkBadgeCfg(clanBadgeState)
  return bgShaded.__merge({
    key = WND_UID
    size = FLEX
    children = modalWndBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        modalWndHeaderWithClose(loc("clans/badge/edit"), closeModal)
        {
          padding = [hdpx(44), hdpx(96)]
          flow = FLOW_HORIZONTAL
          children = [
            mkClanBadgePreview(clanBadgeState, hdpx(250))
            {
              flow = FLOW_VERTICAL
              gap = hdpx(100)
              margin = [0, 0, 0, hdpx(100)]
              children = {
                flow = FLOW_VERTICAL
                gap = smallBtnGap
                children = badgeOrder.map(@(id, idx) {
                  margin = [idx != 0 && idx % 2 == 0 ? addSmallBtnGap : 0, 0, 0, 0]
                  children = mkClanChangeBtn(
                    utf8ToUpper(loc(badgeCfg[id].locTitle)),
                    @() selectedBtn.set(id),
                    badgeOptionBtnSize,
                    {
                      childOvr = { size = badgeOptionBtnSize, padding = [0, hdpx(5)] }
                      hotkeyBlockOvr = { halign = ALIGN_LEFT }
                    })
                })
              }
            }
            linesComp
            mkSelector(badgeCfg, clanBadgeState)
          ]
        }
      ]
    })
    animations = wndSwitchAnim
  })
}

return {
  badgeEditorWnd
}