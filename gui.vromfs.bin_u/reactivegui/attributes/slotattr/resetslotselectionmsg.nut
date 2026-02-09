from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { reset_slots_level } = require("%appGlobals/pServer/pServerApi.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { CS_INCREASED_ICON, CS_INACTIVE_ICON, mkCurrencyImage, mkCurrencyText } = require("%rGui/components/currencyComp.nut")
let { isOpenedSlotSelection, resetSlotSelectionData } = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { buttonsHGap, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgUnit, unitPlateRatio } = require("%rGui/unit/components/unitPlateComp.nut")
let { revealAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { mkSlotLevel } = require("%rGui/attributes/slotAttr/slotLevelComp.nut")
let { maxSlotLevels } = require("%rGui/slotBar/slotBarState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")


let RESET_SLOT_SELECTION_UID = "resetSlotSelection"

let iconStyle = CS_INCREASED_ICON
let iconSize = iconStyle.iconSize
let slotWidth = evenPx(370)
let slotHeight = (slotWidth * unitPlateRatio).tointeger()
let slotSize = [slotWidth, slotHeight]
let levelImageSize = evenPx(30)
let selBorderColor = 0xFFFFFFFF
let hoverBorderColor = 0x40404040
let borderHeight = hdpx(8)
let checkIconSize = hdpxi(80)
let highlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 25, 22, 31,-22))

let selIndexes = Watched([])
let canApplySlotsReset = Computed(@() selIndexes.get()
  .filter(@(v) (curSlots.get()?[v].level ?? 0) > 0 || (curSlots.get()?[v].exp ?? 0) > 0).len() > 0)

let close = @() resetSlotSelectionData.set(null)

function selectSlot(selectedIdx) {
  selIndexes.mutate(function(v) {
    let index = v.findindex(@(idx) idx == selectedIdx)
    if (index != null)
      v.remove(index)
    else
      v.append(selectedIdx)
  })
}

let textComp = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny, ovr)

let textareaComp = @(text, ovr = {}) {
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  rendObj = ROBJ_TEXTAREA
  text
}.__update(fontTiny, ovr)

let mkSlotInfo = @(slot, idx) {
  size = slotSize
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  children = [
    {
      padding = [hdpx(5), hdpx(10)]
      children = textComp(loc("gamercard/slot/title", { idx = idx + 1 }), fontVeryTinyAccented)
    }
    { size = flex() }
    mkSlotLevel(slot?.level ?? 0, levelImageSize)
  ]
}

let mkHightlightPlate = @(isSelected) {
  size = flex()
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      flipY = true
      image = highlight()
      animations = revealAnimation(0)
      transform = { rotate = 180 }
      opacity = 0.2
    }
    {
      size = [flex(), borderHeight]
      pos = [0, -borderHeight]
      rendObj = ROBJ_BOX
      hplace = ALIGN_TOP
      fillColor = isSelected ? selBorderColor : hoverBorderColor
    }
    !isSelected ? null
      : {
          size = checkIconSize
          margin = [0, hdpx(10)]
          rendObj = ROBJ_IMAGE
          hplace = ALIGN_LEFT
          vplace = ALIGN_TOP
          image = Picture($"ui/gameuiskin#mark_check.svg:{checkIconSize}:{checkIconSize}:P")
          keepAspect = true
        }
  ]
}

let mkCurrencyComp = @(value, currencyId, isInactive) {
  size = [SIZE_TO_CONTENT, iconSize]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    mkCurrencyImage(currencyId, iconSize)
    mkCurrencyText(value, isInactive ? iconStyle.__merge(CS_INACTIVE_ICON) : iconStyle)
  ]
}

function mkSlotBtn(slot, idx) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selIndexes.get().indexof(idx) != null)

  return @() {
    watch = [isSelected, stateFlags]
    size = slotSize
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    onClick = @() selectSlot(idx)
    sound = { click  = "click" }
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = bgUnit
        children = [
          {
            size = slotSize
            rendObj = ROBJ_IMAGE
            keepAspect = true
            image = Picture($"ui/gameuiskin/upgrades_tank_crew_icon.avif:{slotSize[0]}:{slotSize[1]}:P")
          }
          mkSlotInfo(slot, idx)
        ]
      }
      !isSelected.get() && !(stateFlags.get() & S_HOVER) ? null
        : mkHightlightPlate(isSelected.get())
    ]
  }
}

function mkSlotExp(slot) {
  let fullSlotExp = Computed(function() {
    local res = slot.exp
    for (local lvl = 0; lvl < slot.level; lvl++)
      res += maxSlotLevels.get()?[lvl].exp ?? 0
    return res
  })
  return @() {
    watch = fullSlotExp
    children = {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        {
          size = levelImageSize
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#experience_icon.svg:{levelImageSize}:{levelImageSize}:P")
          color = 0xFF65BC82
        }
        textComp(decimalFormat(fullSlotExp.get()))
      ]
    }
  }
}

let mkSlot = @(slot, idx) {
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  halign = ALIGN_CENTER
  children = [
    mkSlotBtn(slot, idx)
    textareaComp(loc($"header/resetSlotSelection/availableForReset"), { maxWidth = slotWidth })
    mkSlotExp(slot)
  ]
}

function content() {
  let { currencyId = "", price = 0, campaign = "", cb = "" } = resetSlotSelectionData.get()
  return {
    watch = [curSlots, selIndexes, resetSlotSelectionData, canApplySlotsReset]
    padding = buttonsHGap
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = buttonsHGap
    children = resetSlotSelectionData.get() == null ? null
    : [
        {
          flow = FLOW_HORIZONTAL
          gap = hdpx(20)
          children = curSlots.get().map(mkSlot)
        }
        textButtonPricePurchase(utf8ToUpper(loc("purchase/resetSelectedSlots/approve")),
          mkCurrencyComp(price, currencyId, !canApplySlotsReset.get()),
          @() !canApplySlotsReset.get() ? null
            : reset_slots_level(campaign, selIndexes.get(), currencyId, price, cb),
          (!canApplySlotsReset.get() ? buttonStyles.INACTIVE : {}).__merge({ hotkeys = ["^J:Y"], useFlexText = true }))
      ]
  }
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = RESET_SLOT_SELECTION_UID
  size = flex()
  onClick = close
  onAttach = @() selIndexes.set(curSlots.get().map(@(_, i) i))
  children = modalWndBg.__merge({
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("header/resetSlotSelection"),
        close,
        { minWidth = SIZE_TO_CONTENT })
      content
    ]
  })
  animations = wndSwitchAnim
}))

if (isOpenedSlotSelection.get())
  openImpl()
isOpenedSlotSelection.subscribe(@(v) v ? openImpl() : removeModalWindow(RESET_SLOT_SELECTION_UID))
