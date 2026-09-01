from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "dagor.workcycle" import resetTimeout
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clientState/clientState.nut" import isOutOfBattleAndResults
import "%appGlobals/config/infoPopupPresentation.nut" as getInfoPopupPresentation
from "%rGui/components/modalWindows.nut" import removeModalWindow, addModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/msgBox.nut" import msgBoxText
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import EMPTY_ACTION
from "%rGui/gameModes/gameModeState.nut" import isRandomBattleNewbie
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/notifications/infoPopupActions.nut" import getPopupActionCfg
from "%rGui/notifications/infoPopupState.nut" import popupToShow, markCurPopupSeen
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


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
  let { descLocId, image, imageSize, innerImage, innerImageSize } = getInfoPopupPresentation(popup.id)
  let desc = doesLocTextExist(descLocId) ? loc(descLocId) : null
  local descBox = msgBoxText(desc, { size = SIZE_TO_CONTENT, maxWidth = contentWidth, halign = ALIGN_LEFT }
    .__update(fontTinyAccented))
  if (calc_comp_size(descBox)[0] >= (contentWidth * (2.0 / 3.0)))
    descBox = msgBoxText(desc, { size = const [contentWidth, SIZE_TO_CONTENT], halign = ALIGN_LEFT }
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
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = !innerImage ? null : {
              size = innerImageSize.map(hdpxi)
              rendObj = ROBJ_IMAGE
              image = Picture($"{innerImage}:0:P")
              keepAspect = true
            }
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
    size = FLEX
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
