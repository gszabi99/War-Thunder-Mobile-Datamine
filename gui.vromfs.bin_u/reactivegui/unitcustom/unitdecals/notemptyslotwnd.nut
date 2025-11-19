from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { allow_subscriptions } = require("%appGlobals/permissions.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { hangarUnitHasLockedPremDecals } = require("%rGui/unit/hangarUnit.nut")
let { textButtonPurchase, textButtonCommon, buttonStyles } = require("%rGui/components/textButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { btnBEscUp, btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { defButtonMinWidth } = buttonStyles


let WND_UID = "notEmptySlotWnd"

let wndGap = hdpx(40)
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
  padding = [0, 0, wndGap, 0]
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
              ? textButtonPurchase(utf8ToUpper(loc("subscription/activate")), @() openSubsPreview("vip"), { hotkeys = [btnAUp] })
              : textButtonPurchase(utf8ToUpper(loc("debriefing/tryPremium")), tryPremium, { hotkeys = [btnAUp] })
          ]
    }
  ]
})

let openImpl = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  hotkeys = [[btnBEscUp, { action = close, description = loc("mainmenu/btnClose") }]]
  onClick = close
  children = window
  animations = wndSwitchAnim
}))

if (isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @() isOpened.set(true)
