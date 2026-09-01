from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import deep_clone, isEqual
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import curSlots
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/editTextWnd.nut" import openEditTextWnd, closeEditTextWnd
from "%rGui/components/gradientDefComps.nut" import headerGradientBg, headerHeightInSafeArea, headerMargin
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import openMsgBox
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textButton.nut" import iconButtonPrimary, iconButtonCommon, textButtonPrimary,
  textButtonCommon, textButtonPurchase
from "%rGui/components/verticalBlocks.nut" import mkBlocksContainer
from "%rGui/shop/goodsPreviewState.nut" import openSubsPreview
from "%rGui/slotBar/slotBar.nut" import mkSlotHeader, emptySlotText
from "%rGui/slotBar/slotBarConsts.nut" import unitPlateSize
from "%rGui/slotBar/slotBarState.nut" import getSlotAnimTrigger
from "%rGui/slotBar/slotBarUpdater.nut" import setSlots
from "%rGui/slotBar/slotPresetsState.nut" import playerSelectedPresetIdx, playerSelectedSlotIdx, currentPresetName,
  savedSlotPresets, isOpenedPresetWnd, closeSlotPresetWnd, currentPresetUnits, setSavedSlotPresets, loadSlotPresets
from "%rGui/state/profilePremium.nut" import hasPrem, hasVip, hasPremiumSubs
from "%rGui/style/backgrounds.nut" import bgShadedDark
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/components/unitInfoPanel.nut" import unitInfoPanel, mkUnitTitle, statsWidth
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, bgUnit, mkUnitImage, mkUnitTexts, mkUnitPlateBorder,
  mkUnitLock, mkUnitSelectedGlow


const WND_UID = "SLOT_PRESET_WND"

const MAX_TEXT_LENGTH_DEFAULT = 32
let gameProfile = Computed(@() serverConfigs.get()?.gameProfile)
let maxPreset = Computed(@() gameProfile.get()?.maxSavedPreset ?? 5)
let maxPresetsPrem = Computed(@() gameProfile.get()?.premiumBonuses.maxSavedPreset ?? maxPreset.get())
let maxPresetsVip = Computed(@() gameProfile.get()?.vipBonuses.maxSavedPreset ?? maxPreset.get())
let subIconSize = [hdpxi(50), hdpxi(30)]
const btnMinWidth = hdpx(200)
const btnIconSize = hdpx(70)
const iconSize = hdpx(40)
const btnGap = hdpx(20)
const infoPanelPadding = hdpx(50)
let infoPanelWidth = statsWidth + infoPanelPadding
let presetBlockWidth = saSize[0] - infoPanelWidth - headerMargin
let presetBlockHeight = saSize[1] - headerHeightInSafeArea - headerMargin
let maxPresetsCount = Computed(@() hasPrem.get() ? maxPresetsPrem.get()
  : hasVip.get() ? maxPresetsVip.get()
  : maxPreset.get())
let subsIdToGetMorePresets = Computed(@() maxPresetsVip.get() > maxPresetsCount.get() ? "vip"
  : maxPresetsPrem.get() > maxPresetsCount.get() ? "premium"
  : null)

let mkUnitPlate = @(unit) {
  size = unitPlateSize
  behavior = Behaviors.Button
  children = [
    mkUnitBg(unit)
    mkUnitSelectedGlow(unit, Watched(false))
    mkUnitImage(unit)
    mkUnitTexts(unit, getUnitName(unit.name))
    mkUnitLock(unit, false)
    mkUnitPlateBorder(Watched(false))
  ]
}

function closeEditNameWnd() {
  closeEditTextWnd()
  currentPresetName.set("")
}

function onSave(name) {
  let newPreset = {
    name
    presetUnits = currentPresetUnits.get()
  }
  setSavedSlotPresets(deep_clone(savedSlotPresets.get()).append(newPreset), curCampaign.get())
}

function onSetPresetName(presets, presetIdx) {
  let name = currentPresetName.get().strip()
  if (name.len() == 0)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/empty_name")})
  let savedPresets = savedSlotPresets.get()
  if (savedPresets.findindex(@(p) p.name == name) != null)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/duplicated")})
  let allPresets = presets
  let presetIdxToEdit = allPresets.len() == savedPresets.len() ? presetIdx : -1
  if (presetIdxToEdit == -1)
    onSave(name)
  else
    setSavedSlotPresets(savedPresets.map(@(p, idx) idx != presetIdxToEdit ? p : p.__merge({name})), curCampaign.get())
  closeEditNameWnd()
}

function openEditNameWnd(presets, presetIdx, isNotSaved, isMaxAmountReached, isNew = false) {
  if (isNew) {
    if (!isNotSaved)
      return openMsgBox({text = loc("msgbox/presets/cannot_save/already_saved")})
    if (isMaxAmountReached)
      return allow_subscriptions.get() && subsIdToGetMorePresets.get()
        ? openMsgBox({
          text = loc("msgbox/presets/cannot_save/max_reached_without_subscription",
            { subsActionTxt = loc(hasPremiumSubs.get() ? "msgbox/presets/unlockBySubs/upgrade" : "msgbox/presets/unlockBySubs/activate") }),
          buttons = [
            { id = "cancel", isCancel = true }
            {
              id = "ok",
              text = loc("subscription/viewSubsPlans"),
              styleId = "PURCHASE",
              isDefault = true,
              cb = @() openSubsPreview("vip", "slot_presets")
            }
          ]})
        : openMsgBox({text = loc("msgbox/presets/cannot_save/max_reached")})
  } else {
    if (isNotSaved)
      return openMsgBox({text = loc("msgbox/presets/cannot_edit")})
  }

  openEditTextWnd(currentPresetName, @() onSetPresetName(presets, presetIdx), MAX_TEXT_LENGTH_DEFAULT)
  currentPresetName.set(presets?.findvalue(@(p) p.idx == presetIdx).name ?? "")
}

function onDelete(presets, presetIdx, isNotSaved, campaign) {
  let preset = presets.findvalue(@(p) p.idx == presetIdx)
  if (!preset)
    return
  if (isNotSaved)
    return openMsgBox({text = loc("msgbox/presets/cannot_delete")})

  let name = preset.name
  openMsgBox({
    text = loc("presets/confirmUserPresetDeletion", { name })
    buttons = [
      { id = "cancel", isCancel = true }
      {
        id = "delete",
        cb = @() setSavedSlotPresets(deep_clone(savedSlotPresets.get())
          .filter(@(p) p.name != name), campaign),
        styleId = "PRIMARY"
      }
    ]
  })
}

function onApply(presets, presetIdx, campaign, isCurrent) {
  let preset = presets.findvalue(@(p) p.idx == presetIdx)
  if (!preset)
    return
  if (isCurrent)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply")})
  setSlots(campaign, preset.presetUnits)
  foreach(idx, name in preset.presetUnits)
    anim_start(getSlotAnimTrigger(idx, name, presetIdx))
}

function mkCustomIconButton(iconPath, onClick, isDisabled, hotkeys = null) {
  let mkButton = isDisabled ? iconButtonCommon : iconButtonPrimary
  return @() {
    watch = isGamepad
    children = mkButton(
      iconPath,
      onClick
      {
        iconOvr = { size = iconSize },
        ovr = {
          size = isGamepad.get() ? [btnIconSize*2, btnIconSize] : [btnIconSize, btnIconSize],
          minWidth = btnIconSize
        }
        hotkeys
      }
    )
  }
}

function mkPresetButtons(presets, presetIdx) {
  let selectedPreset = Computed(@() presets.get().findvalue(@(p) p.idx == presetIdx.get()))
  let isCurrentPreset = Computed(@() isEqual(selectedPreset.get()?.presetUnits, currentPresetUnits.get()))
  let isNotSavedPreset = Computed(@() presets.get().len() != savedSlotPresets.get().len() && presetIdx.get() == -1)
  let isMaxSavedPresetAmountReached = Computed(@() presets.get().len() > maxPresetsCount.get())
  let canEdit = Computed(@() maxPresetsCount.get() <= (selectedPreset.get()?.idx ?? -1))
  let iconBtnsRow = @() {
    watch = [canEdit, isNotSavedPreset, isMaxSavedPresetAmountReached, isGamepad]
    size = isGamepad.get() ? FLEX_H : SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    gap = isGamepad.get() ? {size = FLEX} : btnGap
    children = [
      mkCustomIconButton(
        "ui/gameuiskin#btn_trash.svg",
        @() onDelete(presets.get(), presetIdx.get(), isNotSavedPreset.get(), curCampaign.get()),
        isNotSavedPreset.get(),
        ["^J:LT"]
      ),
      canEdit.get() ? null
        : mkCustomIconButton(
          "ui/gameuiskin#menu_edit.svg",
          @() openEditNameWnd(presets.get(), presetIdx.get(), isNotSavedPreset.get(), isMaxSavedPresetAmountReached.get(), false),
          isNotSavedPreset.get(),
          ["^J:LB"]
        ),
      canEdit.get() ? null
        : mkCustomIconButton(
          "ui/gameuiskin#icon_save.svg",
          @() openEditNameWnd(presets.get(), presetIdx.get(), isNotSavedPreset.get(), isMaxSavedPresetAmountReached.get(), true),
          !isNotSavedPreset.get() || isMaxSavedPresetAmountReached.get(),
          ["^J:Y"]
        )
    ]
  }

  let txtBtnsRow = @() {
    watch = [canEdit, isCurrentPreset]
    size = FLEX_H
    children = canEdit.get()
      ? textButtonPurchase(utf8ToUpper(loc("subscription/activate")),
          @() openSubsPreview("vip", "slot_presets"),
          {
            ovr = {
              size = const [FLEX, btnIconSize]
            },
            hotkeys = ["^J:X"]
          }
        )
      : (isCurrentPreset.get() ? textButtonCommon : textButtonPrimary)(
          utf8ToUpper(loc("mainmenu/btnApply")),
          @() onApply(presets.get(), presetIdx.get(), curCampaign.get(), isCurrentPreset.get()),
          {
            ovr = {size = const [FLEX, btnIconSize], minWidth = btnMinWidth},
            childOvr = fontTinyAccentedShaded,
            hotkeyBlockOvr = {padding = 0}
            hotkeys = ["^J:X"]
          },
        )
  }

  return @() {
    watch = isGamepad
    size = [statsWidth, SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
    clipChildren = true
    vplace = ALIGN_TOP
    flow = isGamepad.get() ? FLOW_VERTICAL : FLOW_HORIZONTAL
    gap = btnGap
    children = [
      iconBtnsRow,
      txtBtnsRow
    ]
  }
}


let header = headerGradientBg([
  backButton(closeSlotPresetWnd)
  {
    rendObj = ROBJ_TEXT
    text = loc("presets/title")
  }.__update(fontMedium)
])

function mkPresetUnitSlot(unit, slotIdx, presetIdx, onClick, isSelected) {
  let stateFlags = Watched(0)
  if (unit == null)
    return @() {
      watch = [isSelected, stateFlags]
      size = unitPlateSize
      behavior = Behaviors.Button
      onClick
      rendObj = ROBJ_IMAGE
      image = bgUnit
      sound = { click = "choose" }
      children = [
        emptySlotText
        mkUnitPlateBorder(isSelected)
      ]
    }
  let trigger = getSlotAnimTrigger(slotIdx, unit.name, presetIdx)
  let isGlowing = Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER))

  return @() {
    watch = [isSelected, stateFlags]
    key = trigger
    size = unitPlateSize
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags.set(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, isGlowing)
      mkUnitImage(unit)
      mkUnitTexts(unit, getUnitName(unit.name))
      mkUnitLock(unit, false)
      mkUnitPlateBorder(isSelected)
    ]
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.scale, from = [0.8, 0.8], duration = 0.2, easing = InQuad, trigger }
      { prop = AnimProp.scale, to = [1.1, 1.1], duration = 0.3, delay = 0.2, easing = Blink, trigger}
      { prop = AnimProp.opacity, from = 0.0, duration = 0.2, easing = OutQuad, trigger }
    ]
  }
}

function mkPresetSlot(slot, slotIdx, presetIdx, isSelected, onClick) {
  let { name = "" } = slot
  let unit = Computed(@() campMyUnits.get()?[name])
  return @() {
    watch = unit
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = [
      mkSlotHeader(slot, slotIdx, isSelected)
      mkPresetUnitSlot(unit.get(), slotIdx, presetIdx, onClick, isSelected)
    ]
  }
}

let mkPresetSlots = @(preset, presetIdx, aPresetIdx, aSlotIdx) @() {
  watch = [curSlots, aPresetIdx, aSlotIdx]
  flow = FLOW_HORIZONTAL
  gap = hdpx(4)
  children = curSlots.get()
    .map(function(slot, i) {
      let pSlot = slot.__merge({name = preset.presetUnits[i]})
      return mkPresetSlot(
        pSlot,
        i,
        presetIdx,
        Computed(@() aPresetIdx.get() == presetIdx && aSlotIdx.get() == i),
        function() {
          if (pSlot.name != "")
            playerSelectedSlotIdx.set(i)
          else
            playerSelectedSlotIdx.set(preset.presetUnits.findindex(@(n) n != ""))
          playerSelectedPresetIdx.set(presetIdx)
        },
      )}
    )
}


let mkBlockContent = @(preset, activePresetIdx, activeSlotIdx) @() {
  watch = currentPresetUnits
  rendObj = ROBJ_BOX
  children = [
    {
      size = [presetBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(4)
      padding = const [hdpx(10), hdpx(2), hdpx(2)]
      children = [
        {
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          children = [
            {
              rendObj = ROBJ_TEXT
              behavior = Behaviors.Marquee
              delay = defMarqueeDelay
              speed = hdpx(30)
              maxWidth = pw(100)
              margin = const [0, 0, 0, hdpx(4)]
              text = $"{preset.name}{!(isEqual(preset.presetUnits, currentPresetUnits.get())) ? "" : $" ({loc("presets/current")})"}"
            }.__update(fontTinyShaded)
            @() {
              watch = [maxPreset, maxPresetsPrem, maxPresetsVip]
              size = subIconSize
              rendObj = ROBJ_IMAGE
              image = preset.idx >= maxPreset.get() && preset.idx < maxPresetsPrem.get()
                  ? Picture($"ui/gameuiskin/gamercard_subs_prem.avif:{subIconSize[0]}:{subIconSize[1]}:P")
                : preset.idx >= maxPresetsPrem.get() && preset.idx < maxPresetsVip.get()
                  ? Picture($"ui/gameuiskin/gamercard_subs_vip.avif:{subIconSize[0]}:{subIconSize[1]}:P")
                : null
              keepAspect = true
            }.__update(fontTinyShaded)
          ]
        }
        mkPresetSlots(preset, preset.idx, activePresetIdx, activeSlotIdx)
      ]
    }
    @() {
      watch = maxPresetsCount
      size = FLEX
      children = maxPresetsCount.get() > preset.idx ? null
        : {
            size = FLEX
            rendObj = ROBJ_SOLID
            color = 0xDD000000
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = {
              rendObj = ROBJ_TEXT
              text = utf8ToUpper(loc("subscription/available"))
            }.__update(fontSmall)
          }
    }
  ]
}


let mkMainContent = @(presets, presetIdx, slotIdx) @() {
  watch = presetIdx
  size = FLEX
  children = [
    mkBlocksContainer(
      presets,
      presetIdx,
      @(p, _) mkBlockContent(p, presetIdx, slotIdx),
      function(idx) {
        playerSelectedPresetIdx.set(idx)
        playerSelectedSlotIdx.set(null)
      },
      presetBlockWidth,
      hdpx(190),
      presetBlockHeight
    )
  ]
}

function mkSlotPresetWnd() {
  let slotPresets = Computed(function() {
    let savedSPresets = savedSlotPresets.get().map(@(v, i) v.__merge({ idx = i }))
    let currentPresetIdx = savedSPresets.findindex(@(p) isEqual(p.presetUnits, currentPresetUnits.get())) ?? -1

    if (currentPresetIdx == -1)
      return [{
        idx = -1
        name = "",
        presetUnits = currentPresetUnits.get()
      }].extend(savedSPresets)

    return savedSPresets
  })
  let activePresetIdx = Computed(@() playerSelectedPresetIdx.get()
    ?? slotPresets.get().findvalue(@(p) isEqual(p?.presetUnits, currentPresetUnits.get()))?.idx
    ?? -1)
  let activePresetUnits = Computed(@() slotPresets.get().findvalue(@(p) p.idx == activePresetIdx.get())?.presetUnits ?? [])
  let activeSlotIdx = Computed(@() playerSelectedSlotIdx.get() ?? activePresetUnits.get().findindex(@(n) n !=""))
  let presetSlotUnit = Computed(@() campMyUnits.get()?[activePresetUnits.get()?[activeSlotIdx.get()]])
  let presetButtons = mkPresetButtons(slotPresets, activePresetIdx)
  return bgShadedDark.__merge({
    key = {}
    size = FLEX
    padding = saBordersRv
    onDetach = closeSlotPresetWnd
    onAttach = loadSlotPresets
    flow = FLOW_VERTICAL
    children = [
      header
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = headerMargin
        children = [
          mkMainContent(slotPresets, activePresetIdx, activeSlotIdx)
          {
            size = [infoPanelWidth, FLEX]
            children = @() panelBg.__merge({
              watch = presetSlotUnit
              size = [infoPanelWidth + saBorders[0], FLEX]
              padding = [infoPanelPadding, saBorders[0], 0, infoPanelPadding]
              flow = FLOW_VERTICAL
              children = presetSlotUnit.get() == null
                ? [
                    { size = FLEX }
                    presetButtons
                  ]
                : [
                    mkUnitPlate(presetSlotUnit.get()).__merge({ hplace = ALIGN_CENTER })
                    unitInfoPanel(
                      {
                        size = [statsWidth, FLEX]
                        padding = const [infoPanelPadding, 0, 0, 0]
                        hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
                        animations = wndSwitchAnim
                      }, mkUnitTitle, presetSlotUnit, {})
                    presetButtons
                  ]
            })
          }
        ]
      }
    ]
  })
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = FLEX
  children = mkSlotPresetWnd()
  onClick = closeSlotPresetWnd
  stopMouse = true
})

if (isOpenedPresetWnd.get())
  openImpl()
isOpenedPresetWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
