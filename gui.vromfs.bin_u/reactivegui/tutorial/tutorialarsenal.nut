from "%globalsDarg/darg_library.nut" import *
let logT = log_with_prefix("[ARSENAL_TUTOR] ")
let { register_command } = require("console")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { isCampaignWithUnitsResearch, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots } = require("%appGlobals/pServer/slots.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { hasModalWindows, moveModalToTop } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial,
  activeTutorialId, WND_UID } = require("tutorialWnd/tutorialWndState.nut")
let { selectedSlotIdx, slotBarArsenalKey, slotBarSlotKey, visibleNewModsSlots } = require("%rGui/slotBar/slotBarState.nut")
let { curWeaponIdx, curBeltIdx, setCurSlotIdx, setCurBeltsWeaponIdx, isUnitModSlotsAttached, openUnitModsSlotsWndByName,
  slotWeaponKey, slotBeltKey, groupedCurUnseenMods, curWeaponBeltsOrdered, curWeaponsOrdered, weaponsScrollHandler,
  curWeapon, curWeaponModName, curUnitAllModsCost, curBelt, equippedWeaponId, equippedBeltId, curWeaponMod, curSlotIdx,
  curBeltWeapon, findSlotWeaponsToBuyNonUpdatable
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { weaponW, weaponGap } = require("%rGui/unitMods/slotWeaponCard.nut")
let { getBulletBeltShortName, getWeaponShortNamesList } = require("%rGui/weaponry/weaponsVisual.nut")
let { getModCurrency, getModCost } = require("%rGui/unitMods/unitModsState.nut")
let { openMsgBoxPurchase, PURCHASE_BOX_UID } = require("%rGui/shop/msgBoxPurchase.nut")
let { closeMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { markTutorialCompleted, isFinishedArsenal, isFinishedUnitsResearch } = require("%rGui/tutorial/completedTutorials.nut")
let { TUTORIAL_ARSENAL_ID } = require("tutorialConst.nut")


let MIN_BATLES_TO_START = 4
let isDebugMode = mkWatched(persist, "isDebugMode", false)

let hasUnitModifications = Computed(@() visibleNewModsSlots.get().len() > 0)

let needShowTutorial = Computed(@() !isInSquad.get()
  && !isFinishedArsenal.get()
  && (sharedStatsByCampaign.get()?.battles ?? 0) + (sharedStatsByCampaign.get()?.offlineBattles ?? 0)
    >= MIN_BATLES_TO_START
  && isFinishedUnitsResearch.get()
  && isCampaignWithUnitsResearch.get()
  && curCampaignSlots.get() != null
  && hasUnitModifications.get())
let canStartTutorial = Computed(@() !hasModalWindows.get()
  && isMainMenuAttached.get()
  && !isTutorialActive.get())
let showTutorial = keepref(Computed(@() canStartTutorial.get()
  && (needShowTutorial.get() || isDebugMode.get())))

let shouldEarlyCloseTutorial = keepref(Computed(@() activeTutorialId.get() == TUTORIAL_ARSENAL_ID
  && (!hasUnitModifications.get() || !(isMainMenuAttached.get() || isUnitModSlotsAttached.get()))))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function selectUnit(unitIdx) {
  selectedSlotIdx.set(unitIdx)
  let unitName = curCampaignSlots.get()?.slots[selectedSlotIdx.get()].name
  if (unitName != curUnit.get()?.name)
    setCurrentUnit(unitName)
  curSelectedUnit.set(unitName)
  return true
}

function findModsToBuyNonUpdatable() {
  let { beltUnseenMods, secondaryUnseenMods } = groupedCurUnseenMods.get()
  if (beltUnseenMods.len() == 0 && secondaryUnseenMods.len() == 0) {
    let { idx, available, isBelt } = findSlotWeaponsToBuyNonUpdatable()
    return { isBelt, index = idx, modsToShow = available }
  }

  let isBelt = beltUnseenMods.len() > 0
  let unseenMods = isBelt ? beltUnseenMods : secondaryUnseenMods
  let firstAvaialableGroupIdx = 0
  let index = unseenMods.keys()?[firstAvaialableGroupIdx]
  return { isBelt, index, modsToShow = unseenMods?[index] ?? {} }
}

function startTutorial() {
  let isCurrentSlot = Computed(@() visibleNewModsSlots.get()?[selectedSlotIdx.get()] != null)
  let wasCurrentSlotAtStart = isCurrentSlot.get()
  let wndShowEnough = Watched(false)
  let slotsForLastStep = []

  setTutorialConfig({
    id = TUTORIAL_ARSENAL_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished")
        markTutorialCompleted(TUTORIAL_ARSENAL_ID)
    }
    steps = [
      {
        id = "s1_mainmenu_select_slot"
        nextStepAfter = isCurrentSlot
        text = "\n".concat(loc("tutorial/arsenal/initCongratulations"),
          loc("tutorial/arsenal/chooseSlot"))
        charId = "mary_like"
        onSkip = @() selectUnit(visibleNewModsSlots.get().keys()[0])
        objects = visibleNewModsSlots.get().map(@(_, unitIdx) {
          keys = slotBarSlotKey(unitIdx)
          needArrow = true
          onClick = @() selectUnit(unitIdx)
        })
      }
      {
        id = "s2_press_arsenal_button"
        text = !wasCurrentSlotAtStart ? loc("tutorial/arsenal/moveToArsenal")
          : "\n".concat(loc("tutorial/arsenal/initCongratulations"),
            loc("tutorial/arsenal/moveToArsenal"))
        charId = "mary_like"
        objects = [{
          keys = slotBarArsenalKey
          needArrow = true
          onClick = @() openUnitModsSlotsWndByName(curCampaignSlots.get()?.slots[selectedSlotIdx.get()].name)
        }]
      }
      {
        id = "s3_open_unit_mods"
        function beforeStart() {
          let { index, isBelt, modsToShow } = findModsToBuyNonUpdatable()
          if (index == null) {
            logerr("No unit modification to buy in arsenal tutorial")
            finishTutorial()
            return
          }
          if (isBelt)
            setCurBeltsWeaponIdx(index)
          else
            setCurSlotIdx(index)
          local firstSlot = 1000
          foreach (v in modsToShow.keys()) {
            let slotIdx = isBelt ? curWeaponBeltsOrdered.get().findindex(@(belt) belt.id == v)
              : curWeaponsOrdered.get().findindex(@(weap) weap.name == v)
            firstSlot = min(firstSlot, slotIdx)
            slotsForLastStep.append({
              keys = isBelt ? slotBeltKey(slotIdx) : slotWeaponKey(slotIdx)
              needArrow = true
              onClick = @() isBelt ? curBeltIdx.set(slotIdx) : curWeaponIdx.set(slotIdx)
            })
          }
          resetTimeout(0.5, function() {
            weaponsScrollHandler.scrollToX(firstSlot * (weaponW + weaponGap))
            wndShowEnough.set(true)
          })
        }
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s4_press_unit_mods_slot"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = slotsForLastStep
      }
      {
        id = "s5_open_msg_box_purchase"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = [{
          keys = ["arsenal_purchase_tutor_btn"]
          needArrow = true
          function onClick() {
            let mod = curWeaponMod.get()
            let weaponName = curBelt.get() != null ? getBulletBeltShortName(curBelt.get().id)
              : comma.join(getWeaponShortNamesList(curWeapon.get()?.weapons ?? []))
            openMsgBoxPurchase({
              text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, weaponName) }),
              price = { price = getModCost(mod, curUnitAllModsCost.get()), currencyId = getModCurrency(mod) },
              purchase = @() null,
              bqInfo = null
            })
          }
          hotkeys = ["^J:Y"]
        }]
      }
      {
        beforeStart = @() moveModalToTop(WND_UID)
        id = "s6_press_buy_button"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = [{
          keys = ["purchase_tutor_btn"]
          needArrow = true
          function onClick() {
            let unitName = curCampaignSlots.get()?.slots[selectedSlotIdx.get()].name
            let mod = curWeaponMod.get()
            let modName = curWeaponModName.get()
            let price = getModCost(mod, curUnitAllModsCost.get())
            let currencyId = getModCurrency(mod)
            buy_unit_mod(unitName, modName, currencyId, price, {
              id = "onPurchasedMod"
              unitName
              weapon = curWeapon.get() == null || equippedWeaponId.get() == curWeapon.get().name ? null
                : { slotIdx = curSlotIdx.get(), weapon = curWeapon.get() }
              belt = curBelt.get() == null || equippedBeltId.get() == curBelt.get().id ? null
                : { weaponId = curBeltWeapon.get().weaponId, id = curBelt.get()?.id ?? "" }
            })
            closeMsgBox(PURCHASE_BOX_UID)
          }
          hotkeys = ["^J:A"]
        }]
      }
      {
        id = "s7_finish_arsenal_tutorial"
        nextKeyDelay = -1
        charId = "mary_like"
        text = loc("tutorial/arsenal/finish")
      }
    ]
  })
}

let startTutorialDelayed = @() deferOnce(function() {
  if (!showTutorial.get())
    return
  startTutorial()
  isDebugMode.set(false)
})

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

register_command(
  function() {
    if (activeTutorialId.get() == TUTORIAL_ARSENAL_ID)
      return finishTutorial()
    if (!hasUnitModifications.get())
      console_print("Unable to start tutorial, because of no avaiable mods to buy") 
    else
      isDebugMode.set(true)
  }
  "debug.tutorial_arsenal")
