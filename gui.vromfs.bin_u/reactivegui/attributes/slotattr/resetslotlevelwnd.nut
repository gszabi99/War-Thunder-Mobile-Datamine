from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/goodsView/sharedParts.nut" import pricePlateH, mkBgParticles, mkSlotBgImg

let { slotInProgress, reset_slot_skills, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let { isOpenedSlotResetWnd, attrSlotIdx, slotLevelResetPrice, slotSkillsResetPrice,
  isResetSlotLevelAllowed, isResetSlotSkillsAllowed, resetSlotSelectionData
} = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { buttonsHGap, mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { mkCurrencyComp, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { selectColor, textColor, userlogTextColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGradText } = require("%rGui/components/gradTexts.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_RESET_SLOT_LEVEL, PURCH_TYPE_RESET_SLOT_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")


let WND_UID = "resetSlotLevelWnd"
let blockSize = [hdpx(500), hdpx(280)]
let imgSize = hdpx(150)
let textGradient = mkFontGradient(textColor, selectColor, 11, 6, 2)

let close = @() isOpenedSlotResetWnd.set(false)

registerHandler("closeResetSlotWnd", function(_) {
  resetSlotSelectionData.set(null)
  close()
})

let resetSlotsLevel = @(campaign, _, currencyId, price, cb) resetSlotSelectionData.set({ campaign, currencyId, price, cb })

let mkResetSlotInfo = @(text) {
  size = blockSize
  rendObj = ROBJ_BOX
  borderColor = textColor
  borderWidth = hdpx(2)
  padding = hdpx(2)
  children = [
    mkSlotBgImg()
    {
      size = flex()
      padding = const [hdpx(10), hdpx(20)]
      flow = FLOW_VERTICAL
      gap = hdpx(20)
      vplace = ALIGN_TOP
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        mkGradText(text, fontTinyAccented, textGradient,
          { size = FLEX_H, rendObj = ROBJ_TEXTAREA, behavior = Behaviors.TextArea })
        {
          size = [imgSize, imgSize]
          rendObj = ROBJ_IMAGE
          color = 0xFF65BC82
          image = Picture($"ui/gameuiskin#experience_icon.svg:{imgSize}:{imgSize}:P")
          keepAspect = true
        }
      ]
    }
  ]
}

let mkResetSlotPrice = @(content, stateFlags) @() {
  watch = slotInProgress
  size = const [flex(), pricePlateH]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = slotInProgress.get() != null ? spinner
    : mkCustomButton(content,
        @() null,
        mergeStyles(buttonStyles.PURCHASE, { stateFlags, ovr = { size = flex(), minWidth = 0, behavior = null } }))
}

function mkResetBlock(priceCfg, locId, pServerAction) {
  let { price = 0, currencyId = "" } = priceCfg
  if (price == 0)
    return null

  let stateFlags = Watched(0)
  let bgParticles = mkBgParticles(blockSize)
  function onClick() {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_RESET_SLOT_LEVEL, PURCH_TYPE_RESET_SLOT_LEVEL, "reset_slot_lvl")
    openMsgBoxPurchase({
      text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, loc($"{locId}/approve")) }),
      price = { price, currencyId },
      purchase = @() pServerAction(curCampaign.get(), attrSlotIdx.get(), currencyId, price, "closeResetSlotWnd"),
      bqInfo = bqPurchaseInfo
    })
  }
  let content = mkResetSlotInfo(loc(locId))
  let priceBlock = mkResetSlotPrice(mkCurrencyComp(price, currencyId, CS_COMMON), stateFlags)
  return @() {
    watch = stateFlags
    size = [blockSize[0], SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    gap = -hdpx(2)
    children = [
      {
        size = flex()
        children = bgParticles
      }
      content
      priceBlock
    ]
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let wndContent = @() {
  watch = [slotLevelResetPrice, slotSkillsResetPrice, isResetSlotLevelAllowed, isResetSlotSkillsAllowed]
  flow = FLOW_HORIZONTAL
  padding = buttonsHGap
  gap = buttonsHGap
  children = [
    !isResetSlotSkillsAllowed.get() ? null
      : mkResetBlock(slotSkillsResetPrice.get(), "purchase/resetSlot/slotSkills", reset_slot_skills)
    !isResetSlotLevelAllowed.get() ? null
      : mkResetBlock(slotLevelResetPrice.get(), "purchase/resetSlot/slotLevel", resetSlotsLevel)
  ]
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = @() modalWndBg.__merge({
    watch = attrSlotIdx
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("header/resetSlotLevel", { slotName = loc("gamercard/slot/title", { idx = (attrSlotIdx.get() ?? 0) + 1 }) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      wndContent
    ]
  })
  animations = wndSwitchAnim
}))

if (isOpenedSlotResetWnd.get())
  openImpl()
isOpenedSlotResetWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
