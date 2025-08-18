from "%globalsDarg/darg_library.nut" import *
let { mkTabs, tabExtraWidth } = require("%rGui/components/tabs.nut")
let getCatIcon = require("%appGlobals/config/modsPresentation.nut")
let {
  mods, unitMods, modsByCategory, unit, curCategoryId,
  unseenModsByCategory, onTabChange, modsSort, getModCost, curUnitAllModsCost, getModCurrency
} = require("%rGui/unitMods/unitModsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkLevelLock, bgShade } = require("%rGui/unitMods/modsComps.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")

let contentMargin = [hdpx(10), hdpx(30)]
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:0:P"

let tabH = hdpx(184)
let tabW = hdpx(460)
let tabContentW = tabW - tabExtraWidth
let iconSize = hdpxi(60)

let mkCatIcon = @(cat) {
  size = [iconSize, iconSize]
  margin = hdpx(10)
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  rendObj = ROBJ_IMAGE
  image = Picture(getCatIcon(cat))
  keepAspect = KEEP_ASPECT_FILL
}

function tabData(tab, ovr = {}) {
  let { id = "", locId  = "" } = tab
  let modsSorted = Computed(@() modsByCategory.get()?[id].values().sort(modsSort) ?? [])
  let purchasedModName = Computed(@() modsSorted.get().findvalue(@(v) unitMods.get()?[v.name] == false)?.name)
  let activeModName = Computed(@() modsSorted.get().findvalue(@(v) unitMods.get()?[v.name] == true)?.name)
  let tabModName = Computed(@() activeModName.get() ?? purchasedModName.get() ?? modsSorted.get()?[0]?.name)
  let tabMod = Computed(@() mods.get()?[tabModName.get()])
  let reqLevel = Computed(@() tabMod.get()?.reqLevel ?? 0)
  let isLocked = Computed(@() reqLevel.get() > (unit.get()?.level ?? 0))
  let isPurchased = Computed(@() unitMods.get()?[tabModName.get()] != null)
  let hasInactiveMod = Computed(@() !activeModName.get() && purchasedModName.get() != null)

  return {
    id
    content = {
      size = [tabContentW, tabH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        @() {
          watch = tabModName
          size = flex()
          rendObj = ROBJ_IMAGE
          image = tabModName.get() == null ? null : Picture($"ui/gameuiskin/{tabModName.get()}.avif:0:P")
          fallbackImage = Picture(defImage)
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_LEFT
          imageValign = ALIGN_BOTTOM
        }

        {
          maxWidth = tabContentW - contentMargin[1] * 2
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = contentMargin
          rendObj = ROBJ_TEXT
          text = loc(locId)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontTinyShaded)

        mkCatIcon(id)

        @() {
          watch = [isLocked, isPurchased, tabMod, curUnitAllModsCost]
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            !isPurchased.get() ? bgShade : null
            isLocked.get() || isPurchased.get() ? null
              : mkCurrencyComp(getModCost(tabMod.get(), curUnitAllModsCost.get()), getModCurrency(tabMod.get()))
          ]
        }

        @() {
          watch = [ isLocked, reqLevel]
          hplace  =  ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = isLocked.get() ? mkLevelLock(reqLevel.get()) : null
        }

        @() {
          watch = hasInactiveMod
          rendObj = ROBJ_TEXT
          text = hasInactiveMod.get() ? loc("mod/inactive") : null
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          margin = contentMargin
        }.__update(fontSmall)

        @() {
          watch = [unseenModsByCategory, curCategoryId]
          hplace = ALIGN_LEFT
          vplace = ALIGN_TOP
          margin = hdpx(20)
          children = (unseenModsByCategory.get()?[id].len() ?? 0) > 0 && curCategoryId.get() != id ? priorityUnseenMark : null
        }
      ]
    }.__update(ovr)
  }
}

return {
  mkModsCategories = @(tabs, curTabId) mkTabs(tabs.map(@(t) tabData(t)), curTabId, {}, onTabChange)
  tabH
  tabW
}
