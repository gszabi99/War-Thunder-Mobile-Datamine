from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { deferOnce } = require("dagor.workcycle")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { modsInProgress, buy_unit_mod, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { mkGamercardUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { unitModSlotsOpenCount, closeUnitModsSlotsWnd, curUnit, weaponSlots, curSlotIdx, curWeapons,
  curWeaponIdx, curWeapon, equippedWeaponsBySlots, equippedWeaponId, setCurSlotIdx, setCurBeltsWeaponIdx,
  curWeaponMod, curWeaponModName, curWeaponReqLevel, curWeaponIsLocked, curWeaponIsPurchased,
  unequipCurWeapon, unequipCurWeaponFromWings, curUnitAllModsSlotsCost, beltWeapons, curBeltsWeaponIdx, isOwn, getConflictsList,
  curWeaponBeltsOrdered, curBeltIdx, curBelt, equippedBeltId, equipCurBelt, getEquippedBelt, curUnseenMods,
  chosenBelts, mkWeaponBelts, equippedWeaponIdCount, curBeltWeapon, overloadInfo, fixCurPresetOverload,
  isUnitModSlotsAttached, equipBelt, equipWeaponList, equipWeaponListWithMirrors, mirrorIdx,
  isEmptyBomber, setDefaultSecondaryWeapon
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { loadUnitWeaponSlots, mustSlotHaveDefault } = require("%rGui/weaponry/loadUnitBullets.nut")
let { equipCurWeaponMsg, customEquipCurWeaponMsg } = require("%rGui/unitMods/equipSlotWeaponMsgBox.nut")
let { getModCurrency, getModCost } = require("%rGui/unitMods/unitModsState.nut")
let { getWeaponShortNameWithCount, getBulletBeltShortName, getWeaponShortNamesList
} = require("%rGui/weaponry/weaponsVisual.nut")
let { mkSlotWeapon, mkWeaponImage, mkWeaponDesc, mkEmptyText, weaponTotalH, weaponGap,
  mkSlotText, mkBeltImage, mkSlotBelt, mkConflictsBorder, eqIconSize
} = require("%rGui/unitMods/slotWeaponCard.nut")
let { mkBeltDesc, mkSlotWeaponDesc } = require("%rGui/unitMods/unitModsSlotsDesc.nut")
let { textButtonPrimary, textButtonCommon, textButtonPurchase, iconButtonCommon
} = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { tabsGap, bgColor, tabExtraWidth, mkTabs } = require("%rGui/components/tabs.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { openUnitWeaponPresetWnd } = require("%rGui/unit/unitWeaponPresetsWnd.nut")
let { PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { userlogTextColor, badTextColor2, commonTextColor } = require("%rGui/style/stdColors.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY } = require("%rGui/style/gradients.nut")
let buyUnitLevelWnd = require("%rGui/attributes/unitAttr/buyUnitLevelWnd.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkUnseenModIndicator, mkVerticalPannableArea, verticalGradientLine,
  mkCarouselPannableArea, mkLevelUpRewardBtnChildren, catsPanelBg
} = require("%rGui/unitMods/modsComps.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")
let { carouselScrollHandler } = require("%rGui/unitMods/unitModsScroll.nut")
let { blocksLineSize, blocksPadding, blocksGap, tabW, tabH, contentGamercardGap, slotsBlockMargin, catsBlockHeight
} = require("%rGui/unitMods/unitModsConst.nut")


let slotPadding = [hdpx(10), hdpx(30)]
let headerHeight = hdpx(70)
let headerHeightWithGap = headerHeight + tabsGap
let weaponHWithGap = tabH + tabsGap
let maxSlotsNoScroll = ((catsBlockHeight - tabsGap - 2 * headerHeightWithGap) / weaponHWithGap).tointeger()
let descWidth = hdpx(600)
let maxOverloadInfoWidth = min(hdpx(1650), saSize[0] - descWidth - tabW - tabExtraWidth - 4 * panelBg.padding - 2 * blocksGap - blocksLineSize)

let vertIndent = hdpx(100)
let vertIndentThroughHeader = vertIndent + headerHeight / 2

let pageWidth = saSize[0] + saBorders[0] - tabW - blocksLineSize - blocksGap
let pageScrollXMiddle = blocksGap / pageWidth
let pageScrollYMiddle = slotsBlockMargin / catsBlockHeight
let pageMaskX = mkBitmapPictureLazy((pageWidth / 10).tointeger(), 2, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF, pageScrollXMiddle))
let pageMaskY = mkBitmapPictureLazy(2, (catsBlockHeight / 10).tointeger(), mkGradientCtorDoubleSideY(0, 0xFFFFFFFF, pageScrollYMiddle))

let slotsScrollHandler = ScrollHandler()

function actionWithChecking(actionFn) {
  let { overloads = [] } = overloadInfo.get()
  if (overloads.len() != 0)
    return openMsgBox({
      text = loc("weapons/pilonsRemoveWarning", {
        warnings = colorize(badTextColor2, "\n".join(overloads))
      })
      buttons = [
        { text = loc("btn/autoRemovePilons"),
          function cb() {
            fixCurPresetOverload()
            actionFn()
          },
          multiLine = true
        }
        { text = loc("btn/fixItMyself"), styleId = "PRIMARY", isCancel = true, multiLine = true }
      ]
    })

  if (isEmptyBomber.get())
    return openMsgBox({
      text = loc("weapons/secondaryWeaponNotSet")
      buttons = [
        { text = loc("btn/doNotSet"),
          function cb() {
            actionFn()
          },
          isCancel = true
          multiLine = true
        }
        {
          text = loc("btn/setDefault"),
          function cb() {
            setDefaultSecondaryWeapon()
            actionFn()
          }
          styleId = "PRIMARY",
          multiLine = true }
      ]
    })

  actionFn()
}

registerHandler("onPurchasedMod", function equipOnPurchase(_, context) {
  let { belt, weapon, unitName } = context
  if (unitName != curUnit.get()?.name) 
    return
  if (belt)
    equipBelt(belt.weaponId, belt.id)
  if (weapon){
    let { mirror = -1 } = loadUnitWeaponSlots(unitName)[weapon.slotIdx]
    let weaponList = { [weapon.slotIdx] = weapon.weapon.name }
    if (mirror != -1)
      weaponList.__update({ [mirror] = weapon.weapon?.mirrorId ?? weapon.weapon.name })
    customEquipCurWeaponMsg(weapon.slotIdx, weapon.weapon,
      equippedWeaponsBySlots.get(), @() equipWeaponList(weaponList), @(list) equipWeaponListWithMirrors(list, unitName))
  }
})

function scrollToWeapon() {
  let idx = curWeaponBeltsOrdered.get().len() > 0 ? curBeltIdx.get() : curWeaponIdx.get()
  let { elem } = carouselScrollHandler
  if (elem != null)
    carouselScrollHandler.scrollToX(idx * (tabW + weaponGap) - (elem.getWidth() - tabW) / 2)
}

function scrollToSlot() {
  let beltIdx = curBeltsWeaponIdx.get()
  let isBeltActive = beltIdx >= 0

  let idx = isBeltActive ? beltIdx : curSlotIdx.get()
  if (idx == null)
    return
  let { elem } = slotsScrollHandler
  if (elem == null)
    return

  let beltWeaponTypes = beltWeapons.get().reduce(function(acc, weapon, index) {
    if (weapon.turrets != 0)
      acc.turrets.append(index)
    else
      acc.course.append(index)
    return acc
  }, { turrets = [], course = [] })
  let beltWeaponsCount = beltWeapons.get().len()
  let beltWeaponTypesCount = beltWeaponTypes.filter(@(v) v.len() > 0).len()

  local isFirstAfterHeader = curSlotIdx.get() == 1
  local top = 0

  if (!isBeltActive) {
    let baseOffset = (beltWeaponTypesCount + 1) * headerHeightWithGap
    top = (beltWeaponsCount + idx - 1) * weaponHWithGap + baseOffset
  } else {
    let headersCount = beltWeaponTypes.filter(@(v) v.findindex(@(index) index <= beltIdx) != null).len()
    top = idx * weaponHWithGap + headersCount * headerHeightWithGap
    isFirstAfterHeader = beltWeaponTypes.filter(@(v) v.findindex(@(index) index == beltIdx) == 0).len() > 0
  }

  let ident = isFirstAfterHeader ? vertIndentThroughHeader : vertIndent
  if (top - ident < elem.getScrollOffsY())
    slotsScrollHandler.scrollToY(top - ident)
  else if (top + tabH + ident > elem.getScrollOffsY() + elem.getHeight())
    slotsScrollHandler.scrollToY(top + tabH + ident - elem.getHeight())
}

curSlotIdx.subscribe(function(_) {
  deferOnce(scrollToWeapon)
  deferOnce(scrollToSlot)
})

curBeltsWeaponIdx.subscribe(function(_) {
  deferOnce(scrollToWeapon)
  deferOnce(scrollToSlot)
})

let mkIsSelWeaponConflict = @(slotIdx, weapon)
  Computed(@() curWeapon.get()?.banPresets[slotIdx][weapon.get()?.name] ?? false)

function mkSlotContent(idx) {
  let weapon = Computed(@() equippedWeaponsBySlots.get()?[idx])
  let isUnseen = Computed(@() curUnseenMods.get()?[idx]
    .findindex(@(_, mod) mod in (weaponSlots.get()?[idx].wPresets ?? {})) != null)

  return {
    size = [flex(), tabH]
    children = [
      mkWeaponImage(weapon)
      mkWeaponDesc(weapon)
      mkEmptyText(weapon)
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        margin = slotPadding
        rendObj = ROBJ_TEXT
        text = $"#{idx}"
        color = 0xFFC0C0C0
      }.__update(fontVeryTinyAccentedShaded)
      mkConflictsBorder(mkIsSelWeaponConflict(idx, weapon))
      mkUnseenModIndicator(isUnseen)
    ]
  }
}

let slotsKey = {}
let slotsList = @(slots) {
  key = slotsKey
  size = FLEX_H
  onAttach = scrollToSlot
  children = mkTabs(
    slots.slice(1) 
      .map(@(_, idx) { id = idx + 1, content = mkSlotContent(idx + 1) }),
    curSlotIdx, {}, setCurSlotIdx)
}

function mkBeltSlotContent(weapon, idx) {
  let beltId = Computed(@()
    getEquippedBelt(chosenBelts.get(), weapon.weaponId,
        mkWeaponBelts(curUnit.get()?.name, weapon),
        curUnit.get()?.mods)
      ?.id)
  let gunCount = Computed(@() equippedWeaponIdCount.get()?[weapon.weaponId] ?? 0)
  let isUnseen = Computed(@() curUnseenMods.get()?[idx]
    .findindex(@(_, mod) mod in (beltWeapons.get()?[idx].bulletSets ?? {})) != null)
  return @() {
    watch = [beltId, gunCount, isUnseen]
    size = [flex(), tabH]
    opacity = gunCount.get() == 0 ? 0.5 : 1.0
    children = beltId.get() == null ? null
      : [
          mkBeltImage(weapon.bulletSets?[beltId.get()].bullets ?? [])
          mkSlotText(getWeaponShortNameWithCount(weapon.__merge({ count = gunCount.get() })))
          mkSlotText(getBulletBeltShortName(beltId.get()), { vplace = ALIGN_BOTTOM, halign = ALIGN_LEFT })
          mkUnseenModIndicator(isUnseen)
        ]
  }
}

function beltsList(weapons, filter) {
  let list = weapons
    .map(@(w, idx) filter(w) ? { id = idx, content = mkBeltSlotContent(w, idx) } : null)
    .filter(@(v) v != null)
  if (list.len() == 0)
    return null
  return {
    size = FLEX_H
    children = mkTabs(list, curBeltsWeaponIdx, {}, setCurBeltsWeaponIdx)
  }
}

let mkBlock = @(text, child) child == null ? null
  : {
      size = [tabW, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = tabsGap
      children = [
        {
          margin = [0, 0, 0, tabExtraWidth]
          size = [tabW - tabExtraWidth, headerHeight]
          padding = hdpx(10)
          rendObj = ROBJ_SOLID
          color = bgColor
          valign = ALIGN_CENTER
          children = {
            size = FLEX_H
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text
            color = 0xFFA0A0A0
          }.__update(fontTinyShaded)
        }
        child
      ]
    }

function slotsBlock() {
  let children = [
    mkBlock(loc("weaponry/courseGunBelts"), beltsList(beltWeapons.get(), @(w) w.turrets == 0))
    mkBlock(loc("weaponry/turretGunBelts"), beltsList(beltWeapons.get(), @(w) w.turrets != 0))
    weaponSlots.get().len() <= 1 ? null 
      : mkBlock(loc("weaponry/secondaryWeapons"), slotsList(weaponSlots.get()))
  ]
    .filter(@(v) v != null)
  let cardsCount = weaponSlots.get().len() - 1 + beltWeapons.get().len()
  return catsPanelBg.__merge({
    watch = [beltWeapons, weaponSlots]
    size = [saBorders[0] + tabW + blocksPadding, flex()]
    padding = [0, blocksPadding, 0, 0]
    margin = [contentGamercardGap, 0, 0, 0]
    halign = ALIGN_RIGHT
    children = cardsCount > maxSlotsNoScroll ? mkVerticalPannableArea(children, tabW, pageMaskY())
      : {
          size = flex()
          padding = [slotsBlockMargin, 0, 0, 0]
          flow = FLOW_VERTICAL
          gap = tabsGap
          halign = ALIGN_RIGHT
          children
        }
  })
}

let notUsedCurGunInfo = panelBg.__merge({
  vplace = ALIGN_BOTTOM
  children = @() {
    watch = curBeltWeapon
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = curBeltWeapon.get() == null ? ""
      : "\n".concat(
          getWeaponShortNameWithCount(curBeltWeapon.get().__merge({ count = 0 })),
          loc("weaponry/hint/needToInstallSecondaryGun")
        )
     color = commonTextColor
  }.__update(fontVeryTinyAccentedShaded)
})

let weaponsCount = Computed(@() curWeapons.get().len())
let beltsCount = Computed(@() curWeaponBeltsOrdered.get().len())
let curBeltGunCount = Computed(@() curBeltWeapon.get() == null ? -1
  : equippedWeaponIdCount.get()?[curBeltWeapon.get().weaponId] ?? 0)
let slotWeaponsBlock = @() {
  watch = [weaponsCount, beltsCount, curBeltGunCount]
  size = FLEX_V
  flow = curBeltGunCount.get() == 0 ? null : FLOW_HORIZONTAL
  gap = weaponGap
  children = curBeltGunCount.get() == 0 ? notUsedCurGunInfo
    : beltsCount.get() > 0
      ? array(beltsCount.get())
        .map(@(_, idx) mkSlotBelt(idx, scrollToWeapon))
    : array(weaponsCount.get())
        .map(@(_, idx) mkSlotWeapon(idx, scrollToWeapon))
}

function slotPresetInfo() {
  let watch = [curWeapon, curBelt, equippedWeaponsBySlots]
  if (curWeapon.get() == null && curBelt.get() == null)
    return { watch }
  return panelBg.__merge({
    watch
    hplace = ALIGN_RIGHT
    children = curBelt.get() != null ? mkBeltDesc(curBelt.get(), descWidth)
      : mkSlotWeaponDesc(curWeapon.get(), descWidth, getConflictsList(curWeapon.get(), equippedWeaponsBySlots.get()))
  })
}

function overloadInfoBlock() {
  let { massInfo = "", overloads = [] } = overloadInfo.get()
  if (massInfo == "" && overloads.len() == 0)
    return { watch = overloadInfo }
  local overText = overloads.len() == 0 ? ""
    : colorize(badTextColor2, "\n".join(overloads))
  return panelBg.__merge({
    watch = overloadInfo
    children = {
      maxWidth = maxOverloadInfoWidth
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = commonTextColor
      text = "\n".join([massInfo, overText], true)
    }.__update(fontVeryTinyAccentedShaded)
  })
}

let spinner = {
  size = [defButtonMinWidth, defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkSpinner
}

function onPurchaseMod() {
  let unitName = curUnit.get()?.name
  let mod = curWeaponMod.get()
  let modName = curWeaponModName.get()
  if (unitName == null || mod == null || modName == null)
    return
  let price = getModCost(mod, curUnitAllModsSlotsCost.get())
  let currencyId = getModCurrency(mod)
  let weaponName = curBelt.get() != null
    ? getBulletBeltShortName(curBelt.get().id)
    : comma.join(getWeaponShortNamesList(curWeapon.get()?.weapons ?? []))
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, weaponName) }),
    price = { price, currencyId },
    purchase = @() buy_unit_mod(unitName, modName, currencyId, price,
      {
        id = "onPurchasedMod",
        weapon = curWeapon.get() != null && equippedWeaponId.get() != curWeapon.get().name
          ? {
              slotIdx = curSlotIdx.get()
              weapon = curWeapon.get()
            }
          : null,
        belt = curBelt.get() != null && equippedBeltId.get() != curBelt.get().id
          ? {
              weaponId = curBeltWeapon.get().weaponId
              id = curBelt.get()?.id ?? ""
            }
          : null
        unitName
      }),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, $"{unitName} {modName}")
  })
}

let isNotAvailableForUse = Computed(@() !isOwn.get() || (curWeapon.get() == null && curBelt.get() == null))
let hasUnseenRewards = Computed(@() curUnit.get()?.name in unseenUnitLvlRewardsList.get())

let slotPresetButtons = @() {
  watch = [isNotAvailableForUse, curWeapon, curBelt, modsInProgress, curWeaponIsLocked, curWeaponReqLevel,
    equippedWeaponId, curWeapons, equippedBeltId, curUnit, isGamepad, hasUnseenRewards, curSlotIdx]
  size = FLEX_H
  halign = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    isNotAvailableForUse.get() || !hasUnseenRewards.get() ? null
      : { children = mkLevelUpRewardBtnChildren(curUnit.get()) }
    isNotAvailableForUse.get() ? null
      : modsInProgress.get() != null ? spinner
      : iconButtonCommon("ui/gameuiskin#icon_weapon_preset.svg",
        @() actionWithChecking(@() openUnitWeaponPresetWnd(curUnit.get())),
        { ovr = { size = isGamepad.get() ? [defButtonHeight*2, defButtonHeight] : [defButtonHeight, defButtonHeight], minWidth = defButtonHeight },
        hotkeys = ["^J:X | Enter"]
      })
    isNotAvailableForUse.get() ? null
      : modsInProgress.get() != null ? spinner
      : curWeaponIsLocked.get() && curWeaponReqLevel.get() > 0
        ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), curWeaponReqLevel.get(),
          @() curUnit.get() != null ? buyUnitLevelWnd(curUnit.get().name) : null, { hotkeys = ["^J:Y"] }.__merge({textOvr = fontTinyShadedBold}))
      : curWeaponIsLocked.get() ? null
      : !curWeaponIsPurchased.get()
        ? textButtonPurchase(utf8ToUpper(loc("mainmenu/btnBuy")), onPurchaseMod, { ovr = { key = "arsenal_purchase_btn" }, hotkeys = ["^J:Y"] })
      : curWeapon.get() != null && equippedWeaponId.get() != curWeapon.get().name
        ? textButtonPrimary(utf8ToUpper(loc($"mod/enable{mirrorIdx.get() != -1 ? "/both_wings" : ""}")), equipCurWeaponMsg)
      : curWeapon.get() != null && !mustSlotHaveDefault(curUnit.get()?.name, curSlotIdx.get())
        ? textButtonCommon(utf8ToUpper(loc($"mod/disable{mirrorIdx.get() != -1 ? "/both_wings" : ""}")), mirrorIdx.get() != -1 ? unequipCurWeaponFromWings : unequipCurWeapon)
      : curBelt.get() != null && equippedBeltId.get() != curBelt.get().id
        ? textButtonPrimary(utf8ToUpper(loc("mod/enable")), equipCurBelt)
      : null
  ]
}

let unitModsWnd = {
  key = {}
  size = flex()
  padding = [saBordersRv[0], 0, 0, 0]
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  onAttach = @() isUnitModSlotsAttached.set(true)
  onDetach = @() isUnitModSlotsAttached.set(false)
  children = [
    @() {
      watch = curCampaign
      padding = [0, 0, 0, saBorders[0]]
      children = mkGamercardUnitCampaign(@() actionWithChecking(closeUnitModsSlotsWnd),
        getCampaignPresentation(curCampaign.get()).levelUnitModLocId,
        curUnit)
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      children = [
        slotsBlock
        verticalGradientLine
        @() {
          size = flex()
          flow = FLOW_VERTICAL
          padding = [0, 0, saBorders[1] - eqIconSize[1] / 2, 0]
          halign = ALIGN_RIGHT
          children = [
            {
              size = flex()
              padding = [contentGamercardGap, saBorders[0], contentGamercardGap, blocksGap]
              children = [
                overloadInfoBlock
                slotPresetInfo
                slotPresetButtons
              ]
            }
            mkCarouselPannableArea(slotWeaponsBlock, weaponTotalH, pageMaskX())
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitModsSlotsWnd", unitModsWnd, closeUnitModsSlotsWnd, unitModSlotsOpenCount)
