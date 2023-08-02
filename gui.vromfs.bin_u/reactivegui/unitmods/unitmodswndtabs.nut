from "%globalsDarg/darg_library.nut" import *
let { mkTabs, tabExtraWidth } = require("%rGui/components/tabs.nut")
let { mods, unitMods, modsByCategory, unit, curCategoryId } = require("unitModsState.nut")
let getCatIcon = require("%appGlobals/config/modsPresentation.nut")
let { unseenModsByCategory, onTabChange, modsSort, getModCost, curUnitAllModsCost, getModCurrency
} = require("%rGui/unitMods/unitModsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkLevelLock, bgShade } = require("modsComps.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")

let contentMargin = [hdpx(10), hdpx(30)]
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:O:P"

let tabH = hdpx(184)
let tabW = hdpx(460)
let tabContentW = tabW - tabExtraWidth
let iconSize = hdpxi(60)

let mkCatIcon = @(cat) {
  size = [iconSize, iconSize]
  pos = [-contentMargin[1], hdpx(5)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_IMAGE
  image = Picture(getCatIcon(cat))
  keepAspect = KEEP_ASPECT_FILL
}

let function tabData(tab, ovr = {}) {
  let { id = "", locId  = "" } = tab
  let modsSorted = Computed(@() modsByCategory.value?[id].values().sort(modsSort) ?? [])
  let purchasedModName = Computed(@() modsSorted.value.findvalue(@(v) unitMods.value?[v.name] == false)?.name)
  let activeModName = Computed(@() modsSorted.value.findvalue(@(v) unitMods.value?[v.name] == true)?.name)
  let tabModName = Computed(@() activeModName.value ?? purchasedModName.value ?? modsSorted.value?[0]?.name)
  let tabMod = Computed(@() mods.value?[tabModName.value])
  let reqLevel = Computed(@() tabMod.value?.reqLevel ?? 0)
  let isLocked = Computed(@() reqLevel.value > (unit.value?.level ?? 0))
  let isPurchased = Computed(@() unitMods.value?[tabModName.value] != null)
  let hasInactiveMod = Computed(@() !activeModName.value && purchasedModName.value != null)

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
          image = Picture($"ui/gameuiskin#{tabModName.value}.avif:O:P")
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
          delay = 1
          speed = hdpx(50)
        }.__update(fontSmallShaded)

        mkCatIcon(id)

        @() {
          watch = [isLocked, isPurchased, tabMod, curUnitAllModsCost]
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            !isPurchased.value ? bgShade : null
            isLocked.value || isPurchased.value ? null
              : mkCurrencyComp(getModCost(tabMod.value, curUnitAllModsCost.value), getModCurrency(tabMod.value))
          ]
        }

        @() {
          watch = reqLevel
          size = flex()
          padding = hdpx(40)
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = mkLevelLock(isLocked, reqLevel.value)
        }

        @() {
          watch = hasInactiveMod
          rendObj = ROBJ_TEXT
          text = hasInactiveMod.value ? loc("mod/inactive") : null
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          margin = contentMargin
        }.__update(fontSmall)

        @() {
          watch = [unseenModsByCategory, curCategoryId]
          hplace = ALIGN_LEFT
          vplace = ALIGN_TOP
          margin = hdpx(20)
          children = (unseenModsByCategory.value?[id].len() ?? 0) > 0 && curCategoryId.value != id ? priorityUnseenMark : null
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
