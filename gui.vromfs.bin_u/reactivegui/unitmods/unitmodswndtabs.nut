from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/config/modsPresentation.nut" as getCatIcon
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_SMALL
from "%rGui/components/tabs.nut" import mkTabs, tabExtraWidth
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/unitMods/modsComps.nut" import mkLevelLock, bgShade
from "%rGui/unitMods/unitModsConst.nut" import tabW, tabH, tabContentMargin, tabsOvr
from "%rGui/unitMods/unitModsState.nut" import mods, unitMods, modsByCategory, unit, curModCategoryId,
  unseenModsByCategory, onModTabChange, modsSort, getModCost, curUnitModCostCfg, isOwn


const defImage = "ui/gameuiskin#upgrades_tools_icon.avif:0:P"

let tabContentW = tabW - tabExtraWidth
const iconSize = hdpxi(60)

let mkCatIcon = @(cat) {
  size = const [iconSize, iconSize]
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
  let isDisplayedAsPurchased = Computed(@() unit.get()?.isPremium || unit.get()?.isUpgraded)
  let isLocked = Computed(@() reqLevel.get() > (unit.get()?.level ?? 0) && !isDisplayedAsPurchased.get())
  let hasInactiveMod = Computed(@() !activeModName.get() && purchasedModName.get() != null)

  let cost = Computed(@() getModCost(tabMod.get(), curUnitModCostCfg.get()))

  let hasModNotOwn = Computed(@() !isLocked.get() && !isOwn.get() && cost.get().price == 0)
  let isPurchased = Computed(@() isDisplayedAsPurchased.get() || unitMods.get()?[tabModName.get()] != null)

  return {
    id
    content = {
      size = [FLEX, tabH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        @() {
          watch = tabModName
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = tabModName.get() == null ? null : Picture($"ui/gameuiskin/{tabModName.get()}.avif:0:P")
          fallbackImage = Picture(defImage)
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_LEFT
          imageValign = ALIGN_BOTTOM
        }

        {
          maxWidth = tabContentW - tabContentMargin[1] * 2
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = tabContentMargin
          rendObj = ROBJ_TEXT
          text = loc(locId)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontVeryTinyAccentedShaded)

        mkCatIcon(id)

        @() {
          watch = [isLocked, hasModNotOwn, isPurchased, cost]
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            !isPurchased.get() && !hasModNotOwn.get() ? bgShade : null
            isLocked.get() || hasModNotOwn.get() || isPurchased.get() ? null
              : mkCurrencyComp(cost.get().price, cost.get().currencyId, CS_SMALL)
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
          margin = tabContentMargin
        }.__update(fontTinyAccented)

        @() {
          watch = [unseenModsByCategory, curModCategoryId]
          hplace = ALIGN_LEFT
          vplace = ALIGN_TOP
          margin = hdpx(20)
          children = (unseenModsByCategory.get()?[id].len() ?? 0) > 0 && curModCategoryId.get() != id ? priorityUnseenMark : null
        }
      ]
    }.__update(ovr)
  }
}

return {
  mkModsCategories = @(tabs, curTabId) mkTabs(tabs.map(@(t) tabData(t)), curTabId, tabsOvr, onModTabChange)
}
