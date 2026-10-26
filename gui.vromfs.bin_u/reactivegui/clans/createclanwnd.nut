from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import getCurrentLanguage
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN
from "%appGlobals/config/clanPresentation.nut" import defBadgeIcon
from "%appGlobals/dirtyWordsFilter.nut" import clearExcessiveWhitespace, checkPhrase
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/campaign.nut" import allCampaignsBitmask, isProfileReceived
from "%appGlobals/pServer/pServerApi.nut" import clansInProgress
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%rGui/clans/badgeEditorWnd.nut" import badgeEditorWnd
from "%rGui/clans/clanCfg.nut" import clanLocations
from "%rGui/clans/clanState.nut" import isClanCreateOpen, getClanNameError, closeClanCreate, createClan,
  clanCreateEconomy
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgeBtn
from "%rGui/clans/components/clanComps.nut" import separator
from "%rGui/clans/components/clanFormComps.nut" import MAX_NAME_CHARS, MAX_DESCRIPTION_CHARS, badgeSize, sectionLabel,
  mkTypePropertyRow, mkLocationPropertyRow, mkLanguagePropertyRow, mkCampaignsPropertyRow
from "%rGui/clans/components/textInputs.nut" import MIN_CLAN_NAME_CHARS, mkClanNameInput, mkClanInputField
from "%rGui/components/buttonStyles.nut" import INACTIVE
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/modalWindows.nut" import addModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPricePurchase, textButtonInactive
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/shop/msgBoxPurchase.nut" import showNoBalanceMsgIfNeed


let clanName = Watched("")
let clanDesc = Watched("")
let clanType = Watched(PRIVACY_OPEN)
let clanLocation = Watched("")
let clanLanguage = Watched("")
let clanCampaigns = Watched(0)
let clanBadge = Watched(defBadgeIcon)

function resetFieldsToDefault() {
  clanName.set("")
  clanDesc.set("")
  clanCampaigns.set(allCampaignsBitmask.get())
  clanLanguage.set(getCurrentLanguage())
  clanLocation.set(clanLocations.get()?[0] ?? "")
  clanBadge.set(clone defBadgeIcon)
  clanType.set(PRIVACY_OPEN)
}

resetFieldsToDefault()
isProfileReceived.subscribe(@(_) resetFieldsToDefault())

function onCloseClanCreate() {
  closeClanCreate()
  resetFieldsToDefault()
}

let clanNameClean = Computed(@() clearExcessiveWhitespace(clanName.get()))
let clanNameErrW = Computed(@() getClanNameError(clanNameClean.get(), MIN_CLAN_NAME_CHARS))

function onCreateClan() {
  if (clanNameErrW.get())
    return openFMsgBox({ text = loc(clanNameErrW.get())})

  if (showNoBalanceMsgIfNeed(clanCreateEconomy.get().amount, clanCreateEconomy.get().currencyCode, null))
    return

  createClan(clanType.get(),
    {
      name = clanNameClean.get()
      description = checkPhrase(clanDesc.get().strip())
      location = clanLocation.get()
      language = clanLanguage.get()
      campaigns = clanCampaigns.get()
      ...clanBadge.get()
    },
    "on_clan_created")

  clanName.set(clanNameClean.get())
}

registerHandler("on_clan_created", @(_) resetFieldsToDefault())

let mkBadgePreview = mkClanBadgeBtn(clanBadge, badgeSize, @() addModalWindow(badgeEditorWnd(clanBadge)))

let clanNameInput = mkClanNameInput(clanName, clanNameClean, MAX_NAME_CHARS, clanNameErrW)
let clanInputField = mkClanInputField(clanDesc, MAX_DESCRIPTION_CHARS)

let createBtn = @() {
  watch = [clanNameErrW, clansInProgress, clanCreateEconomy]
  opacity = !clanNameErrW.get() ? 1.0 : 0.4
  children = clansInProgress.get() ? spinner
    : clanCreateEconomy.get() == null ? textButtonInactive(utf8ToUpper(loc("clans/error/createNotAvailable")), @() null)
    : textButtonPricePurchase(utf8ToUpper(loc("clans/create/createBtn")),
        mkCurrencyComp(clanCreateEconomy.get().amount, clanCreateEconomy.get().currencyCode),
          onCreateClan, !clanNameErrW.get() ? {} : INACTIVE)
}

let createClanWnd = bgShaded.__merge({
  key = {}
  size = FLEX
  children = [
    modalWndBg.__merge({
      size = const [sw(70), sh(85)]
      children = [
        @() {
          size = FLEX
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          padding = const [0, 0, hdpx(30), 0]
          children = [
            modalWndHeaderWithClose(loc("clans/create/title"), onCloseClanCreate)
            {
              size = FLEX
              flow = FLOW_VERTICAL
              padding = [hdpx(20), saBorders[0], 0, saBorders[0]]
              gap = hdpx(50)
              children = [
                {
                  size = FLEX_H
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  halign = ALIGN_CENTER
                  text = loc("clans/create/desc")
                }.__update(fontSmallShaded)
                {
                  size = FLEX_H
                  flow = FLOW_HORIZONTAL
                  gap = hdpx(20)
                  children = [
                    {
                      size = const [pw(15), SIZE_TO_CONTENT]
                      flow = FLOW_VERTICAL
                      gap = hdpx(50)
                      children = [
                        {
                          size = const [FLEX, hdpx(100)]
                          valign = ALIGN_CENTER
                          children = sectionLabel(loc("clans/create/name"),
                            { size = FLEX_H, rendObj = ROBJ_TEXTAREA, behavior = Behaviors.TextArea })
                        }
                        {
                          size = const [FLEX, hdpx(200)]
                          valign = ALIGN_CENTER
                          children = sectionLabel(loc("clans/create/badge"),
                            { size = FLEX_H, rendObj = ROBJ_TEXTAREA, behavior = Behaviors.TextArea })
                        }
                      ]
                    }
                    {
                      size = const [pw(85), SIZE_TO_CONTENT]
                      flow = FLOW_VERTICAL
                      gap = hdpx(50)
                      children = [
                        {
                          size = const [FLEX, hdpx(100)]
                          children = clanNameInput
                        }
                        {
                          size = const [FLEX, hdpx(200)]
                          flow = FLOW_HORIZONTAL
                          gap = hdpx(50)
                          children = [
                            mkBadgePreview
                            {
                              size = FLEX
                              flow = FLOW_VERTICAL
                              gap = hdpx(20)
                              halign = ALIGN_CENTER
                              children = [
                                {
                                  rendObj = ROBJ_TEXT
                                  text = loc("clans/create/description")
                                }.__update(fontSmallAccented)
                                clanInputField
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
                {
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  gap = hdpx(20)
                  children = [
                    separator
                    {
                      size = FLEX_H
                      flow = FLOW_HORIZONTAL
                      gap = { size = FLEX_H }
                      children = [
                        mkTypePropertyRow(clanType)
                        mkLocationPropertyRow(clanLocation)
                        mkLanguagePropertyRow(clanLanguage)
                        mkCampaignsPropertyRow(clanCampaigns)
                      ]
                    }
                  ]
                }
              ]
            }
            createBtn
          ]
        }
      ]
    })
  ]
  animations = wndSwitchAnim
})

registerScene("createClanWnd", createClanWnd, closeClanCreate, isClanCreateOpen)
