from "%globalsDarg/darg_library.nut" import *
let logT = log_with_prefix("[ARSENAL_TUTOR] ")
let { register_command } = require("console")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { buy_unit_mod } = require("%appGlobals/pServer/pServerApi.nut")
let { isCampaignWithUnitsResearch, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots } = require("%appGlobals/pServer/slots.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { hasModalWindows, moveModalToTop } = require("%rGui/components/modalWindows.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { setTutorialConfig, isTutorialActive, finishTutorial, goToStep,
  activeTutorialId, WND_UID } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { selectedSlotIdx, slotBarArsenalKey, slotBarSlotKey, visibleNewModsSlots, actualSlotIdx,
  attachedSlotBarArsenalIdx
} = require("%rGui/slotBar/slotBarState.nut")
let { curWeaponIdx, curBeltIdx, setCurSlotIdx, setCurBeltsWeaponIdx, isUnitModSlotsAttached, openUnitModsSlotsWnd,
  slotWeaponKey, slotBeltKey, groupedCurUnseenMods, curWeaponBeltsOrdered, curWeaponsOrdered,
  curWeapon, curWeaponModName, curBelt, equippedWeaponId, equippedBeltId, curWeaponMod, curSlotIdx,
  curBeltWeapon, findSlotWeaponsToBuyNonUpdatable, isHangarUnitHasWeaponSlots, curUnitAllModsSlotsCost
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { carouselScrollHandler } = require("%rGui/unitMods/unitModsScroll.nut")
let { modW, modsGap } = require("%rGui/unitMods/unitModsConst.nut")
let { getBulletBeltShortName, getWeaponShortNamesList } = require("%rGui/weaponry/weaponsVisual.nut")
let { getModCurrency, getModCost, slotModKey, curModId, modsSorted, unseenModsByCategory, mods, hasEnoughCurrencies
  curModCategoryId, curBulletCategoryId, isUnitModAttached, curUnitAllModsCost, curMod, openUnitModsWnd
} = require("%rGui/unitMods/unitModsState.nut")
let { openMsgBoxPurchase, PURCHASE_BOX_UID } = require("%rGui/shop/msgBoxPurchase.nut")
let { closeMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { markTutorialCompleted, isFinishedArsenal, isFinishedUnitsResearch } = require("%rGui/tutorial/completedTutorials.nut")
let { TUTORIAL_ARSENAL_ID } = require("%rGui/tutorial/tutorialConst.nut")


let STEP_OPEN_ARSENAL_BUTTON = "s2_open_arsenal_button"
let STEP_FINISH = "s9_finish_arsenal_tutorial"

let MIN_BATLES_TO_START = 4
let isDebugMode = mkWatched(persist, "isDebugMode", false)

let hasUnitModifications = Computed(@() visibleNewModsSlots.get().len() > 0)

let needShowTutorial = Computed(@() !isInSquad.get()
  && actualSlotIdx.get() != null
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
  && (!hasUnitModifications.get() || (!isMainMenuAttached.get() && !isUnitModSlotsAttached.get() && !isUnitModAttached.get()))))
let finishEarly = @() shouldEarlyCloseTutorial.get() ? finishTutorial() : null
shouldEarlyCloseTutorial.subscribe(@(v) v ? deferOnce(finishEarly) : null)

function selectUnit(unitIdx) {
  let unitName = curCampaignSlots.get()?.slots[unitIdx].name
  if (unitName == null || selectedSlotIdx.get() == unitIdx)
    return

  if (unitName != curCampaignSlots.get()?.slots[selectedSlotIdx.get()].name)
    setCurrentUnit(unitName)

  selectedSlotIdx.set(unitIdx)
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
  let isCurrentSlot = Computed(@() visibleNewModsSlots.get()?[actualSlotIdx.get()] != null)
  let wasCurrentSlotAtStart = isCurrentSlot.get()
  let wndShowEnough = Watched(false)
  let slotsForLastStep = []

  let toPressArsenalBtnStep = @(v) v ? deferOnce(@() goToStep(STEP_OPEN_ARSENAL_BUTTON)) : null
  isCurrentSlot.subscribe(toPressArsenalBtnStep)

  setTutorialConfig({
    id = TUTORIAL_ARSENAL_ID
    function onStepStatus(stepId, status) {
      logT($"{stepId}: {status}")
      if (status == "tutorial_finished") {
        isCurrentSlot.unsubscribe(toPressArsenalBtnStep)
        markTutorialCompleted(TUTORIAL_ARSENAL_ID)
      }
    }
    steps = [
      {
        id = "s1_mainmenu_select_slot"
        text = "\n".concat(loc("tutorial/arsenal/initCongratulations"),
          loc("tutorial/arsenal/chooseSlot"))
        charId = "mary_like"
        objects = visibleNewModsSlots.get().keys().map(@(unitIdx) {
          keys = slotBarSlotKey(unitIdx)
          needArrow = true
          function onClick() {
            isCurrentSlot.unsubscribe(toPressArsenalBtnStep)
            selectUnit(unitIdx)
          }
        })
      }
      {
        id = STEP_OPEN_ARSENAL_BUTTON
        beforeStart = @() isCurrentSlot.unsubscribe(toPressArsenalBtnStep)
        charId = "mary_like"
        nextStepAfter = Computed(@() isCurrentSlot.get() && attachedSlotBarArsenalIdx.get() == actualSlotIdx.get())
      }
      {
        id = "s3_press_arsenal_button"
        text = !wasCurrentSlotAtStart ? loc("tutorial/arsenal/moveToArsenal")
          : "\n".concat(loc("tutorial/arsenal/initCongratulations"),
            loc("tutorial/arsenal/moveToArsenal"))
        charId = "mary_like"
        objects = [{
          keys = slotBarArsenalKey
          needArrow = true
          onClick = @() isHangarUnitHasWeaponSlots.get() ? openUnitModsSlotsWnd() : openUnitModsWnd()
        }]
      }
      {
        id = "s4_open_unit_mods"
        charId = "mary_like"
        nextStepAfter = Computed(@() isHangarUnitHasWeaponSlots.get()
          || curModCategoryId.get() != null
          || curBulletCategoryId.get() != null)
        objects = [{ keys = "sceneRoot", onClick = @() true }]
      }
      {
        id = "s5_select_available_unit_mods"
        function beforeStart() {
          local firstSlot = 1000
          if (isHangarUnitHasWeaponSlots.get()) {
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
          }
          else {
            let categoryId = unseenModsByCategory.get().findindex(function(unseenMods) {
              foreach (k, _ in unseenMods)
                if (hasEnoughCurrencies(mods.get()?[k], curUnitAllModsCost.get(), balance.get()))
                  return true
              return false
            })
            if (categoryId == null) {
              logerr("No unit modification to buy in arsenal tutorial")
              finishTutorial()
              return
            }
            curModCategoryId.set(categoryId)
            foreach (idx, v in modsSorted.get()) {
              let { name } = v
              if (unseenModsByCategory.get()?[categoryId][name] && hasEnoughCurrencies(v, curUnitAllModsCost.get(), balance.get())) {
                firstSlot = min(firstSlot, idx)
                slotsForLastStep.append({
                  keys = slotModKey(idx)
                  needArrow = true
                  onClick = @() curModId.set(name)
                })
              }
            }
          }
          resetTimeout(0.5, function() {
            carouselScrollHandler.scrollToX(firstSlot * (modW + modsGap))
            wndShowEnough.set(true)
          })
        }
        nextStepAfter = wndShowEnough
        objects = [{ keys = "sceneRoot" }]
      }
      {
        id = "s6_press_unit_mods_slot"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = slotsForLastStep
      }
      {
        id = "s7_open_msg_box_purchase"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = [{
          keys = "arsenal_purchase_btn"
          needArrow = true
          function onClick() {
            let allModsCost = isHangarUnitHasWeaponSlots.get() ? curUnitAllModsSlotsCost.get() : curUnitAllModsCost.get()
            let mod = isHangarUnitHasWeaponSlots.get() ? curWeaponMod.get() : curMod.get()
            if (mod == null) {
              goToStep(STEP_FINISH)
              return
            }
            let weaponName = !isHangarUnitHasWeaponSlots.get() ? loc($"modification/{curMod.get().name}")
              : curBelt.get() != null ? getBulletBeltShortName(curBelt.get().id)
              : comma.join(getWeaponShortNamesList(curWeapon.get()?.weapons ?? []))
            openMsgBoxPurchase({
              text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, weaponName) }),
              price = { price = getModCost(mod, allModsCost), currencyId = getModCurrency(mod) },
              purchase = @() null,
              bqInfo = null
            })
          }
          hotkeys = ["^J:Y"]
        }]
      }
      {
        beforeStart = @() moveModalToTop(WND_UID)
        id = "s8_press_buy_button"
        text = loc("tutorial/arsenal/arsenalInfo")
        charId = "mary_points"
        objects = [{
          keys = "purchase_tutor_btn"
          needArrow = true
          function onClick() {
            let unitName = curUnit.get().name
            let mod = isHangarUnitHasWeaponSlots.get() ? curWeaponMod.get() : curMod.get()
            let modName = isHangarUnitHasWeaponSlots.get() ? curWeaponModName.get() : curMod.get().name
            let allModsCost = isHangarUnitHasWeaponSlots.get() ? curUnitAllModsSlotsCost.get() : curUnitAllModsCost.get()
            let price = getModCost(mod, allModsCost)
            let currencyId = getModCurrency(mod)
            let cb = !isHangarUnitHasWeaponSlots.get() ? null
              : {
                  id = "onPurchasedMod"
                  unitName
                  weapon = curWeapon.get() == null || equippedWeaponId.get() == curWeapon.get().name ? null
                    : { slotIdx = curSlotIdx.get(), weapon = curWeapon.get() }
                  belt = curBelt.get() == null || equippedBeltId.get() == curBelt.get().id ? null
                    : { weaponId = curBeltWeapon.get().weaponId, id = curBelt.get()?.id ?? "" }
                }
            buy_unit_mod(unitName, modName, currencyId, price, cb)
            closeMsgBox(PURCHASE_BOX_UID)
          }
          hotkeys = ["^J:A"]
        }]
      }
      {
        id = STEP_FINISH
        hasNextKey = true
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
