from "%globalsDarg/darg_library.nut" import *
let { getBulletImage, getBulletTypeIcon } = require("%appGlobals/config/bulletsPresentation.nut")
let { sliderValueSound } = require("%rGui/components/slider.nut")
let { mkTabs, tabExtraWidth } = require("%rGui/components/tabs.nut")
let { opacityTransition } = require("%rGui/components/selectedLine.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkBulletSlider } = require("%rGui/bullets/bulletsSlotComps.nut")
let { BULLETS_PRIM_SLOTS } = require("%rGui/bullets/bulletsConst.nut")
let { onBulletTabChange, setCurUnitBullets } = require("%rGui/unitMods/unitBulletsState.nut")
let { curBulletCategoryId, unitName } = require("%rGui/unitMods/unitModsState.nut")
let { tabH, tabW, tabContentMargin, knobSize, knobGap, tabsOvr } = require("%rGui/unitMods/unitModsConst.nut")
let { mkBulletTypeIcon } = require("%rGui/unitMods/modsComps.nut")
let { mkUnseenUnitBullets } = require("%rGui/unitMods/unseenBullets.nut")
let { getAmmoTypeShortText } = require("%rGui/weaponry/weaponsVisual.nut")


let bgColor = 0x990C1113
let tabContentW = tabW - tabExtraWidth

let slotNumberText = @(slotNumber) slotNumber == null ? "" : "".concat(loc("icon/mpstats/rowNo"), (slotNumber + 1))

function tabData(tab, ovr = {}) {
  let { id, bSlot, bInfo, bSet, bTotalSteps, bStep, maxBullets, withExtraBullets, bLeftSteps, isOwn } = tab
  let { count = 0, name = null } = bSlot
  let { image = null, icon = null, maxCount = null } = bInfo?.fromUnitTags[name]

  let imageBulletName = getBulletImage(image, bSet?.bullets ?? [])
  let ammoTypeName = getAmmoTypeShortText(bSet?.bullets[0] ?? "")
  let iconBulletType = getBulletTypeIcon(icon, bSet)

  let realMaxCount = min(bTotalSteps, maxCount ?? bTotalSteps)
  let maxCountByStep = Computed(@() realMaxCount * bStep.get())

  let unitValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : bStep.get())
  let maxValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : maxCountByStep.get())
  let countText = Computed(@() $"{count}/{maxValue.get()}")

  let unseenUnitBullets = mkUnseenUnitBullets(unitName)
  let isPrimaryBullet = id < BULLETS_PRIM_SLOTS

  function onChange(value) {
    if (bSlot == null)
      return
    let newVal = clamp(value, 0, !withExtraBullets.get()
      ? (count + bLeftSteps.get() * bStep.get())
      : maxBullets.get())
    if (newVal == count)
      return
    sliderValueSound()
    setCurUnitBullets(id, name, newVal)
  }

  return {
    id
    content = {
      size = [flex(), tabH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = Picture($"{imageBulletName}:0:P")
          keepAspect = true
          imageHalign = ALIGN_CENTER
          imageValign = ALIGN_CENTER
        }
        {
          maxWidth = tabContentW - tabContentMargin[1] * 2
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_LEFT
          margin = tabContentMargin
          rendObj = ROBJ_TEXT
          text = slotNumberText(id)
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
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
          color = bgColor
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
