from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send
from "mission" import get_mission_time
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/clientState/missionState.nut" import hudCustomRules
from "%appGlobals/clientState/respawnStateBase.nut" import isRespawnInProgress, isRespawnStarted, respawnUnitInfo,
  timeToRespawn, respawnUnitItems, respawnsLeft, respawnsTotalInitial
from "%appGlobals/itemsState.nut" import SPARE
from "%appGlobals/unitConst.nut" import AIR
from "%appGlobals/unitPresentation.nut" import getUnitPresentation, getUnitName
from "%rGui/components/animGrowLines.nut" import mkAnimGrowLines, mkAGLinesCfgOrdered
from "%rGui/components/buttonStyles.nut" import defButtonHeight, BATTLE, INACTIVE
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, mkCurrencyImage
from "%rGui/components/currencyStyles.nut" import CS_RESPAWN, CS_GAMERCARD
from "%rGui/components/infoButton.nut" import infoTooltipButton
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/selectedLineUnits.nut" import selLineSize
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonCommon, mkCustomButton, iconButtonPrimary, mkButtonTextMultiline
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/hud/localMPlayer.nut" import mySpawnScore
from "%rGui/hud/menuButton.nut" import mkMenuButton
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType, scoreBoardHeight
from "%rGui/hud/weaponsButtonsAnimations.nut" import mkConsumableSpend
from "%rGui/hudHints/hintBlocks.nut" import logerrHintsBlock
from "%rGui/respawn/bulletsChoiceState.nut" import bulletsToSpawn, hasLowBullets, hasZeroBullets, chosenBullets,
  hasChangedCurSlotBullets, hasZeroMainBullets
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
import "%rGui/respawn/respawnAirWeaponry.nut" as respawnAirWeaponry
from "%rGui/respawn/respawnAnimState.nut" import slotAABB, selSlotLinesSteps, lineSpeed
import "%rGui/respawn/respawnBullets.nut" as respawnBullets
from "%rGui/respawn/respawnComps.nut" import bg, headerText, headerHeight, header, gap, contentOffset, unitListHeight,
  skinPadding
from "%rGui/respawn/respawnMap.ui.nut" import respawnMap, visibleRespawnBases
from "%rGui/respawn/respawnSkins.nut" import respawnSkins, skinSize, skinGap
from "%rGui/respawn/respawnState.nut" import isRespawnAttached, respawnSlots, respawn, cancelRespawn,
  selSlotContentGenId, selSlot, selSlotUnitType, playerSelectedSlotIdx, sparesNum, unitListScrollHandler, hasSkins,
  needRespawnSlotsAndWeaponry, spawnScoreCosts, isUseSpawnScore
from "%rGui/respawn/spawnScore.nut" import mkSpawnScore, spawnScoreBalance
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import markTextColor, badTextColor2, textColor, commonTextColor
from "%rGui/tooltip.nut" import mkTooltipText
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateSmall, mkUnitBg, mkUnitSelectedGlow, mkPlateText,
  mkUnitLevel, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitSlotLockedByQuests, mkUnitSelectedUnderline,
  mkUnitInfo, plateTextsSmallPad
from "%rGui/unit/unitSettings.nut" import mkWeaponPreset
from "%rGui/unit/unitWeaponPresetsWnd.nut" import openUnitWeaponPresetWnd
from "%rGui/unitMods/equippedSecondaryWeapons.nut" import getEquippedWeapon
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitWeaponSlots


const MAX_DEF_SLOTS = 4

const mapMaxSize = hdpx(610)
let unitListGradientSize = [gap, saBorders[1]]
const scoreIconSize = hdpxi(30)
const tooltipIconSize = hdpxi(32)

const lockColor = 0xFF9C9EA0
const destroyedColor = 0xFFEE5353

let needCancel = Computed(@() isRespawnStarted.get() && !isRespawnInProgress.get() && respawnSlots.get().len() > 1)
let showLowBulletsWarning = Watched(true)
let startRespawnTime = mkWatched(persist, "startRespawnTime", -1)
isRespawnStarted.subscribe(function(v) {
  if (v)
    startRespawnTime.set(get_mission_time())
})
let needSpareBalance = Computed(@() !!hudCustomRules.get()?.allowSpare && !!respawnUnitItems.get()?.spare)

let spareBalance = @() {
  watch = sparesNum
  children = [
    mkCurrencyComp(sparesNum.get(), SPARE)
    mkConsumableSpend(SPARE, hdpx(20), hdpx(80), @(count) sparesNum.set(sparesNum.get() - count))
  ]
}



let balanceBlock = @() {
  watch = needSpareBalance
  size = FLEX_V
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    spawnScoreBalance
    needSpareBalance.get() ? spareBalance : null
  ]
}

let topPanel = {
  size = [FLEX, scoreBoardHeight]
  children = [
    { size = FLEX_V, children = logerrHintsBlock }
    @() {
      watch = scoreBoardType
      size = FLEX
      children = scoreBoardCfgByType?[scoreBoardType.get()].comp
    }
    mkMenuButton(1.0, { onClick = @() eventbus_send("openFlightMenuInRespawn", {}) })
    balanceBlock
  ]
}

function onSlotClick(slot) {
  
  sendPlayerActivityToServer()
  if (slot.canSpawn) {
    playerSelectedSlotIdx.set(slot.id)
    return
  }
  let name = colorize(markTextColor, getUnitName(slot.name))
  openMsgBox((slot?.reqLevel ?? 0) > 0 ? { text  = loc("msg/requirePlatoonLevel", { level = slot.reqLevel, name }) }
    : slot?.isLocked ? { text  = loc("msg/requireUnlockByQuests", { name }) }
    : { text  = loc("msg/unitAlreadyUsedInBattle", { name }) })
}

let sparePrice = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  padding = const [hdpx(10), hdpx(20), 0, 0]
  children = mkCurrencyImage(SPARE, CS_RESPAWN.iconSize)
}

let notEnoughScoreStyle = { color = badTextColor2 }
function mkSlotScorePrice(slot) {
  let { name, canSpawn } = slot
  if (!canSpawn)
    return null

  let score = Computed(@() spawnScoreCosts.get()?[name] ?? 0)
  let isEnough = Computed(@() score.get() <= mySpawnScore.get())
  return @() {
    watch = [score, isEnough]
    vplace = ALIGN_BOTTOM
    margin = [ 0, 0, plateTextsSmallPad, plateTextsSmallPad ]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(5)
    children = score.get() <= 0 ? null
      : [
          {
            size = scoreIconSize
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#icon_spawn_points.svg:{scoreIconSize}:P")
            keepAspect = true
          }
          mkPlateText(score.get(), isEnough.get() ? {} : notEnoughScoreStyle)
        ]
  }
}

function mkSlotPlate(slot, baseUnit) {
  let p = getUnitPresentation(slot.name)
  let isSelected = Computed(@() selSlot.get()?.id == slot.id)
  let unit = baseUnit.__merge(slot)
  let { canSpawn, isSpawnBySpare, mRank } = slot
  return {
    key = slot
    behavior = Behaviors.Button
    onClick = @() onSlotClick(slot)
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkUnitSelectedUnderline(unit, isSelected, { margin = 0, size = [FLEX, selLineSize] })
      {
        size = unitPlateSmall
        children = [
          mkUnitBg(unit, !canSpawn)
          canSpawn ? mkUnitSelectedGlow(unit, isSelected) : null
          mkUnitImage(unit, !canSpawn)
          mkUnitTexts(unit, loc(p.locId), !canSpawn)
          mkSlotScorePrice(slot)
          unit.rewardedMasteryTier > 0 ? mkUnitLevel(unit.level, unit.rewardedMasteryTier) : null
          canSpawn
              ? mkUnitInfo(mRank == 0 ? baseUnit : unit, { padding = [0, plateTextsSmallPad * 2, 0, 0] })
            : slot?.isLocked && (slot?.reqLevel ?? 0) <= 0
              ? unitSlotLockedByQuests
            : mkUnitSlotLockedLine(slot)
          canSpawn && isSpawnBySpare ? sparePrice : null
        ]
      }
    ]
  }
}

let mkRespToolipText = @(text) mkTooltipText(text).__update(fontTinyAccented, { color = commonTextColor })

let mkIcon = @(image) {
  size = tooltipIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{tooltipIconSize}:p")
  keepAspect = KEEP_ASPECT_FIT
}
let tankIcon = mkIcon("ui/gameuiskin#unit_tank.svg")
let spareIcon = mkIcon("ui/gameuiskin#shop_consumables_spare.svg")
let destroyedIcon = mkIcon("ui/gameuiskin#unit_tank.svg").__update({ color = destroyedColor })
let lockIcon = mkIcon("ui/gameuiskin#lock_icon.svg").__update({ size = hdpxi(30), color = lockColor })

let tankStackIcon = mkIcon("ui/gameuiskin#unit_tank_stack.svg").__update({ size = hdpxi(26) })
let spareStackIcon = mkIcon("ui/gameuiskin#shop_consumables_spare_stack.svg")
let destroyedStackIcon = mkIcon("ui/gameuiskin#unit_tank_stack.svg").__update({ size = hdpxi(26), color = destroyedColor })
let lockStackIcon = mkIcon("ui/gameuiskin#lock_icon_stack.svg").__update({ size = hdpxi(30), color = lockColor })

let mkTooltipRow = @(iconComp, text) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    iconComp
    mkRespToolipText(text)
  ]
}

function tooltipContentCtor() {
  sendPlayerActivityToServer()
  let { allowSpare = false } = hudCustomRules.get()
  let res = {
    flow = FLOW_VERTICAL
    children = [
      mkTooltipRow(tankIcon, loc("respawn/spawnsCounter/type/available"))
      allowSpare ? mkTooltipRow(spareIcon, loc("respawn/spawnsCounter/type/spare")) : null
      mkTooltipRow(destroyedIcon, loc("respawn/spawnsCounter/type/destroyed"))
      mkTooltipRow(lockIcon, loc("respawn/spawnsCounter/type/notAvailable"))
    ]
  }

  let unitsLeft = min(respawnsLeft.get(), respawnSlots.get().filter(@(slot) slot.canSpawn && !slot.isSpawnBySpare).len())
  let hasMaxSlots = respawnSlots.get().len() >= min(respawnsTotalInitial.get(), MAX_DEF_SLOTS)
  let hasEnoughSpares = !allowSpare || (sparesNum.get() >= (respawnsLeft.get() - unitsLeft))
  if (hasMaxSlots && hasEnoughSpares)
    return res

  let hint = !hasMaxSlots && !hasEnoughSpares ? loc("respawn/spawnsCounter/tooltip/all")
    : !allowSpare ? loc("respawn/spawnsCounter/tooltip/unit")
    : !hasMaxSlots ? loc("respawn/spawnsCounter/tooltip/unitNoSpare")
    : hasEnoughSpares ? loc("respawn/spawnsCounter/tooltip/unit")
    : loc("respawn/spawnsCounter/tooltip/spare")
  res.children.append(mkRespToolipText("".concat("\n\n", colorize(textColor, hint))))
  return res
}

let mkStack = @(amount, baseIconComp, stackIconComp, contentGap) {
  flow = FLOW_HORIZONTAL
  gap = contentGap
  valign = ALIGN_CENTER
  children = amount == 1 ? baseIconComp
    : [
        baseIconComp
        {
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = contentGap - hdpx(4)
          children = array(amount - 1).map(@(_) stackIconComp)
        }
      ]
}

function mkDoubleStack(amount, baseIconComp, stackIconComp, secAmount, secBaseIconComp, secStackIconComp, contentGap) {
  let iconComp = amount == 0 ? secBaseIconComp : baseIconComp
  return {
    flow = FLOW_HORIZONTAL
    gap = contentGap
    valign = ALIGN_CENTER
    children = amount + secAmount <= 1 ? iconComp
      : [
          iconComp
          {
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = contentGap - hdpx(4)
            children = [].extend(
              amount > 1 ? array(amount - 1).map(@(_) stackIconComp) : [],
              secAmount > 1 && amount == 0 ? array(secAmount - 1).map(@(_) secStackIconComp)
                : secAmount > 0 ? array(secAmount).map(@(_) secStackIconComp)
                : []
            )
          }
        ]
  }
}

let slotsBlockTitle = @(unit, respSlots) function() {
  let { unitType = "" } = unit
  let hasSpawnCounter = !isUseSpawnScore.get() && respawnsTotalInitial.get() > 0
  let text = hasSpawnCounter ? loc("respawn/spawnsCounter")
    : unitType == "" ? ""
    : loc($"respawn/squad/{unitType}")
  if (!hasSpawnCounter)
    return header(headerText(text), { watch = [respawnsTotalInitial, isUseSpawnScore] })

  let unitsLeft = min(respawnsLeft.get(),
    respSlots.filter(@(slot) slot.canSpawn && !slot.isSpawnBySpare).len())
  let sparesLeft = !hudCustomRules.get()?.allowSpare ? 0
    : min(respawnsLeft.get() - unitsLeft, sparesNum.get(),
        unitsLeft + respSlots.filter(@(slot) slot.canSpawn && slot.isSpawnBySpare).len())
  let unitsDestroyed = respawnsTotalInitial.get() - respawnsLeft.get()
  let unitsNotAvailable = respawnsLeft.get() - unitsLeft - sparesLeft

  return header(
    {
      size = FLEX
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = hdpx(10)
      gap
      children = [
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          halign = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          children = [
            headerText(text).__update({ size = FLEX_H, hplace = ALIGN_LEFT, halign = ALIGN_LEFT })
            infoTooltipButton(tooltipContentCtor, {}, { onClick = @() sendPlayerActivityToServer() })
          ]
        }
        {
          size = FLEX
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = FLEX }
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = [
                unitsLeft <= 0 && unitsDestroyed <= 0 ? null
                  : mkDoubleStack(unitsLeft, tankIcon, tankStackIcon,
                      unitsDestroyed, destroyedIcon, destroyedStackIcon, -hdpx(5))
                sparesLeft <= 0 ? null
                  : mkStack(sparesLeft, spareIcon, spareStackIcon, -hdpx(13))
              ].filter(@(v) v != null)
            }
            {
              flow = FLOW_HORIZONTAL
              children = unitsNotAvailable <= 0 ? null
                : mkStack(unitsNotAvailable, lockIcon, lockStackIcon, -hdpx(15))
            }
          ]
        }
      ]
    }
    {
      watch = [respawnsTotalInitial, sparesNum, isUseSpawnScore, respawnsLeft, hudCustomRules],
      size = const [FLEX, hdpx(100)]
    })
}

let pannableArea = verticalPannableAreaCtor(unitListHeight + unitListGradientSize[0] + unitListGradientSize[1],
  unitListGradientSize)

function slotsBlock() {
  let title = slotsBlockTitle(respawnUnitInfo.get(), respawnSlots.get())
  let list = respawnSlots.get().map(@(slot) mkSlotPlate(slot, respawnUnitInfo.get()))
  return {
    watch = [respawnSlots, respawnUnitInfo]
    size = [unitPlateSmall[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap
    children = respawnUnitInfo.get() == null ? null
      : list.len() <= MAX_DEF_SLOTS ? [ title ].extend(list)
      : [
          title
          {
            size = [FLEX, unitListHeight]
            children = [
              pannableArea(
                {
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  gap
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

let map = @() {
  watch = visibleRespawnBases
  size = FLEX_H
  maxHeight = mapMaxSize + headerHeight + gap
  maxWidth = mapMaxSize
  flow = FLOW_VERTICAL
  gap
  children = [
    visibleRespawnBases.get().len() > 0 ? header(headerText(loc("respawn/choose_respawn_point"))) : null
    bg.__merge({
      size = const [FLEX, pw(100)]
      padding = gap
      children = respawnMap
    })
  ]
}

function cancelBtn() {
  local btnText = loc("Cancel")
  if (timeToRespawn.get() > 0)
    btnText = "".concat(btnText,
      loc("ui/parentheses/space", {
        text = $"{timeToRespawn.get()}{loc("mainmenu/seconds")}" }))
  return {
    watch = timeToRespawn
    children = textButtonCommon(utf8ToUpper(btnText), cancelRespawn, { hotkeys = [btnBEscUp] })
  }
}

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny, override)

let skinsList = @() {
  watch = hasSkins
  children = !hasSkins.get() ? null : {
    flow = FLOW_VERTICAL
    gap
    children = [
      header(headerText(loc("skins/select")))
      {
        size = [((skinSize + skinGap) * 4 - skinGap) + skinPadding * 2, skinSize + skinPadding * 2]
        padding = skinPadding
        rendObj = ROBJ_SOLID
        color = 0x99000000
        clipChildren = true
        children = {
          size = FLEX
          behavior = Behaviors.Pannable
          touchMarginPriority = TOUCH_BACKGROUND
          skipDirPadNav = true
          xmbNode = XmbContainer()
          children = respawnSkins
        }
      }
    ]
  }
}

let vehicleActionLangKeys = {
  [AIR] = "mainmenu/flightAgain"
}

function toBattleButton(onClick, styleOvr) {
  let needShowSpareDesc = Computed(@() selSlot.get()?.isSpawnBySpare ?? false)
  let spawnCost = Computed(@() spawnScoreCosts.get()?[selSlot.get()?.name] ?? 0)
  let btnStyle = Computed(@() isUseSpawnScore.get() && spawnCost.get() > mySpawnScore.get() ? INACTIVE : BATTLE)
  return @() {
    watch = [selSlotUnitType, needShowSpareDesc, spawnCost, btnStyle]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap
    children = [
      skinsList
      {
        flow = FLOW_VERTICAL
        gap
        halign = ALIGN_CENTER
        children = [
          needShowSpareDesc.get()
            ? mkText(utf8ToUpper(loc(vehicleActionLangKeys?[selSlotUnitType.get()] ?? "mainmenu/driveAgain")))
            : null
          mkCustomButton({
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              gap = hdpx(5)
              children = [
                mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/toBattle/short")), fontBoldTinyAccentedShaded)
                needShowSpareDesc.get() ? mkCurrencyComp(1, SPARE, CS_GAMERCARD) : null
                spawnCost.get() <= 0 ? null : mkSpawnScore(spawnCost.get(), CS_GAMERCARD)
              ]
            },
            onClick,
            btnStyle.get().__merge(styleOvr))
        ]
      }
    ]
  }
}

function toBattle() {
  if (chosenBullets.get().len() == 0) 
    respawn(selSlot.get(), bulletsToSpawn.get())
  else if (hasZeroBullets.get())
    openMsgBox({ text = loc("respawn/zero_ammo") })
  else if (hasZeroMainBullets.get())
    openMsgBox({ text = loc("respawn/zero_main_ammo") })
  else if (hasLowBullets.get() && hasChangedCurSlotBullets.get() && showLowBulletsWarning.get()) {
    openMsgBox({
      text = loc("respawn/low_ammo")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = utf8ToUpper(loc("mainmenu/toBattle/short")), styleId = "BATTLE",
          cb = @() respawn(selSlot.get(), bulletsToSpawn.get()) }
      ]
    })
    showLowBulletsWarning.set(false)
  }
  else
    respawn(selSlot.get(), bulletsToSpawn.get())
}

function showSpawnScoreMsgIfNeed() {
  if (!isUseSpawnScore.get())
    return false
  let cost = spawnScoreCosts.get()?[selSlot.get()?.name] ?? 0
  if (cost <= mySpawnScore.get())
    return false
  openMsgBox({ text = loc("multiplayer/noSpawnScore", { cost = colorize(markTextColor, cost) }) })
  return true
}

function checkAndBattle() {
  if (showSpawnScoreMsgIfNeed())
    return

  if (selSlot.get()?.unitClass != "bomber")
    return toBattle()

  let allWSlots = loadUnitWeaponSlots(selSlot.get()?.name)
  let { weaponPreset, setWeaponPreset } = mkWeaponPreset(Watched(selSlot.get().name))
  let equippedWeaponsBySlots = allWSlots.map(@(wSlot, idx) getEquippedWeapon(
      weaponPreset.get(),
      idx,
      wSlot?.wPresets ?? {},
      selSlot.get()?.mods))
  let isEmpty = equippedWeaponsBySlots.filter(@(s, idx) s != null && idx != 0).len() == 0

  if (!isEmpty)
    return toBattle()

  openMsgBox({
    text = loc("weapons/secondaryWeaponNotSet")
    buttons = [
      { text = loc("btn/doNotSet"),
        isCancel = true
        cb = toBattle
      }
      {
        text = loc("btn/setDefault"),
        function cb() {
          let preset = equippedWeaponsBySlots.map(
            @(equippedWeapon, idx) equippedWeapon != null ? equippedWeapon.name
              : (allWSlots[idx].wPresets.findvalue(@(w) w.isDefault)?.name ?? ""))
          setWeaponPreset(preset)
          toBattle()
        }
        styleId = "PRIMARY",
        multiLine = true
      }
    ]
  })
}

let buttons = @() {
  watch = [needCancel, isRespawnStarted, selSlot, selSlotUnitType, isGamepad]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap
  children = [
    selSlotUnitType.get() != AIR ? null
      : iconButtonPrimary("ui/gameuiskin#icon_weapon_preset.svg", @() openUnitWeaponPresetWnd(selSlot.get()), {
        ovr = {
          size = isGamepad.get()
            ? [defButtonHeight * 2, defButtonHeight]
            : [defButtonHeight, defButtonHeight]
          minWidth = defButtonHeight
        }
        hotkeys = ["^J:Y | Enter"]
      }),
    !(selSlot.get()?.canSpawn ?? false) ? null
      : !isRespawnStarted.get() ? toBattleButton(checkAndBattle, { hotkeys = ["^J:X | Enter"] })
      : needCancel.get() ? cancelBtn
      : spinner
  ]
}

let rightBlock = {
  size = FLEX
  halign = ALIGN_RIGHT
  margin = const [0, 0, 0, hdpx(20)]
  children = [
    map
    buttons
  ]
}

let updateSlotAABB = @() slotAABB.set(selSlot.get() == null ? null
  : gui_scene.getCompAABBbyKey(selSlot.get()))
selSlot.subscribe(@(_) deferOnce(updateSlotAABB))

let weaponryBlockByUnitType = {
  [AIR] = respawnAirWeaponry,
}

let respawnBulletsPlace = @() {
  watch = [slotAABB, selSlotUnitType, selSlot]
  size = FLEX_V
  onAttach = @() deferOnce(updateSlotAABB)
  children = {
    key = slotAABB.get()
    onAttach = @() selSlotContentGenId.set(selSlotContentGenId.get() + 1)
    children = selSlotUnitType.get() == null ? null
      : (weaponryBlockByUnitType?[selSlotUnitType.get()](selSlot.get()) ?? respawnBullets)
  }
}

let content = @() {
  watch = needRespawnSlotsAndWeaponry
  key = "respawnWndContent"
  size = FLEX
  flow = FLOW_HORIZONTAL
  children = !needRespawnSlotsAndWeaponry.get() ? null
    : [
        slotsBlock
        respawnBulletsPlace
        rightBlock
      ]
}

let animLines = @() {
  watch = selSlotLinesSteps
  size = FLEX
  children = selSlotLinesSteps.get() == null ? null
    : mkAnimGrowLines(mkAGLinesCfgOrdered(selSlotLinesSteps.get(), lineSpeed))
}

return bgShaded.__merge({
  key = {}
  size = FLEX
  onAttach = @() isRespawnAttached.set(true)
  onDetach = @() isRespawnAttached.set(false)
  children = [
    {
      size = FLEX
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
