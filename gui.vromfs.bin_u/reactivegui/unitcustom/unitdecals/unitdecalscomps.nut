from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "%appGlobals/permissions.nut" import allow_subscriptions
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let decalIconSize = evenPx(130)
let disableIconSize = evenPx(100)
let decalIconSizeBig = evenPx(180)
let borderWidth = hdpxi(4)
let decalsGap = hdpxi(8)
let decalCardWidth = decalIconSize + 2 * borderWidth
let selBorderDecalColor = selectColor
let commonBgColor = 0x70000000
let decalsFooterHeight = decalCardWidth + decalsGap * 2

let mkDecalIcon = @(img, size = decalIconSize) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"!{img}*")
  keepAspect = true
}

let mkDecalText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  halign = ALIGN_CENTER
  maxWidth = hdpx(300)
  text
}.__update(ovr)

let mkDecalTitle = @(name) mkDecalText(loc($"decals/{name}"), fontVeryTinyAccentedShaded)

function mkDecalDesc(name) {
  let locId = $"decals/{name}/desc"
  if (!doesLocTextExist(locId))
    return null
  let text = loc(locId)
  if (text == "" || text == loc($"decals/{name}"))
    return null
  return mkDecalText(text, fontVeryVeryTinyAccented)
}

let mkDecalPrice = @(isAvailable, decalPrice, ovr = {}) @() {
  watch = [isAvailable, decalPrice]
  size = [flex(), ph(30)]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = !isAvailable.get() && (decalPrice.get()?.price ?? 0) > 0
    ? [
        {
          size = flex()
          rendObj = ROBJ_BOX
          fillColor = commonBgColor
        }
        mkCurrencyComp(decalPrice.get().price, decalPrice.get().currencyId, CS_SMALL)
          .__update({ pos = [borderWidth, 0] })
      ]
    : null
}.__update(ovr)

let decalBackground = {
  size = flex()
  padding = borderWidth
  borderWidth
  rendObj = ROBJ_BOX
  fillColor = 0xFFFFFFFF
  opacity = 0.2
}

function mkDecalCard(decal, availableDecals, selectedDecal, onSelect) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() decal.get()?.name == selectedDecal.get())
  let isAvailable = Computed(@() decal.get()?.name in availableDecals.get())
  let decalPrice = Computed(@() decal.get()?.price)
  return @() !decal.get() ? { watch = decal }
    : {
        watch = [stateFlags, decal, isSelected]
        key = decal.get().name
        size = decalCardWidth
        padding = borderWidth
        rendObj = ROBJ_BOX
        borderColor = isSelected.get() ? selBorderDecalColor : 0
        borderWidth
        behavior = Behaviors.Button
        transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
        transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
        children = [
          decalBackground
          mkDecalIcon(decal.get().name)
          mkDecalPrice(isAvailable, decalPrice)
        ]
      }.__update(mkButtonHoldTooltip(@() onSelect(decal.get().name), stateFlags, decal.get().name,
        @() {
          content = @() {
            watch = decal
            halign = ALIGN_CENTER
            valign =  ALIGN_CENTER
            flow = FLOW_VERTICAL
            gap = hdpx(10)
            children = [
              mkDecalTitle(decal.get().name)
              mkDecalDesc(decal.get().name)
              {
                children = [
                  decalBackground
                  mkDecalIcon(decal.get().name, decalIconSizeBig)
                ]
              }
              mkDecalPrice(isAvailable, decalPrice, { size = SIZE_TO_CONTENT })
            ]
          }
        }))
}

let disabledSlotContent = @() {
  watch = allow_subscriptions
  size = flex()
  rendObj = ROBJ_BOX
  fillColor = commonBgColor
  opacity = 0.8
  children = {
    size = disableIconSize
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = allow_subscriptions.get()
      ? Picture($"ui/gameuiskin#subs_prem.avif:{disableIconSize}:{disableIconSize}:P")
      : Picture($"ui/gameuiskin#premium_active_big.avif:{disableIconSize}:{disableIconSize}:P")
  }
}

let emptySlotContent = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("ui/empty")
}.__update(fontVeryTinyAccentedShaded)

let mkEmptyDecalSlot = @(isSelected, isDisabled, editingDecalId) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    isDisabled || (editingDecalId != null && isSelected) ? null : emptySlotContent
    isDisabled ? disabledSlotContent : null
    !isDisabled && editingDecalId != null && isSelected
      ? mkDecalIcon(editingDecalId)
      : null
  ]
}

let mkDefaultDecalSlot = @(decalId, isDisabled) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkDecalIcon(decalId)
    isDisabled ? disabledSlotContent : null
  ]
}

function mkDecalSlot(slot, selectedSlotId, editingDecalId, handleClick) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selectedSlotId.get() == slot.id)
  return @() {
    watch = [stateFlags, isSelected, editingDecalId]
    size = decalCardWidth
    padding = borderWidth
    rendObj = ROBJ_BOX
    borderColor = isSelected.get() ? selBorderDecalColor : 0
    borderWidth = isSelected.get() ? borderWidth : 0
    behavior = Behaviors.Button
    onClick = @() handleClick(slot.id)
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
    children = [
      decalBackground
      slot.isEmpty
        ? mkEmptyDecalSlot(isSelected.get(), slot.isDisabled, editingDecalId.get())
        : mkDefaultDecalSlot(slot.decalId, slot.isDisabled)
    ]
  }
}

return {
  mkDecalCard
  decalCardWidth
  decalsGap
  commonBgColor
  decalsFooterHeight
  mkDecalIcon
  mkDecalSlot
  mkDecalText
}
