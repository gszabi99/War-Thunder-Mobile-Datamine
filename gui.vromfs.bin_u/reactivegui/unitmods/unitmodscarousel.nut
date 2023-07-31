from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { unit, unitMods, curModId, getModCurrency, getModCost } = require("unitModsState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")

let modsGap = hdpx(10)
let selLineGap = hdpx(14)
let selLineHeight = hdpx(7)
let lineColor = 0xFF75D0E7
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let transDuration = 0.3
let contentMargin = hdpx(20)
let lockedBg = 0x80000000
let modH = hdpx(170)
let modW = hdpx(440)
let equippedColor = 0xFF50C0FF
let equippedFrameWidth = hdpx(4)
let lockIconSize = hdpxi(44)
let modTotalH = modH + selLineHeight + selLineGap
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:P"

let iconTankSize = [hdpxi(95), hdpxi(41)]
let iconShipSize = [hdpxi(44), hdpxi(51)]
let iconsCfg = {
  tank = {
    img = "selected_icon_tank.svg"
    size = iconTankSize
  }
  ship = {
    img = "selected_icon.svg"
    size = iconShipSize
  }
}

let bgGradient = mkBitmapPicture(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 8, gradTexSize / 3, gradTexSize / 2, gradTexSize / 4))
let lineGradient = mkBitmapPicture(gradTexSize, 4, mkGradientCtorDoubleSideX(0, lineColor))

let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]

let mkNotPurchasedShade = @(isPurchased) @() isPurchased.value ? { watch = isPurchased }
  : {
      watch = isPurchased
      size = flex()
      rendObj = ROBJ_SOLID
      color = lockedBg
    }

let selectedLine = @(isActive) @() {
  watch = isActive
  size = [flex(), selLineHeight]
  rendObj = ROBJ_IMAGE
  image = lineGradient
  opacity = isActive.value ? 1 : 0
  transitions = opacityTransition
}

let mkLevelLock = @(isLocked, reqLevel) @() !isLocked.value ? { watch = isLocked }
  : {
      watch = isLocked
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = [lockIconSize, lockIconSize]
          image = Picture($"ui/gameuiskin#lock_icon.svg:{lockIconSize}:{lockIconSize}:P")
        }
        {
          rendObj = ROBJ_TEXT
          text = "".concat(loc("multiplayer/level"), "  ", reqLevel)
        }.__update(fontSmall)
      ]
    }

let mkModContent = @(content, isActive, isHover) {
  size = [SIZE_TO_CONTENT, modH]

  children = [
    @() {
      watch = isActive
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgColor
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isActive.value ? 1
        : isHover.value ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

let mkEquippedFrame = @(isEquipped) @() !isEquipped.value ? { watch = isEquipped }
  : {
      watch = isEquipped
      size = [modW, modH]
      rendObj = ROBJ_FRAME
      borderWidth = equippedFrameWidth
      color = equippedColor
    }

let function mkEquippedIcon(isEquipped) {
  let icon = Computed(@() iconsCfg?[unit.value.unitType] ?? iconsCfg.tank)

  return @() !isEquipped.value ? { watch = [unit, isEquipped] }
    : {
        watch = [unit, isEquipped]
        margin = hdpx(10)
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        size = icon.value.size
        rendObj = ROBJ_IMAGE
        color = equippedColor
        keepAspect = KEEP_ASPECT_FIT
        image = Picture($"ui/gameuiskin#{icon.value.img}:{icon.value.size[0]}:{icon.value.size[1]}:P")
      }
}

let function modData(mod) {
  let id = mod?.name
  let locId = $"modification/{id}"
  let image = $"ui/gameuiskin#{id}.avif:O:P"
  let reqLevel = mod?.reqLevel ?? 0
  let currency = getModCurrency(mod)
  let cost = getModCost(mod)
  let isLocked = Computed(@() reqLevel > (unit.value?.level ?? 0))
  let isPurchased = Computed(@() unitMods.value?[id] != null)
  let isEquipped = Computed(@() unitMods.value?[id])

  return {
    id
    content = {
      size = [modW, modH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = Picture(image)
          fallbackImage = Picture(defImage)
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_LEFT
          imageValign = ALIGN_BOTTOM
        }

        {
          maxWidth = modW - contentMargin * 2
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = [contentMargin - hdpx(10), contentMargin]
          rendObj = ROBJ_TEXT
          text = loc(locId)
          fontFx = FFT_GLOW
          fontFxFactor = 48
          fontFxColor = 0xFF000000
          behavior = Behaviors.Marquee
          delay = 1
          speed = hdpx(50)
        }.__update(fontSmall)

        mkNotPurchasedShade(isPurchased)
        mkEquippedFrame(isEquipped)
        mkEquippedIcon(isEquipped)
        mkLevelLock(isLocked, reqLevel)
        @() {
          watch = [isPurchased, isLocked]
          children = isPurchased.value || isLocked.value ? null : mkCurrencyComp(cost, currency)
        }
      ]
    }
  }
}

let function mkMod(id, content) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curModId.value == id || (stateFlags.value & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.value & S_HOVER)

  return {
    size = [SIZE_TO_CONTENT, flex()]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = @() curModId(id)
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    gap = selLineGap

    children = [
      mkModContent(content, isActive, isHover)
      selectedLine(isActive)
    ]
  }
}

let mkMods = @(modsSorted) {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = modsGap
  children = modsSorted
    .map(@(v) modData(v))
    .map(@(mod) mkMod(mod.id, mod.content))
}

return {
  mkMods
  modH
  modW
  modsGap
  modTotalH
}
