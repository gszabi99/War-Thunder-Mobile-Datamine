from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/bulletsPresentation.nut" import getBulletImage, getBulletTypeIcon
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS
from "%rGui/bullets/bulletsSlotComps.nut" import mkBulletSlider
from "%rGui/components/selectedLine.nut" import opacityTransition
from "%rGui/components/slider.nut" import sliderValueSound
from "%rGui/components/tabs.nut" import mkTabs, tabExtraWidth
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/style/stdColors.nut" import tabBgColor
from "%rGui/unitMods/modsComps.nut" import mkBulletTypeIcon
from "%rGui/unitMods/unitBulletsState.nut" import onBulletTabChange, setCurUnitBullets
from "%rGui/unitMods/unitModsConst.nut" import tabH, tabW, tabContentMargin, knobSize, knobGap, tabsOvr
from "%rGui/unitMods/unitModsState.nut" import curBulletCategoryId, unitName
from "%rGui/unitMods/unseenBullets.nut" import mkUnseenUnitBullets
from "%rGui/weaponry/weaponsVisual.nut" import getAmmoTypeShortText, getAmmoNameShortText


let tabContentW = tabW - tabExtraWidth

let slotNumberText = @(slotNumber) slotNumber == null ? "" : "".concat(loc("icon/mpstats/rowNo"), (slotNumber + 1))

function tabData(tab, ovr = {}) {
  let { id, visIdx = null, bSlot, bInfo, bSet, bTotalSteps, bStep, maxBullets, withExtraBullets, bLeftSteps, isOwn } = tab
  let { count = 0, name = null } = bSlot
  let { bulletSetAvailiable = [], fromUnitTags = null } = bInfo
  let { image = null, icon = null, maxCount = null } = fromUnitTags?[name]

  let imageBulletName = getBulletImage(image, bSet?.bullets ?? [])
  let ammoTypeName = getAmmoTypeShortText(bSet?.bullets[0] ?? "")
  let iconBulletType = getBulletTypeIcon(icon, bSet)

  let bStepWithBSetAvail = Computed(@() bulletSetAvailiable.len() == 0 ? bStep.get() : (bStep.get() / bulletSetAvailiable.len()))
  let realMaxCount = min(bTotalSteps, maxCount ?? bTotalSteps)
  let maxCountByStep = Computed(@() realMaxCount * bStepWithBSetAvail.get())

  let unitValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : bStepWithBSetAvail.get())
  let maxValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : maxCountByStep.get())
  let countText = Computed(@() $"{min(count, maxValue.get())}/{maxValue.get()}")

  let unseenUnitBullets = mkUnseenUnitBullets(unitName)
  let isPrimaryBullet = id < BULLETS_PRIM_SLOTS

  function onChange(value) {
    if (bSlot == null)
      return
    let newVal = clamp(value, 0, !withExtraBullets.get()
      ? min(count + bLeftSteps.get() * bStepWithBSetAvail.get(), maxCountByStep.get())
      : maxBullets.get())
    if (newVal == count)
      return
    sliderValueSound()
    setCurUnitBullets(id, name, newVal)
  }

  return {
    id
    content = {
      size = [FLEX, tabH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture($"{imageBulletName}:0:P")
          keepAspect = true
          imageHalign = ALIGN_CENTER
          imageValign = ALIGN_CENTER
        }
        {
          maxWidth = tabContentW - tabContentMargin[1] * 2
          margin = tabContentMargin
          vplace = ALIGN_TOP
          hplace = ALIGN_LEFT
          rendObj = ROBJ_TEXT
          text = getAmmoNameShortText(bSet)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontVeryTinyAccentedShaded)
        {
          margin = tabContentMargin
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_LEFT
          rendObj = ROBJ_TEXT
          text = slotNumberText(visIdx ?? id)
        }.__update(fontVeryTinyAccentedShaded)
        @() {
          watch = countText
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          text = countText.get()
        }.__update(fontVeryTinyShaded)

        function() {
          let { primary, secondary } = unseenUnitBullets.get()
          let hasUnseenMark = isPrimaryBullet ? (primary.len() > 0) : (secondary.len() > 0)
          return {
            watch = [unseenUnitBullets, curBulletCategoryId, unitName]
            hplace = ALIGN_LEFT
            vplace = ALIGN_TOP
            margin = hdpx(20)
            children = hasUnseenMark && curBulletCategoryId.get() != id ? priorityUnseenMark : null
          }
        }
        mkBulletTypeIcon(iconBulletType, ammoTypeName)
      ]
    }.__update(ovr)
    extraContent = !isOwn || bTotalSteps <= 1 ? null
      : {
          size = FLEX_H

          padding = [knobGap, 0]
          margin = [0, 0, 0, tabExtraWidth]
          rendObj = ROBJ_SOLID
          color = tabBgColor
          transitions = opacityTransition

          children = mkBulletSlider(
            [tabContentW, knobSize],
            Watched(count),
            unitValue,
            maxValue,
            onChange)
        }
  }
}

return {
  mkBulletsTabs = @(tabs, curTabId) mkTabs(tabs.map(@(t) tabData(t)), curTabId, tabsOvr, onBulletTabChange)
}
