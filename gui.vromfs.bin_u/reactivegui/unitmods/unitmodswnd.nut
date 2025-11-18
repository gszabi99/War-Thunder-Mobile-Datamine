from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { getBulletImage, getBulletTypeIcon } = require("%appGlobals/config/bulletsPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { modsInProgress, buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkGamercardUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { getAmmoNameText, getAmmoTypeText, getAmmoAdviceText, getAmmoTypeShortText, getAmmoNameShortText
} = require("%rGui/weaponry/weaponsVisual.nut")
let getBulletStats = require("%rGui/bullets/bulletStats.nut")
let { mkShellVideo } = require("%rGui/bullets/bulletsSelectorComps.nut")
let { catsHeight } = require("%rGui/unitMods/unitModsScroll.nut")
let { tabW, blocksGap, blocksPadding, blocksLineSize, modW, modH,
  knobSize, catsBlockHeight, contentGamercardGap, slotsBlockMargin
} = require("%rGui/unitMods/unitModsConst.nut")
let { modsCategories, curModCategoryId, curMod, isUnitModsOpen, closeUnitModsWnd,
  modsSorted, unit, enableCurUnitMod, disableCurUnitMod,
  isCurModPurchased, isCurModEnabled, isCurModLocked,
  getModCurrency, getModCost, curUnitAllModsCost, iconCfg, isOwn, isUnitModAttached
} = require("%rGui/unitMods/unitModsState.nut")
let { mkModsCategories } = require("%rGui/unitMods/unitModsWndTabs.nut")
let { mkMods } = require("%rGui/unitMods/unitModsCarousel.nut")
let { curBullet, chosenBullets, chosenBulletsSec, bulletsInfo, bulletsSecInfo, choiceCount,
  bulletTotalSteps, bulletStep, maxBulletsCountForExtraAmmo, hasExtraBullets, bulletLeftSteps,
  bulletSecTotalSteps, bulletSecStep, maxBulletsSecCountForExtraAmmo, hasExtraBulletsSec, bulletSecLeftSteps,
  isCurBulletLocked, isCurBulletEnabled, setOrSwapCurUnitBullet, curBulletCategoryId, visibleBulletsList
} = require("%rGui/unitMods/unitBulletsState.nut")
let { mkBulletsTabs } = require("%rGui/unitMods/unitBulletsWndTabs.nut")
let { mkBullets } = require("%rGui/unitMods/unitBulletsCarousel.nut")
let { mkVerticalPannableArea, mkCarouselPannableArea, verticalGradientLine,
  mkBulletTypeIcon, mkLevelUpRewardBtnChildren, catsPanelBg
} = require("%rGui/unitMods/modsComps.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")
let { selLineSize } = require("%rGui/components/selectedLine.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { textButtonPrimary, textButtonPurchase } = require("%rGui/components/textButton.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { tabsGap, tabExtraWidth } = require("%rGui/components/tabs.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideX, mkGradientCtorDoubleSideY } = require("%rGui/style/gradients.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let buyUnitLevelWnd = require("%rGui/attributes/unitAttr/buyUnitLevelWnd.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")


let iconSizeH = hdpxi(80)
let iconSizeW = iconSizeH * 2.3

let shellVideoWidth = modH * 4
let infoPanelPadding = hdpx(20)
let modsInfoPadding = hdpx(32)
let shellVideoGap = hdpx(10)
let buttonGap = hdpx(25)
let infoPanelHeight = saSize[1] - gamercardHeight - modH - selLineSize - buttonGap * 2 - buttonStyles.defButtonHeight - contentGamercardGap

let pageWidth = saSize[0] + saBorders[0] - tabW - blocksLineSize - blocksGap
let pageScrollXMiddle = blocksGap / pageWidth
let pageScrollYMiddle = contentGamercardGap / catsBlockHeight
let pageMaskX = mkBitmapPictureLazy((pageWidth / 10).tointeger(), 2, mkGradientCtorDoubleSideX(0, 0xFFFFFFFF, pageScrollXMiddle))
let pageMaskY = mkBitmapPictureLazy(2, (catsBlockHeight / 10).tointeger(), mkGradientCtorDoubleSideY(0, 0xFFFFFFFF, pageScrollYMiddle))

let modsInfoPanelWidth = infoPanelPadding * 2 + modsInfoPadding * 2 + iconSizeW + pageWidth * 0.24
let bulletsInfoPanelWidth = infoPanelPadding * 2 + modW + shellVideoWidth + shellVideoGap

let catsWidth = tabW + knobSize - tabExtraWidth

let iconH = Computed(@() iconCfg.get().size[1] / 2)
let modTotalH = Computed(@() modH + selLineSize + iconH.get())
let emptyCatSlotHeight = Computed(@() catsBlockHeight - catsHeight.get() - tabsGap)

function bulletsCategoriesBlock() {
  let allSlots = []
  let bInfoPrim = bulletsInfo.get()
  if (bInfoPrim != null) {
    let bullets = chosenBullets.get()
    let slots = array(bullets.len()).map(function(_, idx) {
      let bSlot = bullets?[idx]
      let bSet = bInfoPrim?.bulletSets[bSlot?.name]
      return {
        id = bullets.findvalue(@(b) b.name == bSet?.id)?.idx ?? idx
        bInfo = bInfoPrim
        bSlot
        bSet
        bTotalSteps = bulletTotalSteps.get()
        bStep = bulletStep
        maxBullets = Computed(@() maxBulletsCountForExtraAmmo.get()?[idx])
        withExtraBullets = hasExtraBullets
        bLeftSteps = bulletLeftSteps
        isOwn = isOwn.get()
      }
    })
    allSlots.extend(slots)
  }
  let bInfoSec = bulletsSecInfo.get()
  if (bInfoSec != null) {
    let bullets = chosenBulletsSec.get()
    let slots = array(bullets.len()).map(function(_, idx) {
      let bSlot = bullets?[idx]
      let bSet = bInfoSec?.bulletSets[bSlot?.name]
      return {
        id = bullets.findvalue(@(b) b.name == bSet?.id)?.idx ?? idx
        bInfo = bInfoSec
        bSlot
        bSet
        bTotalSteps = bulletSecTotalSteps.get()
        bStep = bulletSecStep
        maxBullets = Computed(@() maxBulletsSecCountForExtraAmmo.get()?[idx])
        withExtraBullets = hasExtraBulletsSec
        bLeftSteps = bulletSecLeftSteps
        isOwn = isOwn.get()
      }
    })
    allSlots.extend(slots)
  }
  return {
    watch = [bulletsInfo, bulletsSecInfo, chosenBullets, chosenBulletsSec, bulletTotalSteps, bulletSecTotalSteps, isOwn]
    size = FLEX_H
    children = mkBulletsTabs(
      allSlots,
      curBulletCategoryId
    )
  }
}

let modsCategoriesBlock = @() {
  watch = modsCategories
  size = FLEX_H
  children = mkModsCategories(
    modsCategories.get()?.map(@(cat) {
      id = cat
      locId = cat == "" ? null : $"modification/{cat}"
    }),
    curModCategoryId
  )
}

let categoriesBlock = @() catsPanelBg.__merge({
  watch = emptyCatSlotHeight
  size = [saBorders[0] + tabW + blocksPadding, flex()]
  padding = [0, blocksPadding - knobSize / 2, 0, 0]
  margin = [contentGamercardGap, 0, 0, 0]
  halign = ALIGN_RIGHT
  children = emptyCatSlotHeight.get() <= 0 ? mkVerticalPannableArea([bulletsCategoriesBlock, modsCategoriesBlock], catsWidth, pageMaskY())
    : {
        size = [catsWidth, flex()]
        padding = [slotsBlockMargin, 0, 0, 0]
        flow = FLOW_VERTICAL
        gap = tabsGap
        children = [bulletsCategoriesBlock, modsCategoriesBlock]
      }
})

let bulletsBlock = @() {
  watch = visibleBulletsList
  size = FLEX_V
  children = mkBullets(visibleBulletsList.get())
}

let modsBlock = @() {
  watch = modsSorted
  size = FLEX_V
  children = mkMods(modsSorted.get())
}

let mkModIcon = @() {
  watch = curMod
  size = [iconSizeW, iconSizeH]
  rendObj = ROBJ_IMAGE
  image = curMod.get()?.name ? Picture($"ui/gameuiskin#{curMod.get().name}.avif:0:P") : null
  keepAspect = KEEP_ASPECT_FILL
}

let mkTextarea = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontTiny)

let mkStatRow = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmall)

function mkBulletsInfo(bullet, unitInfo) {
  let { bSet = null, fromUnitTags = null } = bullet
  let { image = null, icon = null, reqLevel = 0 } = fromUnitTags
  let { caliber = 0.0, bullets = [], shellAnimations = [] } = bSet
  let children = [
    {
      size = [flex(), modH]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = shellVideoGap
      children = [
        {
          size = [modW, modH]
          children = [
            {
              size = flex()
              rendObj = ROBJ_IMAGE
              image = Picture($"{getBulletImage(image, bullets)}:0:P")
              keepAspect = true
              imageHalign = ALIGN_LEFT
              imageValign = ALIGN_BOTTOM
            }
            {
              vplace = ALIGN_TOP
              hplace = ALIGN_CENTER
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              halign = ALIGN_RIGHT
              text = getAmmoNameShortText(bSet)
            }.__update(fontVeryTinyAccentedShaded)
            mkBulletTypeIcon(getBulletTypeIcon(icon, bSet), getAmmoTypeShortText(bullets?[0] ?? ""))
          ]
        }
        mkShellVideo(shellAnimations, shellVideoWidth)
      ]
    }
    mkTextarea(loc("bulletNameWithCaliber", { caliber, bulletName = getAmmoNameText(bSet) }))
    mkTextarea(getAmmoTypeText(bSet))
  ]
  let adviceText = getAmmoAdviceText(bSet)
  if (adviceText != "")
    children.append(mkTextarea(adviceText))
  let stats = getBulletStats(bSet, fromUnitTags, unitInfo.name).map(@(s) {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_TEXT
        text = s.nameText
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
      }.__update(fontTiny)
      {
        rendObj = ROBJ_TEXT
        text = s.valueText
      }.__update(fontTiny)
    ]
  })
  if (stats.len() > 0)
    children.append({
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = stats
    })
  if ((unitInfo?.level ?? 0) < reqLevel && !unitInfo?.isUpgraded && !unitInfo?.isPremium)
    children.append(mkStatRow(loc("mod/reqLevel", { level = reqLevel })))
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(16)
    children
  }
}

function mkModsInfo(mod, unitInfo) {
  let { name = null, reqLevel = 0 } = mod
  let children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = [
        mkModIcon
        {
          size = flex()
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_RIGHT
          text = loc($"modification/{name}")
        }.__update(fontTiny)
      ]
    }

    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc($"modification/{name}/desc")
    }.__update(fontTiny)
  ]
  if ((unitInfo?.level ?? 0) < reqLevel && !unitInfo?.isUpgraded && !unitInfo?.isPremium)
    children.append(mkStatRow(loc("mod/reqLevel", { level = reqLevel })))
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = modsInfoPadding
    gap = hdpx(48)
    children
  }
}

let spinner = {
  size = [buttonStyles.defButtonMinWidth, buttonStyles.defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkSpinner
}

function onPurchase() {
  let unitName = unit.get().name
  let modName = curMod.get().name
  let price = getModCost(curMod.get(), curUnitAllModsCost.get())
  let currencyId = getModCurrency(curMod.get())
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, loc($"modification/{modName}")) }),
    price = { price, currencyId },
    purchase = @() buy_unit_mod(unitName, modName, currencyId, price),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_MODS, PURCH_TYPE_UNIT_MOD, $"{unitName} {modName}")
  })
}

let mkModsButton = @(mod) @() {
  watch = [isCurModPurchased, isCurModEnabled, isCurModLocked, modsInProgress]
  children = isCurModLocked.get()
      ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), mod?.reqLevel ?? 0,
        @() buyUnitLevelWnd(unit.get().name), { hotkeys = ["^J:Y"] })
    : modsInProgress.get() != null ? spinner
    : !isCurModPurchased.get() ? textButtonPurchase(utf8ToUpper(loc("mainmenu/btnBuy")), onPurchase, { ovr = { key = "arsenal_purchase_btn" }, hotkeys = ["^J:Y"] })
    : !isCurModEnabled.get() ? textButtonPrimary(utf8ToUpper(loc("mod/enable")), enableCurUnitMod)
    : !mod?.isAlwaysOn ? textButtonPrimary(utf8ToUpper(loc("mod/disable")), disableCurUnitMod)
    : null
}

let mkBulletsButton = @(bullet) @() {
  watch = [isCurBulletLocked, isCurBulletEnabled]
  children = isCurBulletLocked.get()
      ? textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")), bullet?.fromUnitTags.reqLevel ?? 0,
        @() buyUnitLevelWnd(unit.get().name), { hotkeys = ["^J:Y"] })
    : !isCurBulletEnabled.get()
      ? textButtonPrimary(utf8ToUpper(loc("mod/enable")), @() setOrSwapCurUnitBullet(curBulletCategoryId.get(), bullet.name))
    : null
}

let infoPanelScrollHandler = ScrollHandler()
let resetScrollHandler = @(_) infoPanelScrollHandler.scrollToY(0)
let makeInfoPanelVertScroll = @(content) makeVertScroll(content,
  { isBarOutside = true, scrollHandler = infoPanelScrollHandler })

let unitModsWnd = {
  key = {}
  size = flex()
  padding = [saBordersRv[0], 0, 0, 0]
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  function onAttach() {
    isUnitModAttached.set(true)
    if (choiceCount.get() > 0)
      curBulletCategoryId.set(0)
    else
      curModCategoryId.set(modsCategories.get()?[0])
  }
  onDetach = @() isUnitModAttached.set(false)
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = curCampaign
      padding = [0, 0, 0, saBorders[0]]
      children = mkGamercardUnitCampaign(closeUnitModsWnd, getCampaignPresentation(curCampaign.get()).levelUnitModLocId)
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      children = [
        categoriesBlock
        verticalGradientLine
        @() {
          watch = iconH
          key = iconH
          size = flex()
          flow = FLOW_VERTICAL
          padding = [contentGamercardGap, 0, saBorders[1] - iconH.get(), 0]
          halign = ALIGN_RIGHT
          gap = buttonGap
          function onAttach() {
            curMod.subscribe(resetScrollHandler)
            curBullet.subscribe(resetScrollHandler)
          }
          function onDetach() {
            curMod.unsubscribe(resetScrollHandler)
            curBullet.unsubscribe(resetScrollHandler)
          }
          children = [
            @() panelBg.__merge({
              watch = [unit, curMod, curBullet]
              size = curBullet.get() != null ? [bulletsInfoPanelWidth, infoPanelHeight]
                : curMod.get() != null ? [modsInfoPanelWidth, SIZE_TO_CONTENT]
                : [0, 0]
              padding = infoPanelPadding
              margin = [0, saBorders[0], 0, 0]
              flow = FLOW_VERTICAL
              children = unit.get() == null ? null
                : curMod.get() != null ? mkModsInfo(curMod.get(), unit.get())
                : curBullet.get() != null ? makeInfoPanelVertScroll(mkBulletsInfo(curBullet.get(), unit.get()))
                : null
            })
            @() {
              watch = [curBullet, curMod, isOwn]
              size = FLEX_V
              margin = [0, saBorders[0], 0, 0]
              halign = ALIGN_RIGHT
              valign = ALIGN_BOTTOM
              vplace = ALIGN_BOTTOM
              gap = hdpx(20)
              flow = FLOW_HORIZONTAL
              children = !isOwn.get() ? null
                : [
                    @() {
                      watch = [unit, unseenUnitLvlRewardsList]
                      children = unit.get()?.name not in unseenUnitLvlRewardsList.get() ? null
                        : { children = mkLevelUpRewardBtnChildren(unit.get()) }
                    }
                    curMod.get() != null ? mkModsButton(curMod.get())
                      : curBullet.get() != null ? mkBulletsButton(curBullet.get())
                      : null
                  ].filter(@(v) v != null)
            }
            @() {
              watch = [curModCategoryId, curBulletCategoryId, modTotalH]
              size = [flex(), modTotalH.get()]
              valign = ALIGN_BOTTOM
              vplace = ALIGN_BOTTOM
              children = curModCategoryId.get() != null ? mkCarouselPannableArea(modsBlock, modTotalH.get(), pageMaskX())
                : curBulletCategoryId.get() != null ? mkCarouselPannableArea(bulletsBlock, modTotalH.get(), pageMaskX())
                : null
            }
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitModsWnd", unitModsWnd, closeUnitModsWnd, isUnitModsOpen)
