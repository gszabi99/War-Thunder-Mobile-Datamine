from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/textButton.nut" import textButtonPurchase, textButtonCommon, buttonStyles
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp, btnAUp
from "%rGui/shop/goodsPreviewState.nut" import openSubsPreview
from "%rGui/shop/shopCommon.nut" import SC_PREMIUM
from "%rGui/shop/shopState.nut" import openShopWnd
from "%rGui/style/backgrounds.nut" import bgShadedDark
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/hangarUnit.nut" import hangarUnitHasLockedPremDecals


let { defButtonMinWidth } = buttonStyles


const WND_UID = "notEmptySlotWnd"

const wndGap = hdpx(40)
let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)
registerHandler("closeNotEmptySlotWnd", @(res) res?.error == null ? close() : null)

function tryPremium() {
  close()
  openShopWnd(SC_PREMIUM)
}

let window = @() modalWndBg.__merge({
  watch = [hangarUnitHasLockedPremDecals, allow_subscriptions]
  size = [2 * defButtonMinWidth + 3 * wndGap, SIZE_TO_CONTENT]
  padding = const [0, 0, wndGap, 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = wndGap
  children = [
    modalWndHeaderWithClose(loc("msgbox/noAvailableSpace"), close)
    {
      size = FLEX_H
      margin = [0, wndGap]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc(!hangarUnitHasLockedPremDecals.get()
          ? "mainmenu/customization/decals/notEmptySlot"
        : allow_subscriptions.get()
          ? "subscrition/activateForDecalSlots"
          : "mainmenu/customization/decals/notEmptySlot/needsPremium")
    }.__update(fontSmall)
    {
      flow = FLOW_HORIZONTAL
      gap = wndGap
      halign = ALIGN_CENTER
      children = !hangarUnitHasLockedPremDecals.get()
        ? textButtonCommon(utf8ToUpper(loc("msgbox/btn_ok")), close, { hotkeys = [btnBEscUp] })
        : [
            textButtonCommon(utf8ToUpper(loc("msgbox/btn_cancel")), close, { hotkeys = [btnBEscUp] })
            allow_subscriptions.get()
              ? textButtonPurchase(utf8ToUpper(loc("subscription/activate")),
                  @() openSubsPreview("vip", "not_empty_slot"),
                  { hotkeys = [btnAUp] })
              : textButtonPurchase(utf8ToUpper(loc("debriefing/tryPremium")),
                  tryPremium,
                  { hotkeys = [btnAUp] })
          ]
    }
  ]
})

let openImpl = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = FLEX
  hotkeys = [[btnBEscUp, { action = close, description = loc("mainmenu/btnClose") }]]
  onClick = close
  children = window
  animations = wndSwitchAnim
}))

if (isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @() isOpened.set(true)
