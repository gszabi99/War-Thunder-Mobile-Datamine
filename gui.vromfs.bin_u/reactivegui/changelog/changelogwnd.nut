from "%globalsDarg/darg_library.nut" import *
let { clearTimer, setInterval } = require("dagor.workcycle")
let { btnBUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { registerScene } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = buttonStyles
let scrollbar = require("%rGui/components/scrollbar.nut")
let { formatText } = require("textFormatters.nut")
let { isChangeLogOpened, curPatchnoteId, curPatchnoteIdx, playerSelectedPatchnoteId, nextPatchNote,
  prevPatchNote, versions, curPatchnoteContent, markCurPatchVersionSeen, markAllVersionsSeen, closeChangeLog
} = require("changeLogState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let backButton = require("%rGui/components/backButton.nut")
let listButton = require("%rGui/components/listButton.nut")
let { isGamepad } = require("%rGui/activeControls.nut")

let commonTextColor = 0xFFC0C0C0
let hoverTextColor = 0xFFE0E0E0
let activeTextColor = 0xFFFFFFFF

let scrollHandler = ScrollHandler()
let scrollStep = hdpx(75)
let tabPadding = hdpx(5)
let btnGap = hdpx(20)

let scrollPatchnoteWatch = Watched(0)
let moreInfoUrl = $"https://wtmobile.live/{loc("current_lang")}"

let function patchnoteTab(ver) {
  let { id, shortTitle, title, tVersion } = ver
  return listButton(
    @(sf, isSelected) {
      size = [flex(), defButtonHeight]
      padding = [0, tabPadding]
      children = {
        size = [flex(), defButtonHeight]
        behavior = Behaviors.TextArea
        rendObj = ROBJ_TEXTAREA
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = isSelected || (sf & S_ACTIVE) ? activeTextColor
          : sf & S_HOVER ? hoverTextColor
          : commonTextColor
        text = shortTitle ?? title ?? tVersion
      }.__update(fontTiny)
    },
    Computed(@() curPatchnoteId.value == id),
    function onClick() {
      markCurPatchVersionSeen()
      playerSelectedPatchnoteId(id)
    })
}

let tabsHotkeys = [
  ["J:LB", nextPatchNote, loc("mainmenu/btnPagePrev")],
  ["J:RB", prevPatchNote, loc("mainmenu/btnPageNext")],
]
let patchnoteSelector = @() {
  size = flex()
  watch = [versions, isGamepad]
  flow = FLOW_HORIZONTAL
  gap = btnGap
  children = versions.value.len() <= 1 ? null
    : versions.value.map(patchnoteTab)
      .append(!isGamepad.value || versions.value.len() <= 1 ? null
        : { hotkeys = tabsHotkeys })
}

let missedPatchnoteText = formatText([loc("NoUpdateInfo")])

let seeMoreUrl = {
  t = "url"
  url = moreInfoUrl
  v = loc("visitGameSite", "See game website for more details")
  margin = [hdpx(50), 0, 0, 0]
}

let function scrollPatchnote() {  //FIX ME: Remove this code, when native scroll will have opportunity to scroll by hotkeys.
  let element = scrollHandler.elem
  if (element != null)
    scrollHandler.scrollToY(element.getScrollOffsY() + scrollPatchnoteWatch.value * scrollStep)
}

scrollPatchnoteWatch.subscribe(function(value) {
  clearTimer(scrollPatchnote)
  if (value == 0)
    return

  scrollPatchnote()
  setInterval(0.1, scrollPatchnote)
})

let scrollPatchnoteBtn = @(hotkey, watchValue) {
  behavior = Behaviors.Button
  onElemState = @(sf) scrollPatchnoteWatch((sf & S_ACTIVE) ? watchValue : 0)
  hotkeys = [[hotkey]]
  onDetach = @() scrollPatchnoteWatch(0)
}

curPatchnoteContent.subscribe(@(_) scrollHandler.scrollToY(0))

let patchnoteLoading = freeze({
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow  = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    formatText([{ v = loc("loading"), t = "h2", halign = ALIGN_CENTER }]),
    mkSpinner()
  ]
})

let mkContent = @(content) {
  size = [flex(), SIZE_TO_CONTENT]
  maxWidth = hdpx(1500)
  hplace = ALIGN_CENTER
  children = formatText(content.len() == 0 ? missedPatchnoteText
    : (clone content).append(seeMoreUrl))
}

let patchnoteContent = @() {
  watch = curPatchnoteContent
  size = flex()
  children = curPatchnoteContent.value == null ? patchnoteLoading
    : [
        scrollbar.makeSideScroll(mkContent(curPatchnoteContent.value.content), {
          scrollHandler = scrollHandler
          joystickScroll = false
        })
        scrollPatchnoteBtn("^J:R.Thumb.Up | PageUp", -1)
        scrollPatchnoteBtn("^J:R.Thumb.Down | PageDown", 1)
      ]
}

let btnNext  = textButtonCommon(loc("mainmenu/btnNextItem"), nextPatchNote,
  { hotkeys = [$"{btnBUp} | Tab"] })
let btnClose = textButtonCommon(loc("mainmenu/btnClose"),
  function() {
    markAllVersionsSeen()
    closeChangeLog()
  },
  { hotkeys = [btnBUp] })

let nextButton = @() {
  watch = [curPatchnoteIdx]
  children = curPatchnoteIdx.value > 0 ? btnNext : btnClose
}

let header = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    backButton(function() {
      markAllVersionsSeen()
      closeChangeLog()
    })
    @() {
      watch = curPatchnoteContent
      rendObj = ROBJ_TEXT
      color = activeTextColor
      text = curPatchnoteContent.value?.title
      margin = [0, 0, 0, hdpx(15)]
    }.__update(fontMedium)
  ]
}

let changeLogWnd = bgShaded.__merge({
  size = flex()
  padding = saBordersRv
  onDetach = markCurPatchVersionSeen
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    patchnoteContent
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = btnGap
      children = [
        patchnoteSelector
        nextButton
      ]
    }
  ]
})

registerScene("changeLogWnd", changeLogWnd, closeChangeLog, isChangeLogOpened)
