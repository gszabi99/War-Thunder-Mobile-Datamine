from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { unit, unitMods, curModId, getModCurrency, mkCurUnitModCostComp } = require("unitModsState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkLevelLock, mkNotPurchasedShade, mkModImage } = require("modsComps.nut")
let { selectedLineHor, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { defer } = require("dagor.workcycle")

let modsGap = hdpx(10)
let selLineGap = hdpx(14)
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let contentMargin = [hdpx(10), hdpx(15)]
let modH = hdpx(170)
let modW = hdpx(440)
let equippedColor = 0xFF50C0FF
let equippedFrameWidth = hdpx(4)
let modTotalH = modH + selLineSize + selLineGap

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

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 8, gradTexSize / 2.5, gradTexSize / 2, gradTexSize / 4))

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
      image = bgGradient()
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

function mkEquippedIcon(isEquipped) {
  let icon = Computed(@() iconsCfg?[unit.value?.unitType] ?? iconsCfg.tank)

  return @() !isEquipped.value ? { watch = [unit, isEquipped] }
    : {
        watch = [unit, isEquipped]
        margin = contentMargin
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        size = icon.value.size
        rendObj = ROBJ_IMAGE
        color = equippedColor
        keepAspect = KEEP_ASPECT_FIT
        image = Picture($"ui/gameuiskin#{icon.value.img}:{icon.value.size[0]}:{icon.value.size[1]}:P")
      }
}

function modData(mod) {
  let id = mod?.name
  let locId = $"modification/{id}"
  let reqLevel = mod?.reqLevel ?? 0
  let currency = getModCurrency(mod)
  let cost = mkCurUnitModCostComp(mod)
  let isLocked = Computed(@() reqLevel > (unit.value?.level ?? 0))
  let isPurchased = Computed(@() unitMods.value?[id] != null)
  let isEquipped = Computed(@() unitMods.value?[id])
  let textSize = calc_str_box(loc(locId), fontSmallShaded)[0]

  return {
    id
    content = {
      size = [modW, modH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        mkModImage(mod)
        {
          maxWidth = textSize > modW ? modW - contentMargin[1] * 2 : null
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = contentMargin
          rendObj = ROBJ_TEXT
          text = loc(locId)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontSmallShaded)

        mkNotPurchasedShade(isPurchased)
        mkEquippedFrame(isEquipped)
        mkEquippedIcon(isEquipped)
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = mkLevelLock(isLocked, reqLevel)
        }
        @() {
          watch = [isPurchased, isLocked, cost]
          children = isPurchased.value || isLocked.value ? null : mkCurrencyComp(cost.value, currency)
        }
      ]
    }
  }
}

function mkMod(id, content, scrollToMod) {
  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isActive = Computed (@() curModId.value == id || (stateFlags.value & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.value & S_HOVER)

  return {
    size = [SIZE_TO_CONTENT, flex()]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    xmbNode
    function onClick() {
      curModId(id)
      defer(@() gui_scene.setXmbFocus(xmbNode))
    }
    onAttach = @() isActive.get() ? scrollToMod() : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    gap = selLineGap

    children = [
      mkModContent(content, isActive, isHover)
      selectedLineHor(isActive)
    ]
  }
}

let mkMods = @(modsSorted, scrollToMod) {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = modsGap
  children = modsSorted
    .map(@(v) modData(v))
    .map(@(mod) mkMod(mod.id, mod.content, scrollToMod))
}

return {
  mkMods
  modH
  modW
  modsGap
  modTotalH
}
