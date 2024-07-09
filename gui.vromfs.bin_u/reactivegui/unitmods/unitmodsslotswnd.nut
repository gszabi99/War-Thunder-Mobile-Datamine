from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { deferOnce } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { modsInProgress, buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { mkGamercardUnitCampaign, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { unitModSlotsOpenCount, closeUnitModsSlotsWnd, curUnit, weaponSlots, curSlotIdx, curWeapons,
  curWeaponIdx, curWeapon, getEquippedWeapon, weaponPreset, equippedWeaponId,
  curWeaponMod, curWeaponModName, curWeaponReqLevel, curWeaponIsLocked, curWeaponIsPurchased,
  equipCurWeapon, unequipCurWeapon, curUnitAllModsCost
} = require("unitModsSlotsState.nut")
let { getModCurrency, getModCost } = require("unitModsState.nut")
let { getWeaponNamesList } = require("%rGui/weaponry/weaponsVisual.nut")
let { mkSlotWeapon, mkWeaponImage, mkWeaponDesc, weaponH, weaponW, weaponTotalH, weaponGap
} = require("slotWeaponCard.nut")
let { textButtonPrimary, textButtonPurchase } = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { tabsGap, bgColor, tabExtraWidth, mkTabs } = require("%rGui/components/tabs.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX } = require("%rGui/style/gradients.nut")
let buyUnitLevelWnd = require("%rGui/unitAttr/buyUnitLevelWnd.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let blocksGap = hdpx(60)
let slotW = weaponW + hdpx(20)
let slotPadding = [hdpx(10), hdpx(30)]
let slotsBlockMargin = hdpx(24)
let slotsBlockHeight = saSize[1] - gamercardHeight - slotsBlockMargin
let maxSlotsNoScroll = ((slotsBlockHeight - tabsGap) / (weaponH + tabsGap)).tointeger()

let pageWidth = saSize[0] + saBorders[0] - slotW
let pageMask = mkBitmapPictureLazy((pageWidth / 10).tointeger(), 2, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF, 0.05))

let slotsScrollHandler = ScrollHandler()
let weaponsScrollHandler = ScrollHandler()


function scrollToWeapon() {
  let idx = curWeaponIdx.get()
  if (idx == null)
    return
  let { elem } = weaponsScrollHandler
  if (elem != null)
    weaponsScrollHandler.scrollToX(idx * (weaponW + weaponGap) - (elem.getWidth() - weaponW) / 2)
}

function scrollToSlot() {
  let idx = curSlotIdx.get()
  if (idx == null)
    return
  let { elem } = slotsScrollHandler
  if (elem == null)
    return
  let top = idx * (weaponH + tabsGap)
  if (top < elem.getScrollOffsY())
    slotsScrollHandler.scrollToY(top)
  else if (top + weaponH > elem.getScrollOffsY() + elem.getHeight())
    slotsScrollHandler.scrollToY(top + weaponH - elem.getHeight())
}

curSlotIdx.subscribe(function(_) {
  deferOnce(scrollToWeapon)
  scrollToSlot()
})

let mkVerticalPannableArea = @(content) {
  clipChildren = true
  size = [slotW, flex()]
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    scrollHandler = slotsScrollHandler
    children = content
    xmbNode = {
      canFocus = false
      scrollSpeed = 5.0
      isViewport = true
    }
  }
}

let mkHorizontalPannableArea = @(content) {
  rendObj = ROBJ_MASK
  image = pageMask()
  clipChildren = true
  size = [flex(), weaponTotalH]
  flow = FLOW_HORIZONTAL
  children = [
    { size = [blocksGap, flex()] }
    {
      size = flex()
      padding = [0, saBorders[0], 0, 0]
      behavior = Behaviors.Pannable
      scrollHandler = weaponsScrollHandler
      children = content
      xmbNode = {
        canFocus = false
        scrollSpeed = 2.0
        isViewport = true
        scrollToEdge = false
      }
    }
  ]
}

function mkSlotContent(slot, idx) {
  let weapon = Computed(@() getEquippedWeapon(weaponPreset.get(), idx, slot.wPresets, curUnit.get()?.mods))
  return {
    size = [flex(), weaponH]
    children = [
      mkWeaponImage(weapon)
      mkWeaponDesc(weapon)
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        margin = slotPadding
        rendObj = ROBJ_TEXT
        text = $"#{idx + 1}"
        color = 0xFFC0C0C0
      }.__update(fontSmallShaded)
    ]
  }
}

let slotsKey = {}
let slotsList = @(slots) {
  key = slotsKey
  size = [flex(), SIZE_TO_CONTENT]
  onAttach = scrollToSlot
  children = mkTabs(slots.map(@(s, idx) { id = idx, content = mkSlotContent(s, idx) }),
    curSlotIdx, {}, @(idx) curSlotIdx.set(idx))
}

function slotsBlock() {
  let list = slotsList(weaponSlots.get())
  return {
    watch = weaponSlots
    size = [slotW, flex()]
    margin = [slotsBlockMargin, 0, 0, 0]
    flow = FLOW_VERTICAL
    gap = tabsGap
    children = weaponSlots.get().len() > maxSlotsNoScroll ? mkVerticalPannableArea(list)
      : [
          list
          {
            margin = [0, 0, 0, tabExtraWidth]
            size = [slotW - tabExtraWidth, flex()]
            rendObj = ROBJ_SOLID
            color = bgColor
          }
        ]
  }
}

let weaponsCount = Computed(@() curWeapons.get().len())
let slotWeaponsBlock = @() {
  watch = weaponsCount
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = weaponGap
  children = array(weaponsCount.get())
    .map(@(_, idx) mkSlotWeapon(idx, scrollToWeapon))
}

function slotPresetInfo() {
  if (curWeapon.get() == null)
    return { watch = curWeapon }
  let desc = "\n".join(getWeaponNamesList(curWeapon.get()?.weapons ?? []))
  return {
    watch = curWeapon
    rendObj = ROBJ_IMAGE
    pos = [saBorders[0], 0]
    image = Picture("ui/gameuiskin#debriefing_bg_grad@@ss.avif:0:P")
    color = 0x90090F16
    margin = [0, saBorders[0], 0, 0]
    padding = [hdpx(30), saBorders[0]]
    children = {
      size = [weaponW, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_RIGHT
      text = desc
    }.__update(fontSmall)
  }
}

let spinner = {
  size = [buttonStyles.defButtonMinWidth, buttonStyles.defButtonHeight]
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
  let price = getModCost(mod, curUnitAllModsCost.get())
  let currencyId = getModCurrency(mod)
  let weaponName = comma.join(getWeaponNamesList(curWeapon.get()?.weapons ?? []))
  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, weaponName) }),
    { price, currencyId },
    @() buy_unit_mod(unitName, modName, currencyId, price),
    mkBqPurchaseInfo(PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, $"{unitName} {modName}"))
}

let slotPresetButtons = @() {
  watch = [curWeapon, modsInProgress, curWeaponIsLocked, curWeaponReqLevel, equippedWeaponId, curWeapons]
  size = [flex(), SIZE_TO_CONTENT]
  margin = [hdpx(25), saBorders[0], hdpx(25), 0]
  halign = ALIGN_RIGHT
  children = curWeapon.get() == null ? null
    : modsInProgress.get() != null ? spinner
    : curWeaponIsLocked.get() && curWeaponReqLevel.get() > 0
      ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), curWeaponReqLevel.get(),
        @() curUnit.get() != null ? buyUnitLevelWnd(curUnit.get().name) : null, { hotkeys = ["^J:Y"] })
    : curWeaponIsLocked.get() ? null
    : !curWeaponIsPurchased.get() ? textButtonPurchase(loc("mainmenu/btnBuy"), onPurchaseMod)
    : equippedWeaponId.get() != curWeapon.get().name ? textButtonPrimary(loc("mod/enable"), equipCurWeapon)
    : curWeapons.get().len() > 1 || !curWeapon.get().isDefault ? textButtonPrimary(loc("mod/disable"), unequipCurWeapon)
    : null
}

let unitModsWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = HangarCameraControl
  flow = FLOW_VERTICAL
  children = [
    @(){
      watch = curCampaign
      children = mkGamercardUnitCampaign(closeUnitModsSlotsWnd, $"gamercard/levelUnitMod/desc/{curCampaign.value}")
    }
    {
      size = [saSize[0] + saBorders[0], flex()]
      flow = FLOW_HORIZONTAL
      children = [
        slotsBlock
        {
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            slotPresetInfo
            { size = flex() }
            slotPresetButtons
            mkHorizontalPannableArea(slotWeaponsBlock)
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitModsSlotsWnd", unitModsWnd, closeUnitModsSlotsWnd, unitModSlotsOpenCount)
