from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { doesLocTextExist } = require("dagor.localize")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let getInfoPopupPresentation = require("%appGlobals/config/infoPopupPresentation.nut")
let { isRandomBattleNewbie } = require("%rGui/gameModes/gameModeState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { popupToShow, markCurPopupSeen } = require("%rGui/notifications/infoPopupState.nut")
let { getPopupActionCfg } = require("%rGui/notifications/infoPopupActions.nut")

let { removeModalWindow, addModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { EMPTY_ACTION } = require("%rGui/controlsMenu/gpActBtn.nut")


const WND_UID = "infoPopupWnd"
const contentWidth = hdpx(1200)
const gap = hdpx(40)
const wndWidth = contentWidth + 2 * gap

let needShow = keepref(Computed(@() popupToShow.get() != null
  && isInMenuNoModals.get()
  && isOutOfBattleAndResults.get()
  && !isRandomBattleNewbie.get()))


function mkActionButton(popup) {
  let { action, params } = popup
  let { mkHasAction = null, exec = null } = getPopupActionCfg(action)
  let closeButton = textButtonPrimary(utf8ToUpper(loc("msgbox/btn_ok")), markCurPopupSeen, { hotkeys = ["^J:A"] })
  if (exec == null)
    return closeButton

  let hasAction = mkHasAction?(params) ?? Watched(true)
  return @() {
    watch = hasAction
    children = !hasAction.get() ? closeButton
      : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")),
          function() {
            markCurPopupSeen()
            exec(params)
          },
          { hotkeys = ["^J:A"] })
  }
}

function mkContent(popup) {
  let { descLocId, image, imageSize } = getInfoPopupPresentation(popup.id)
  let desc = doesLocTextExist(descLocId) ? loc(descLocId) : null
  local descBox = msgBoxText(desc, { size = SIZE_TO_CONTENT, maxWidth = contentWidth, halign = ALIGN_LEFT }
    .__update(fontTinyAccented))
  if (calc_comp_size(descBox)[0] >= (contentWidth * (2.0 / 3.0)))
    descBox = msgBoxText(desc, { size = [contentWidth, SIZE_TO_CONTENT], halign = ALIGN_LEFT }
      .__update(fontTinyAccented))
  return {
    size = FLEX_H
    padding = gap
    flow = FLOW_VERTICAL
    gap
    halign = ALIGN_CENTER
    children = [
      image == null ? null
        : {
            size = imageSize.map(hdpxi)
            rendObj = ROBJ_IMAGE
            image = Picture(image)
            keepAspect = true
          }
      desc == null ? null : descBox
      mkActionButton(popup)
    ]
  }
}

function tryOpenWnd() {
  if (!needShow.get())
    return

  addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = flex()
    onClick = EMPTY_ACTION
    children = @() popupToShow.get() == null ? { watch = popupToShow }
      : modalWndBg.__merge({
          watch = popupToShow
          size = const [wndWidth, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          children = [
            modalWndHeaderWithClose(
              loc(getInfoPopupPresentation(popupToShow.get().id).locId),
              markCurPopupSeen,
              {
                minWidth = SIZE_TO_CONTENT,
                padding = const [0, hdpx(10)]
              })
            mkContent(popupToShow.get())
          ]
        })
    animations = wndSwitchAnim
  }))
}

needShow.subscribe(@(v) v ? resetTimeout(0.3, tryOpenWnd) : null)
popupToShow.subscribe(@(v) v == null ? removeModalWindow(WND_UID) : null)
