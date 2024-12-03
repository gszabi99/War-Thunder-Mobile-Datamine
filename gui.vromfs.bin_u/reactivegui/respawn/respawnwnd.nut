from "%globalsDarg/darg_library.nut" import *
let { get_mission_time } = require("mission")
let { eventbus_send } = require("eventbus")
let { round, sqrt } = require("math")
let { deferOnce } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isRespawnAttached, respawnSlots, respawn, cancelRespawn, selSlotContentGenId,
  selSlot, selSlotUnitType, playerSelectedSlotIdx, sparesNum, unitListScrollHandler
} = require("respawnState.nut")
let { bulletsToSpawn, hasLowBullets, hasZeroBullets, chosenBullets, hasChangedCurSlotBullets, hasZeroMainBullets
} = require("bulletsChoiceState.nut")
let { slotAABB, selSlotLinesSteps, lineSpeed } = require("respawnAnimState.nut")
let { isRespawnInProgress, isRespawnStarted, respawnUnitInfo, timeToRespawn, respawnUnitItems,
  hasRespawnSeparateSlots, hasPredefinedReward, dailyBonus
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitPresentation, getPlatoonName, getUnitClassFontIcon, getUnitLocId
} = require("%appGlobals/unitPresentation.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { collectibleTextColor, premiumTextColor, markTextColor } = require("%rGui/style/stdColors.nut")
let mkMenuButton = require("%rGui/hud/mkMenuButton.nut")
let { textButtonCommon, textButtonBattle, iconButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { scoreBoard, scoreBoardHeight } = require("%rGui/hud/scoreBoard.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitPrice, mkUnitBg, mkUnitSelectedGlow,
  mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitSlotLockedByQuests,
  mkUnitSelectedUnderline, mkUnitInfo, unitPlatesGap, plateTextsSmallPad,
  mkUnitDailyBonus
} = require("%rGui/unit/components/unitPlateComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { logerrHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { mkLevelBg, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let respawnMap = require("respawnMap.ui.nut")
let respawnBullets = require("respawnBullets.nut")
let respawnAirWeaponry = require("respawnAirWeaponry.nut")
let { bg, headerText, headerHeight, header, gap, headerMarquee, bulletsBlockMargin, bulletsBlockWidth,
  contentOffset, unitListHeight
} = require("respawnComps.nut")
let { mkAnimGrowLines, mkAGLinesCfgOrdered } = require("%rGui/components/animGrowLines.nut")
let { SPARE } = require("%appGlobals/itemsState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkConsumableSpend } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { respawnSkins, skinSize } = require("respawnSkins.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { openUnitWeaponPresetWnd } = require("%rGui/unit/unitWeaponPresetsWnd.nut")
let { sendPlayerActivityToServer } = require("playerActivity.nut")
let { selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { CS_RESPAWN } = require("%rGui/components/currencyStyles.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")


let mapMaxSize = hdpx(650)
let levelHolderSize = evenPx(84)
let unitListGradientSize = [unitPlatesGap, saBorders[1]]
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2
let skinTextHeight = hdpx(45)
let skinPadding = hdpx(10)
let marginBottom = hdpx(50)

let hasSkins = Computed(@() (selSlot.get()?.skins.len() ?? 0) > 0)
let needCancel = Computed(@() isRespawnStarted.value && !isRespawnInProgress.value && respawnSlots.value.len() > 1)
let showLowBulletsWarning = Watched(true)
let startRespawnTime = mkWatched(persist, "startRespawnTime", -1)
isRespawnStarted.subscribe(function(v) {
  if (v)
    startRespawnTime(get_mission_time())
})

let balanceBlock = @() {
  watch = sparesNum
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  size = [SIZE_TO_CONTENT, flex()]
  children = [
    mkCurrencyComp(sparesNum.value, SPARE)
    mkConsumableSpend(SPARE, hdpx(20), hdpx(80), @(count) sparesNum.set(sparesNum.get() - count))
  ]
}

let topPanel = @() {
  size = [flex(), scoreBoardHeight]
  watch = respawnUnitItems
  children = [
    { size = [SIZE_TO_CONTENT, flex()], children = logerrHintsBlock }
    scoreBoard
    mkMenuButton({ onClick = @() eventbus_send("openFlightMenuInRespawn", {}) })
    respawnUnitItems.value?.spare ? balanceBlock : null
  ]
}

function onSlotClick(slot) {
  //todo: validate spawn here
  sendPlayerActivityToServer()
  if (slot.canSpawn) {
    playerSelectedSlotIdx(slot.id)
    return
  }
  let name = colorize(markTextColor, loc(getUnitLocId(slot.name)))
  openMsgBox((slot?.reqLevel ?? 0) > 0 ? { text  = loc("msg/requirePlatoonLevel", { level = slot.reqLevel, name }) }
    : slot?.isLocked ? { text  = loc("msg/requireUnlockByQuests", { name }) }
    : { text  = loc("msg/unitAlreadyUsedInBattle", { name }) })
}

let sparePrice = {
  hplace = ALIGN_RIGHT
  halign = ALIGN_TOP
  padding = [hdpx(20), hdpx(20), 0, 0]
  children = mkUnitPrice({
    fullPrice = 1,
    price = 1,
    currencyId = SPARE
  }, null, CS_RESPAWN)
}

function mkSlotPlate(slot, baseUnit) {
  let p = getUnitPresentation(slot.name)
  let isSelected = Computed(@() selSlot.value?.id == slot.id)
  let unit = baseUnit.__merge(slot)
  let { canSpawn, isSpawnBySpare, country, mRank } = slot
  return @() {
    watch = hasRespawnSeparateSlots
    key = slot
    behavior = Behaviors.Button
    onClick = @() onSlotClick(slot)
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkUnitSelectedUnderline(unit, isSelected, null,
        {
          margin = 0
          size = [flex(), selLineSize]
        })
      {
        size = [unitPlateWidth, unitPlateHeight]
        children = [
          mkUnitBg(unit, !canSpawn)
          canSpawn ? mkUnitSelectedGlow(unit, isSelected) : null
          mkUnitImage(unit, !canSpawn)
          mkUnitTexts(country == "" ? baseUnit : unit, loc(p.locId), !canSpawn)
          canSpawn
              ? mkUnitInfo(mRank == 0 ? baseUnit : unit, { padding = [0, plateTextsSmallPad * 2, 0, 0] })
            : slot?.isLocked && (slot?.reqLevel ?? 0) <= 0
              ? unitSlotLockedByQuests
            : mkUnitSlotLockedLine(slot)
          canSpawn && isSpawnBySpare ? sparePrice : null
          unit?.hasDailyBonus || (!hasRespawnSeparateSlots.get() && baseUnit?.hasDailyBonus)
            ? mkUnitDailyBonus(Computed(@() !hasPredefinedReward.get()), Computed(@() dailyBonus.get()?.wpMul ?? 1),
              Computed(@() dailyBonus.get()?.expMul ?? 1))
            : null
        ]
      }
    ]
  }
}

let levelBg = mkLevelBg({
  ovr = { size = [ rhombusSize, rhombusSize ] }
  childOvr = { borderColor = unitExpColor }
})

function slotsBlockTitle(unit, isSeparateSlots) {
  if (isSeparateSlots) {
    let { unitType = "" } = unit
    let text = unitType == "" ? "" : loc($"respawn/squad/{unitType}")
    return header({
      valign = ALIGN_CENTER
      children = headerText(text)
    })
  }
  let { name, level = 0, isCollectible = false, isPremium = false, isUpgraded = false } = unit
  let isElite = isPremium || isUpgraded
  let text = "  ".concat(getPlatoonName(name, loc), getUnitClassFontIcon(unit))
  let textLength = calc_str_box(text, fontTinyAccented)[0]
  let textWidth = unitPlateWidth - levelHolderSize
  let textColorOvr = isCollectible ? { color = collectibleTextColor }
    : isElite ? { color = premiumTextColor }
    : {}
  let textComp = headerText(text).__update(
    textLength > textWidth ? headerMarquee(textWidth - hdpx(20)) : {},
    { margin = [0, hdpx(20), 0, 0] },
    textColorOvr
  )
  return header({
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      level < 0 ? null : {
        size = [ levelHolderSize, levelHolderSize ]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          levelBg
          {
            rendObj = ROBJ_TEXT
            text = level
            color = 0xFFFFFFFF
          }.__update(fontSmall)
        ]
      }
      textComp
    ]
  })
}

let pannableArea = verticalPannableAreaCtor(unitListHeight + unitListGradientSize[0] + unitListGradientSize[1],
  unitListGradientSize)

function slotsBlock() {
  let title = slotsBlockTitle(respawnUnitInfo.get(), hasRespawnSeparateSlots.get())
  let list = respawnSlots.value.map(@(slot) mkSlotPlate(slot, respawnUnitInfo.value))
  return {
    watch = [respawnSlots, respawnUnitInfo, hasRespawnSeparateSlots]
    size = [unitPlateWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = unitPlatesGap
    children = respawnUnitInfo.value == null ? null
      : list.len() <= 4 ? [ title ].extend(list)
      : [
          title
          {
            size = [flex(), unitListHeight]
            children = [
              pannableArea(
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  flow = FLOW_VERTICAL
                  gap = unitPlatesGap
                  children = list
                },
                {},
                { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler = unitListScrollHandler })
              mkScrollArrow(unitListScrollHandler, MR_B, scrollArrowImageSmall,
                { vplace = ALIGN_TOP, pos = [0, unitListHeight] })
            ]
          }
        ]
  }
}

let map = {
  size = [flex(), SIZE_TO_CONTENT]
  maxHeight = mapMaxSize + headerHeight + gap
  maxWidth = mapMaxSize
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = [
    header(headerText(loc("respawn/choose_respawn_point")))
    bg.__merge({
      size = [flex(), pw(100)]
      padding = gap
      children = respawnMap
    })
  ]
}

let cancelText = utf8ToUpper(loc("Cancel"))
function cancelBtn() {
  local btnText = cancelText
  if (timeToRespawn.value > 0)
    btnText = "".concat(btnText,
      loc("ui/parentheses/space", {
        text = $"{timeToRespawn.value}{loc("mainmenu/seconds")}" }))
  return {
    watch = timeToRespawn
    children = textButtonCommon(btnText, cancelRespawn, { hotkeys = [btnBEscUp] })
  }
}

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny, override)

let vehicleActionLangKeys = {
  [AIR] = "mainmenu/flightAgain"
}

function toBattleButton(onClick, styleOvr) {
  let button = textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")), onClick, styleOvr)
  if (!(selSlot.value?.isSpawnBySpare ?? false))
    return button
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = [
      @() {
        watch = selSlotUnitType
        size = [SIZE_TO_CONTENT, flex()]
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        children = [
          mkText(utf8ToUpper(loc(vehicleActionLangKeys?[selSlotUnitType.get()] ?? "mainmenu/driveAgain")))
          mkCurrencyComp(1, SPARE)
        ]
      }
      button
    ]
  }
}

function toBattle() {
  if (chosenBullets.value.len() == 0) //no need to validate bullets count when no bullets choice at all
    respawn(selSlot.value, bulletsToSpawn.value)
  else if (hasZeroBullets.value)
    openMsgBox({ text = loc("respawn/zero_ammo") })
  else if (hasZeroMainBullets.get())
    openMsgBox({ text = loc("respawn/zero_main_ammo") })
  else if (hasLowBullets.value && hasChangedCurSlotBullets.value && showLowBulletsWarning.value) {
    openMsgBox({
      text = loc("respawn/low_ammo")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = utf8ToUpper(loc("mainmenu/toBattle/short")), styleId = "BATTLE",
          cb = @() respawn(selSlot.value, bulletsToSpawn.value) }
      ]
    })
    showLowBulletsWarning(false)
  }
  else
    respawn(selSlot.value, bulletsToSpawn.value)
}

let buttons = @() {
  watch = [needCancel, isRespawnStarted, selSlot, selSlotUnitType, isGamepad]
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    selSlotUnitType.get() != AIR ? null
      : iconButtonPrimary("ui/gameuiskin#icon_weapon_preset.svg", @() openUnitWeaponPresetWnd(selSlot.get()), {
        ovr = { size = isGamepad.get() ? [SIZE_TO_CONTENT, defButtonHeight] : [defButtonHeight, defButtonHeight], minWidth = defButtonHeight }
      }),
    !(selSlot.get()?.canSpawn ?? false) ? null
      : !isRespawnStarted.get() ? toBattleButton(toBattle, { hotkeys = ["^J:X | Enter"] })
      : needCancel.get() ? cancelBtn
      : spinner
  ]
}

let rightBlock = {
  size = flex()
  halign = ALIGN_RIGHT
  margin = [0, 0, 0, hdpx(50)]
  children = [
    map
    buttons
  ]
}

let updateSlotAABB = @() slotAABB(selSlot.value == null ? null
  : gui_scene.getCompAABBbyKey(selSlot.value))
selSlot.subscribe(@(_) deferOnce(updateSlotAABB))

let weaponryBlockByUnitType = {
  [AIR] = respawnAirWeaponry,
}

let isFixedPositionByUnitType = {
  [AIR] = true
}

function calcPos(content, contentAABB, slotAABBV, hasSkinsBlock) {
  let size = calc_comp_size(content)
  let posY = (slotAABBV.t + slotAABBV.b - size[1]) / 2  - contentAABB.t
  let maxY = max(0, contentAABB.b - contentAABB.t - size[1] - marginBottom)
  let maxYWithSkins = max(0, contentAABB.b - contentAABB.t - size[1] - skinSize - skinTextHeight - skinPadding * 2 - hdpx(15))
  return [0, clamp(posY, 0, !hasSkinsBlock ? maxY : maxYWithSkins)]
}

function respawnBulletsPlace() {
  let res = { watch = [slotAABB, hasSkins, selSlotUnitType, selSlot], onAttach = @() deferOnce(updateSlotAABB) }
  if (slotAABB.value == null)
    return res
  let contentAABB = gui_scene.getCompAABBbyKey("respawnWndContent")
  if (contentAABB == null)
    return res

  let content = selSlotUnitType.get() == null ? null
    : (weaponryBlockByUnitType?[selSlotUnitType.get()](selSlot.get()) ?? respawnBullets)
  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = {
      key = slotAABB.value
      onAttach = @() selSlotContentGenId.set(selSlotContentGenId.get() + 1)
      pos = [0,
        (isFixedPositionByUnitType?[selSlotUnitType.get()] ?? false) ? 0
          : calcPos(content, contentAABB, slotAABB.get(), hasSkins.get())[1]
      ]
      children = content
    }
  })
}

let skinsList = @() {
  watch = hasSkins
  size = flex()
  valign = ALIGN_BOTTOM
  children = !hasSkins.get() ? null : {
    rendObj = ROBJ_SOLID
    color = 0x99000000
    pos = [bulletsBlockMargin, 0]
    padding = skinPadding
    flow = FLOW_VERTICAL
    children = [
      headerText(loc("skins/select"), { size = [SIZE_TO_CONTENT, skinTextHeight] })
      {
        size = [bulletsBlockWidth - skinPadding * 2, skinSize]
        clipChildren = true
        children = {
          size = flex()
          behavior = Behaviors.Pannable
          skipDirPadNav = true
          xmbNode = {
            canFocus = @() false
            scrollSpeed = 5.0
            isViewport = true
            scrollToEdge = true
            screenSpaceNav = true
          }
          children = respawnSkins
        }
      }
    ]
  }
}

let content = @() {
  watch = [respawnSlots, hasRespawnSeparateSlots]
  key = "respawnWndContent"
  size = flex()
  flow = FLOW_HORIZONTAL
  children = !hasRespawnSeparateSlots.get() && respawnSlots.get().len() <= 1 ? null
    : [
        slotsBlock
        {
          size = [SIZE_TO_CONTENT, flex()]
          children = [
            respawnBulletsPlace
            skinsList
          ]
        }
        rightBlock
      ]
}

let animLines = @() {
  watch = selSlotLinesSteps
  size = flex()
  children = selSlotLinesSteps.value == null ? null
    : mkAnimGrowLines(mkAGLinesCfgOrdered(selSlotLinesSteps.value, lineSpeed))
}

return bgShaded.__merge({
  key = {}
  size = flex()
  onAttach = @() isRespawnAttached(true)
  onDetach = @() isRespawnAttached(false)
  children = [
    {
      size = flex()
      padding = saBordersRv
      flow = FLOW_VERTICAL
      gap = contentOffset
      children = [
        topPanel
        content
      ]
    }
    animLines
  ]
  animations = wndSwitchAnim
})
