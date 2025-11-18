from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { unit, unitMods, curModId, getModCurrency, mkCurUnitModCostComp, iconCfg, isOwn, slotModKey
} = require("%rGui/unitMods/unitModsState.nut")
let { unseenCampUnitMods, markUnitModsSeen } = require("%rGui/unitMods/unseenMods.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkLevelLock, mkNotPurchasedShade, mkModImage, mkEquippedFrame, mkUnseenModIndicator
} = require("%rGui/unitMods/modsComps.nut")
let { startCarouselAnimScroll, carouselScrollHandler, getCarouselPosX } = require("%rGui/unitMods/unitModsScroll.nut")
let { modH, modW, modsGap, activeColor } = require("%rGui/unitMods/unitModsConst.nut")
let { selectedLineHorSolid, opacityTransition } = require("%rGui/components/selectedLine.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")


let bgColor = 0x990C1113
let contentMargin = [hdpx(10), hdpx(15)]

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeColor, 0, gradTexSize / 8, gradTexSize / 2.5, gradTexSize / 2, gradTexSize / 4))

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
      opacity = isActive.get() ? 1
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

let mkIcon = @(icon, size) {
  size = flex()
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#{icon}:{size[0]}:{size[1]}:P")
}

let mkEquippedIcon = @(isEquipped) @() !isEquipped.get() ? { watch = isEquipped }
  : {
      watch = [iconCfg, isEquipped]
      pos = [0, iconCfg.get().size[1] / 2]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      size = iconCfg.get().size
      children = [
        mkIcon(iconCfg.get().imgOutline, iconCfg.get().size)
        mkIcon(iconCfg.get().img, iconCfg.get().size).__update({ color = 0xFF000000 })
      ]
    }

function mkModContentData(mod, idx) {
  let stateFlags = Watched(0)
  let id = mod?.name
  let locId = $"modification/{id}"
  let reqLevel = mod?.reqLevel ?? 0
  let currency = getModCurrency(mod)
  let cost = mkCurUnitModCostComp(mod)
  let isDisplayedAsPurchased = Computed(@() unit.get()?.isPremium || unit.get()?.isUpgraded)
  let isLocked = Computed(@() reqLevel > (unit.get()?.level ?? 0) && !isDisplayedAsPurchased.get())
  let hasModNotOwn = Computed(@() !isLocked.get() && !isOwn.get() && cost.get() == 0)
  let isPurchased = Computed(@() isDisplayedAsPurchased.get() || unitMods.get()?[id] != null)
  let isEquipped = Computed(@() unitMods.get()?[id])
  let isActive = Computed(@() curModId.get() == id || (stateFlags.get() & S_ACTIVE) != 0)
  let textSize = calc_str_box(loc(locId), fontVeryTinyAccentedShaded)[0]

  return {
    id
    stateFlags
    content = {
      key = slotModKey(idx)
      size = [modW, modH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        mkModImage(mod)
        {
          maxWidth = textSize + contentMargin[1] * 2 > modW ? modW - contentMargin[1] * 2 : null
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = contentMargin
          rendObj = ROBJ_TEXT
          text = loc(locId)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontVeryTinyAccentedShaded)

        mkNotPurchasedShade(Computed(@() isPurchased.get() || hasModNotOwn.get()))
        mkEquippedFrame(isEquipped, isActive)
        mkEquippedIcon(isEquipped)
        @() {
          watch = isLocked
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = isLocked.get() ? mkLevelLock(reqLevel) : null
        }
        @() {
          watch = [isPurchased, isLocked, hasModNotOwn, cost]
          children = isPurchased.get() || isLocked.get() || hasModNotOwn.get() ? null : mkCurrencyComp(cost.get(), currency, CS_SMALL)
        }
        mkUnseenModIndicator(Computed(@() id in unseenCampUnitMods.get()?[unit.get()?.name]))
      ]
    }
  }
}

function mkMod(id, content, stateFlags, idx) {
  let isActive = Computed(@() curModId.get() == id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)

  return {
    key = isActive
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    function onClick() {
      markUnitModsSeen(unit.get()?.name, [id])
      curModId.set(id)
      startCarouselAnimScroll(getCarouselPosX(idx))
    }
    onAttach = @() isActive.get() ? carouselScrollHandler.scrollToX(getCarouselPosX(idx)) : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      selectedLineHorSolid(isActive)
      mkModContent(content, isActive, isHover)
    ]
  }
}

let mkMods = @(modsSorted) {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap = modsGap
  children = modsSorted
    .map(function(mod, idx) {
       let { id, content, stateFlags } = mkModContentData(mod, idx)
       return mkMod(id, content, stateFlags, idx)
    })
}

return {
  mkMods

  contentMargin
  bgColor
  bgGradient

  mkEquippedIcon
}
