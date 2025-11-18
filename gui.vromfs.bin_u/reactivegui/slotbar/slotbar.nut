from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { balance, GOLD } = require("%appGlobals/currenciesState.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { translucentSlotButton, getBorderCommand, lineWidth, slotBtnSize,
  COMMADN_STATE
} = require("%rGui/components/translucentButton.nut")
let { campMyUnits, campUnitsCfg, curUnit } = require("%appGlobals/pServer/profile.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, bgUnit, mkUnitSelectedGlow,
  mkUnitPlateBorder, mkProfileUnitDailyBonus, mkUnitSpinner
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { setUnitToSlot, buyUnitSlot, newSlotPriceGold, slotsNeedAddAnim, visibleNewModsSlots, selectedTreeSlotIdx,
  getSlotAnimTrigger, onFinishSlotAnim, selectedSlotIdx, slotBarArsenalKey, slotBarSlotKey, slotBarSelectWndAttached,
  selectedUnitToSlot, attachedSlotBarArsenalIdx
} = require("%rGui/slotBar/slotBarState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { slotBarTreeHeight, unitPlateSize, unitPlateHeader, slotsGap } = require("%rGui/slotBar/slotBarConsts.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { openUnitModsSlotsWnd, mkListUnseenMods, mkHasUnitWeaponSlots } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { openUnitModsWnd, modsPresets, mkUnitAllModsCost, hasEnoughCurrencies } = require("%rGui/unitMods/unitModsState.nut")
let { unseenCampUnitMods } = require("%rGui/unitMods/unseenMods.nut")
let { mkUnseenUnitBullets } = require("%rGui/unitMods/unseenBullets.nut")
let { mkSlotLevel, levelHolderSize } = require("%rGui/attributes/slotAttr/slotLevelComp.nut")
let { levelProgressBorderWidth } = require("%rGui/components/levelBlockPkg.nut")
let { priorityUnseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")
let { openSlotAttrWnd, mkUnseenSlotAttrByIdx } = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { infoPanelWidth } = require("%rGui/unitsTree/unitsTreeComps.nut")
let { gradTranspDoubleSideX, mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")
let { draggedData, dropUnitToSlot, dropZoneSlotIdx } = require("%rGui/slotBar/dragDropSlotState.nut")
let { notActualSlotsByUnit } = require("%rGui/slotBar/slotBarUpdater.nut")


let marginVert = hdpx(5)
let buyIconSize = hdpxi(40)
let actionBtnSize = slotBtnSize
let actionBtnsBlockSize = [unitPlateSize[0], actionBtnSize[1] + unseenSize[0]]
let slotBarSize = [saSize[0] - defButtonMinWidth, unitPlateSize[1] + actionBtnsBlockSize[1] + unitPlateHeader + marginVert]
let mainMenuTopPadding = hdpx(10)
let slotBarMainMenuSize = [slotBarSize[0], slotBarSize[1] + mainMenuTopPadding]
let slotBarUnitsTreePadding = hdpx(20)
let slotBarUnitsTreeWidth = saSize[0] - infoPanelWidth + saBorders[0] * 2

let aTimeSlotRemove = 0.5
let aTimeSlotAddAppear = 0.2
let aTimeSlotAddBlink = 0.3

let removeUnitTrigger = {}

let playSlotRemove = @() playSound("meta_unit_remove")
let playSlotRemoveDelayed = @() resetTimeout(0.01, playSlotRemove)
let slotChangeTrigger = "slotChange"
let changeBtnAnimation = [
  { prop = AnimProp.fillColor, from = 0x60000000, to = 0x10202020,
    duration = 1, easing = CosineFull trigger = slotChangeTrigger }
  { prop = AnimProp.fillColor, from = 0x60000000, to = 0x10202020, delay = 1,
    duration = 1, easing = CosineFull trigger = slotChangeTrigger }
]

let highlightEmptySearch = mkColoredGradientY(0x20A0A0A0, 0)

selectedTreeSlotIdx.subscribe(@(idx) curSlots.get()?[idx].name == "" ? deferOnce(@() anim_start(slotChangeTrigger)) : null)

function skipRemoveAnim() {
  anim_skip(removeUnitTrigger)
  clearTimer(playSlotRemove)
}

let emptySlotText = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("slotbar/empty")
}.__update(fontVeryTinyAccented)

let dropBorderMarker = {
  size = flex()
  rendObj = ROBJ_BOX
  borderColor = 0xFFFFFFFF
  borderWidth = hdpxi(4)
}

let mkEmptySlot = @(idx, isSelected, stateFlags, onClick) @() {
  watch = [isSelected, stateFlags]
  key = $"empty_{idx}"
  size = unitPlateSize
  behavior = Behaviors.DragAndDrop
  onClick
  onDrop = @(data) dropUnitToSlot(idx, data)
  onElemState = function(sf) {
    stateFlags.set(sf)
    if (draggedData.get())
      dropZoneSlotIdx.set(sf & S_ACTIVE ? idx : null)
  }
  clickableInfo = loc("mainmenu/btnSelect")
  sound = { click = "choose" }
  rendObj = ROBJ_IMAGE
  image = bgUnit
  children = [
    emptySlotText
    mkUnitSelectedGlow(null, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
    mkUnitPlateBorder(isSelected)
  ]
  animations = [{ prop = AnimProp.opacity, to = 0.0, duration = aTimeSlotAddAppear,
    easing = OutQuad, playFadeOut = true }]
}

let function mkDefaultEmptySlot(idx) {
  let isSelected = Computed(@() selectedSlotIdx.get() == idx)

  return {
    size = unitPlateSize
    rendObj = ROBJ_IMAGE
    image = bgUnit
    children = [
      emptySlotText
      mkUnitPlateBorder(isSelected)
    ]
  }
}

let function emptySelectSlot(idx) {
  let isSelected = Computed(@() selectedSlotIdx.get() == idx)
  let stateFlags = Watched(0)
  let onClick = @() selectedSlotIdx.set(idx)

  return mkEmptySlot(idx, isSelected, stateFlags, onClick)
}

let function emptySelectSlotTree(idx) {
  let isSelected = Computed(@() selectedTreeSlotIdx.get() == idx)
  let stateFlags = Watched(0)

  function onClick() {
    setUnitToSlot(idx)
    selectedTreeSlotIdx.set(idx)
    anim_start(slotChangeTrigger)
  }

  return mkEmptySlot(idx, isSelected, stateFlags, onClick)
}

let function emptySlotTree(idx) {
  let isSelected = Computed(@() selectedTreeSlotIdx.get() == idx)
  let stateFlags = Watched(0)

  function onClick() {
    curSelectedUnit.set(null)
    selectedTreeSlotIdx.set(idx)
  }

  return mkEmptySlot(idx, isSelected, stateFlags, onClick)
}

let function slotToPurchase(priceGold) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = unitPlateSize
    rendObj = ROBJ_BOX
    fillColor = 0x80000000
    borderColor = 0xFFFFFFFF
    borderWidth = hdpx(3)
    behavior = Behaviors.Button
    onClick = buyUnitSlot
    onElemState = @(s) stateFlags.set(s)
    children = [
      mkUnitSelectedGlow(null, Computed(@() stateFlags.get() & S_HOVER))
      {
        size = array(2, buyIconSize)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        keepAspect = true
        image = Picture($"ui/gameuiskin#icon_slot_buy.svg:{buyIconSize}:{buyIconSize}:P")
      }
      {
        pos = [hdpx(10), hdpx(-10)]
        vplace = ALIGN_BOTTOM
        children = mkCurrencyComp(
          priceGold,
          GOLD,
          CS_COMMON.__merge({ fontStyle = fontTinyAccented }))
      }
    ]
  }
}

let mkMark = {
  pos = [0, -unseenSize[0] / 2]
  vplace = ALIGN_TOP
  hplace = ALIGN_CENTER
}

let statusUnseenMark = @(hasUnseenMark) @() {
  watch = hasUnseenMark
  children = hasUnseenMark.get() ? priorityUnseenMark : null
}.__update(mkMark)

let slotIndicatorSize = hdpx(16)

let mkUnseenIndicator = @(ovr = {}) {
  size = [hdpx(45), unitPlateHeader]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2)
  fillColor = 0xFFFFB70B
  color = 0xFFFFB70B
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [slotIndicatorSize, slotIndicatorSize]
    rendObj = ROBJ_IMAGE
    color = 0xFFFFFF
    image = Picture($"ui/gameuiskin#button_notify_marker.svg:{slotIndicatorSize}:{slotIndicatorSize}:P")
    keepAspect = true
  }
  commands = [[VECTOR_POLY, 0, 100, 50, 0, 100, 0, 50, 100, 0, 100]]
  animations = [{
    prop = AnimProp.opacity, from = 0.2, to = 1.0, easing = CosineFull,
    duration = 3.0, play = true, loop = true, globalTimer = true
  }]
}.__update(ovr)

let mkSlotHeaderTitle = @(text, isSelected) {
  rendObj = ROBJ_TEXT
  color = isSelected ? 0xFF383B3E : 0xFFFFFFFF
  text
}.__update(fontVeryTinyAccented)

function mkSlotHeaderIndicator(unit, hasUnseenMods, hasUnseenMarker, idx, isSelected) {
  let mutateSlots = @(v) visibleNewModsSlots.mutate(@(nms) v ? nms.$rawset(idx, unit.get()?.name ?? "") : nms.$rawdelete(idx))
  return @() {
    watch = [hasUnseenMarker, isSelected]
    key = mutateSlots
    function onAttach() {
      mutateSlots(hasUnseenMods.get())
      hasUnseenMods.subscribe(mutateSlots)
    }
    function onDetach() {
      mutateSlots(hasUnseenMods.get())
      hasUnseenMods.unsubscribe(mutateSlots)
    }
    children = isSelected.get() || !hasUnseenMarker.get() ? null : mkUnseenIndicator({ pos = [-hdpx(27), hdpx(1)], key = {} })
  }
}

function mkSlotHeader(slot, idx, isSelected) {
  let { level = 0 } = slot

  return @(){
    watch = isSelected
    size = [unitPlateSize[0], unitPlateHeader]
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_BOX
    fillColor = isSelected.get() ? 0xFFFFFFFF : 0xFF212121
    children = [
      {
        padding = const [0, hdpx(10)]
        hplace = ALIGN_LEFT
        children = mkSlotHeaderTitle(loc("gamercard/slot/title", { idx = idx + 1 }), isSelected.get())
      }
      {
        size = flex()
      }
      {
        hplace = ALIGN_RIGHT
        pos = [hdpx(5), hdpx(1)]
        children = [
          mkSlotLevel(level,
            hdpx(26),
            { size = [hdpx(110), unitPlateHeader] },
            { fillColor = 0xFF383B3E, color = isSelected.get() ? 0xFFFFFFFF : 0xFFA0A0A0})
        ]
      }
    ]
  }
}

let function mkUnitSlot(unit, idx, onClick, isSelected) {
  let stateFlags = Watched(0)
  let trigger = getSlotAnimTrigger(idx, unit.name)
  let needPlayOnAttach = slotsNeedAddAnim.get()?[idx] == unit.name
  let needShowSpinner = Computed(@() unit.name in notActualSlotsByUnit.get())
  return @() {
    watch = [isSelected, stateFlags, selectedUnitToSlot]
    key = $"slot_{idx}_{unit.name}"
    size = unitPlateSize
    behavior = Behaviors.DragAndDrop
    onClick
    dropData = selectedUnitToSlot.get() != null ? null : { unitName = unit.name, fromIdx = idx, canRemove = true }
    onDragMode = @(on, data) draggedData.set(on ? data : null)
    onDrop = @(data) dropUnitToSlot(idx, data)
    onElemState = function(sf) {
      stateFlags.set(sf)
      if (draggedData.get() != null && (sf & S_ACTIVE) && draggedData.get().unitName != unit.name)
        dropZoneSlotIdx.set(idx)
    }
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitLock(unit, false)
      mkUnitPlateBorder(isSelected)
      {
        padding = const [0, 0, hdpx(3), hdpx(3)]
        vplace = ALIGN_BOTTOM
        children = mkProfileUnitDailyBonus(unit)
      }
      mkUnitSpinner(needShowSpinner)
    ]
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.translate, to = unitPlateSize.map(@(v) v / 4), duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger, onStart = playSlotRemoveDelayed }
      { prop = AnimProp.scale, to = [0.5, 0.5], duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }
      { prop = AnimProp.opacity, to = 0.0, duration = aTimeSlotRemove,
        easing = InOutQuad, playFadeOut = true, trigger = removeUnitTrigger }

      { prop = AnimProp.scale, from = [0.8, 0.8], duration = aTimeSlotAddAppear,
        easing = InQuad, trigger, play = needPlayOnAttach, sound = { start = "meta_unit_place" } }
      { prop = AnimProp.scale, to = [1.1, 1.1], duration = aTimeSlotAddBlink, delay = aTimeSlotAddAppear,
        easing = Blink, trigger, play = needPlayOnAttach, onFinish = @() onFinishSlotAnim(idx) }
      { prop = AnimProp.opacity, from = 0.0, duration = aTimeSlotAddAppear,
        easing = OutQuad, trigger, play = needPlayOnAttach }
    ]
  }
}

function actionBtns(unit, hasUnseenArsenal, hasUnseenAttributes, hasUnitWeaponSlots, idx) {
  let showBtns = Computed(@() selectedSlotIdx.get() == idx)
  let hasUnit = Computed(@() unit.get() != null)
  return @() {
    watch = [showBtns, hasUnit, hasUnitWeaponSlots]
    size = actionBtnsBlockSize
    pos = [lineWidth / 2, 0]
    margin = [0, 0, marginVert, 0]
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = lineWidth
    children = !showBtns.get() ? null : [
      translucentSlotButton("ui/gameuiskin#icon_slot_change.svg",
        openUnitsTreeWnd,
        null,
        {
          commands = getBorderCommand(COMMADN_STATE.LEFT),
          animations = changeBtnAnimation
        })
      !hasUnit.get()
        ? translucentSlotButton("ui/gameuiskin#arsenal.svg", @() null, null,
            { fillColor = 0x9F000000, watch = null })
        : translucentSlotButton("ui/gameuiskin#arsenal.svg",
            hasUnitWeaponSlots.get() ? openUnitModsSlotsWnd : openUnitModsWnd, statusUnseenMark(hasUnseenArsenal),
            {
              key = slotBarArsenalKey,
              onAttach = @() attachedSlotBarArsenalIdx.set(idx),
              onDetach = @() attachedSlotBarArsenalIdx.set(null)
            })
      translucentSlotButton("ui/gameuiskin#slot_crew.svg",
        openSlotAttrWnd,
        statusUnseenMark(hasUnseenAttributes),
        {
          key = "slot_crew_btn" 
          commands = getBorderCommand(COMMADN_STATE.RIGHT)
        })
    ]
  }
}

function onUnitSlotClick(unit, idx) {
  if (unit.get() == null || selectedSlotIdx.get() == idx)
    return

  let unitName = unit.get().name

  if (unitName != curUnit.get()?.name)
    setCurrentUnit(unitName)

  selectedSlotIdx.set(idx)
}

let function mkSlotWithButtons(slot, idx) {
  let unit = Computed(@() campMyUnits.get()?[slot?.name] ?? campUnitsCfg.get()?[slot?.name])
  let needHideDraggableUnit = Computed(@() draggedData.get() != null && draggedData.get()?.fromIdx == idx)
  let needClearDropZone = Computed(@() dropZoneSlotIdx.get() == idx)
  let isDraggedUnit = Computed(@() draggedData.get() && unit.get()?.name == draggedData.get()?.unitName)
  let isSelected = Computed(@() selectedSlotIdx.get() == idx)
  let needTargetMarker = Computed(@() draggedData.get() != null && needClearDropZone.get())
  let needShowDefEmptySlot = Computed(@() needHideDraggableUnit.get() || isDraggedUnit.get())

  let unseenMods = mkListUnseenMods(unit)
  let hasUnitWeaponSlots = mkHasUnitWeaponSlots(unit)
  let hasUnseenMods = Computed(@() hasUnitWeaponSlots.get() ? unseenMods.get().len() > 0
    : slot?.name in unseenCampUnitMods.get())

  let unitAllModsCost = mkUnitAllModsCost(unit)
  let hasUnseenModsForTutorial = Computed(function() {
    if (hasUnitWeaponSlots.get())
      return unseenMods.get().len() > 0
    let unseenUnitMods = unseenCampUnitMods.get()?[slot?.name] ?? {}
    if (unseenUnitMods.len() == 0)
      return false
    let mods = modsPresets.get()?[unit.get()?.modPreset] ?? {}
    return null != unseenUnitMods.findvalue(@(_, k) hasEnoughCurrencies(mods?[k], unitAllModsCost.get(), balance.get()))
  })

  let slotUnseenBullets = mkUnseenUnitBullets(Watched(slot?.name))
  let hasUnseenBullets = Computed(function() {
    if (hasUnitWeaponSlots.get())
      return false
    let { primary, secondary } = slotUnseenBullets.get()
    return primary.len() > 0 || secondary.len() > 0
  })

  let hasUnseenRewards = Computed(@() unit.get()?.name in unseenUnitLvlRewardsList.get())

  let hasUnseenArsenal = Computed(@() hasUnseenMods.get() || hasUnseenBullets.get() || hasUnseenRewards.get())

  let unseenAttr = mkUnseenSlotAttrByIdx(idx)
  let hasUnseenAttributes = Computed(@() unseenAttr.get().isUnseen)
  let hasUnseenMarker = Computed(@() hasUnseenArsenal.get() || hasUnseenAttributes.get())
  return @() {
    watch = needTargetMarker
    flow = FLOW_VERTICAL
    children = [
      actionBtns(unit, hasUnseenArsenal, hasUnseenAttributes, hasUnitWeaponSlots, idx)
      {
        children = [
          @() {
            watch = [unit, needShowDefEmptySlot, needClearDropZone]
            key = slotBarSlotKey(idx) 
            flow = FLOW_VERTICAL
            children = [
              {
                children = [
                  mkSlotHeader(slot, idx, isSelected)
                  {
                    pos = [-levelHolderSize[0] / 2 - levelProgressBorderWidth * 2, 0]
                    hplace = ALIGN_RIGHT
                    children = mkSlotHeaderIndicator(unit, hasUnseenModsForTutorial, hasUnseenMarker, idx, isSelected)
                  }
                ]
              }
              needShowDefEmptySlot.get() ? mkDefaultEmptySlot(idx) : null
              unit.get() == null || needClearDropZone.get()
                ? emptySelectSlot(idx)
                : mkUnitSlot(unit.get(), idx, @() onUnitSlotClick(unit, idx), isSelected)
            ]
          }
          needTargetMarker.get() ? dropBorderMarker : null
        ]
      }
    ]
  }
}

let mainMenuPannable = horizontalPannableAreaCtor(saSize[0] - defButtonMinWidth, [0, 0])
let slotBarMainMenu = mainMenuPannable(@() {
  watch = curSlots
  key = "slotBarMainMenu"
  onDetach = skipRemoveAnim
  flow = FLOW_HORIZONTAL
  gap = slotsGap
  children = curSlots.get().map(mkSlotWithButtons)
}, {}, { padding = [mainMenuTopPadding, 0, 0, 0]})

function mkSlotCommon(slot, idx) {
  let { name = "" } = slot
  let unit = Computed(@() campMyUnits.get()?[name] ?? campUnitsCfg.get()?[name])
  let needHideDraggableUnit = Computed(@() draggedData.get() != null && draggedData.get()?.fromIdx == idx)
  let isDraggedUnit = Computed(@() draggedData.get() && unit.get()?.name == draggedData.get()?.unitName)
  let needClearDropZone = Computed(@() dropZoneSlotIdx.get() == idx)
  let isSelected = Computed(@() selectedTreeSlotIdx.get() == idx)
  let needTargetMarker = Computed(@() draggedData.get() != null && needClearDropZone.get())
  let needShowDefEmptySlot = Computed(@() needHideDraggableUnit.get() || isDraggedUnit.get())

  return @() {
    watch = [unit, needShowDefEmptySlot, needClearDropZone, needTargetMarker]
    children = [
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_BOTTOM
        children = [
          mkSlotHeader(slot, idx, Computed(@() selectedTreeSlotIdx.get() == idx))
          needShowDefEmptySlot.get() ? mkDefaultEmptySlot(idx) : null
          unit.get() == null || needClearDropZone.get()
            ? emptySlotTree(idx)
            : mkUnitSlot(unit.get(), idx, @() curSelectedUnit.set(name != "" ? name : null), isSelected)
        ]
      }
      needTargetMarker.get() ? dropBorderMarker : null
    ]
  }
}

let unitsTreePannable = horizontalPannableAreaCtor(slotBarUnitsTreeWidth, [0, 0])
let slotBarUnitsTree = {
  key = {}
  size = [slotBarUnitsTreeWidth, sh(100)]
  valign = ALIGN_BOTTOM
  onDetach = skipRemoveAnim
  children = [
    {
      size = [slotBarUnitsTreeWidth - saBorders[1], hdpx(2)]
      pos = [0, - slotBarTreeHeight - saBorders[1]]
      hplace = ALIGN_RIGHT
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0xFFD4D4D4
    }
    {
      size = [flex(), slotBarTreeHeight + saBorders[1]]
      padding = [slotBarUnitsTreePadding, 0, saBorders[1], saBorders[0]]
      rendObj = ROBJ_SOLID
      color = 0x40000000
      flow = FLOW_HORIZONTAL
      children = unitsTreePannable(@() {
        watch = [curSlots, newSlotPriceGold]
        flow = FLOW_HORIZONTAL
        gap = slotsGap
        children = curSlots.get().map(mkSlotCommon)
          .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get()))
      })
    }
  ]
  animations = wndSwitchAnim
}

function mkSlotSelect(slot, idx) {
  let { name = "" } = slot
  let unit = Computed(@() campMyUnits.get()?[name] ?? campUnitsCfg.get()?[name])
  let needClearDropZone = Computed(@() dropZoneSlotIdx.get() == idx)
  let isSelected = Computed(@() selectedTreeSlotIdx.get() == idx)
  let needTargetMarker = Computed(@() draggedData.get() != null && needClearDropZone.get())

  return @() {
    watch = [unit, needClearDropZone, needTargetMarker]
    key = $"select_slot_{idx}" 
    valign = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    children = [
      mkSlotHeader(slot, idx, Computed(@() selectedTreeSlotIdx.get() == idx))
      {
        children = [
          unit.get() == null || needClearDropZone.get()
            ? emptySelectSlotTree(idx)
            : mkUnitSlot(unit.get(), idx, @() setUnitToSlot(idx), isSelected)
          unit.get() ? null
            : {
                key = idx
                size = const [flex(), ph(70)]
                rendObj = ROBJ_IMAGE
                vplace = ALIGN_TOP
                image = highlightEmptySearch
                transform = {}
                opacity = 0
                animations = [{ prop = AnimProp.opacity, from = 0.0, to = 0.3, duration = 1,
                  play = true, easing = CosineFull, loop = true, loopPause = 1 }]
              }
          needTargetMarker.get() ? dropBorderMarker : null
        ]
      }
    ]
  }
}

let slotBarSelectWnd = @() {
  watch = [curSlots, newSlotPriceGold]
  key = "slotBarSelectWnd"
  size = const [sw(100), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  onAttach = @() slotBarSelectWndAttached.set(true)
  function onDetach() {
    slotBarSelectWndAttached.set(false)
    skipRemoveAnim()
  }
  flow = FLOW_HORIZONTAL
  padding = [hdpx(10), hdpx(10), 0, saBorders[0]]
  gap = slotsGap
  children = curSlots.get().map(mkSlotSelect)
    .append(newSlotPriceGold.get() == null ? null : slotToPurchase(newSlotPriceGold.get()))
}

return {
  slotBarMainMenu
  slotBarSize
  slotBarMainMenuSize
  slotBarUnitsTree
  slotBarTreeHeight
  slotBarSelectWnd
  emptySlotText
  mkSlotHeader
}
