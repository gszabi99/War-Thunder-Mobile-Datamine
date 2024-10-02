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
  selSlot, selSlotUnitType, playerSelectedSlotIdx, sparesNum, unitListScrollHandler, canGoToBattle
} = require("respawnState.nut")
let { bulletsToSpawn, hasLowBullets, hasZeroBullets, chosenBullets, hasChangedCurSlotBullets
} = require("bulletsChoiceState.nut")
let { slotAABB, selSlotLinesSteps, lineSpeed } = require("respawnAnimState.nut")
let { isRespawnInProgress, isRespawnStarted, respawnUnitInfo, timeToRespawn, respawnUnitItems, respawnUnitSkins,
  hasRespawnSeparateSlots
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitPresentation, getPlatoonName, getUnitClassFontIcon, getUnitLocId
} = require("%appGlobals/unitPresentation.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { collectibleTextColor, premiumTextColor, markTextColor } = require("%rGui/style/stdColors.nut")
let mkMenuButton = require("%rGui/hud/mkMenuButton.nut")
let { textButtonCommon, textButtonBattle } = require("%rGui/components/textButton.nut")
let { scoreBoard, scoreBoardHeight } = require("%rGui/hud/scoreBoard.nut")
let { unitPlateWidth, unitPlateHeight, unitSelUnderlineFullSize, mkUnitPrice,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitSlotLockedByQuests,
  mkUnitSelectedUnderlineVert, mkUnitRank, unitPlatesGap, plateTextsSmallPad
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
let { sendPlayerActivityToServer } = require("playerActivity.nut")

let slotPlateWidth = unitPlateWidth + unitSelUnderlineFullSize
let mapMaxSize = hdpx(650)
let levelHolderSize = evenPx(84)
let unitListGradientSize = [unitPlatesGap, saBorders[1]]
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2
let skinTextHeight = hdpx(45)
let skinPadding = hdpx(10)

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
  if (canGoToBattle(slot, sparesNum.get() > 0)) {
    playerSelectedSlotIdx(slot.id)
    return
  }
  let name = colorize(markTextColor, loc(getUnitLocId(slot.name)))
  openMsgBox((slot?.reqLevel ?? 0) > 0 ? { text  = loc("msg/requirePlatoonLevel", { level = slot.reqLevel, name }) }
    : slot?.isLocked ? { text  = loc("msg/requireUnlockByQuests", { name }) }
    : { text  = loc("msg/unitAlreadyUsedInBattle", { name }) })
}

let sparePrice = {
  size = flex()
  children = mkUnitPrice({
    fullPrice = 1,
    price = 1,
    currencyId = SPARE
  })
}

let mkSlotPlateContent = @(slot, unit, baseUnit, p, isSelected) function() {
  let { isSpawnBySpare, country, mRank, isLocked = false, reqLevel = 0 } = slot
  let canBattle = canGoToBattle(slot, sparesNum.get() > 0)
  return {
    watch = sparesNum
    key = slot
    size = [unitPlateWidth, unitPlateHeight]
    children = [
      mkUnitBg(unit, !canBattle)
      canBattle ? mkUnitSelectedGlow(unit, isSelected) : null
      mkUnitImage(unit, !canBattle)
      mkUnitTexts(country == "" ? baseUnit : unit, loc(p.locId), !canBattle)
      canBattle
          ? mkUnitRank(mRank == 0 ? baseUnit : unit, { padding = [0, plateTextsSmallPad * 2, 0, 0] })
        : isLocked && reqLevel <= 0
          ? unitSlotLockedByQuests
        : mkUnitSlotLockedLine(slot)
      canBattle && isSpawnBySpare ? sparePrice : null
    ]
  }
}

function mkSlotPlate(slot, baseUnit) {
  let p = getUnitPresentation(slot.name)
  let isSelected = Computed(@() selSlot.value?.id == slot.id)
  let unit = baseUnit.__merge(slot)
  return {
    size = [slotPlateWidth, unitPlateHeight]
    behavior = Behaviors.Button
    onClick = @() onSlotClick(slot)
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(unit, isSelected)
      mkSlotPlateContent(slot, unit, baseUnit, p, isSelected)
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
  let textWidth = slotPlateWidth - levelHolderSize
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
    size = [slotPlateWidth, SIZE_TO_CONTENT]
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
  gap
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
  watch = [needCancel, isRespawnStarted, selSlot, sparesNum]
  vplace = ALIGN_BOTTOM
  children = !canGoToBattle(selSlot.get(), sparesNum.get() > 0) ? null
    : !isRespawnStarted.value ? toBattleButton(toBattle, { hotkeys = ["^J:X | Enter"] })
    : needCancel.value ? cancelBtn
    : spinner
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

function calcPos(content, contentAABB) {
  let size = calc_comp_size(content)
  let posY = (slotAABB.value.t + slotAABB.value.b - size[1]) / 2  - contentAABB.t
  let maxY = max(0, contentAABB.b - contentAABB.t - size[1])
  let maxYWithSkins = max(0, contentAABB.b - contentAABB.t - size[1] - skinSize - skinTextHeight - skinPadding * 2 - hdpx(15))
  return [0, clamp(posY, 0, !respawnUnitSkins.get() ? maxY : maxYWithSkins)]
}

function respawnBulletsPlace() {
  let res = { watch = [slotAABB, respawnUnitSkins, selSlotUnitType, selSlot], onAttach = @() deferOnce(updateSlotAABB) }
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
      pos = [0, (isFixedPositionByUnitType?[selSlotUnitType.get()] ?? false) ? 0 : calcPos(content, contentAABB)[1]]
      children = content
    }
  })
}

let skinsList = @() {
  watch = respawnUnitSkins
  size = flex()
  valign = ALIGN_BOTTOM
  children = !respawnUnitSkins.get() ? null : {
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
