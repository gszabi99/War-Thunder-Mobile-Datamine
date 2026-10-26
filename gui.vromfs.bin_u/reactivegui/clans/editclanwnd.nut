from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge, defBadgeIcon
from "%appGlobals/dirtyWordsFilter.nut" import checkPhrase
from "%appGlobals/pServer/pServerApi.nut" import clansInProgress
from "%rGui/clans/badgeEditorWnd.nut" import badgeEditorWnd
from "%rGui/clans/clanPermissions.nut" import CLAN_REMOVE, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import updateClan, closeClanEditor, isClanEditorOpen, removeClan
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgeBtn
from "%rGui/clans/components/clanComps.nut" import separator
from "%rGui/clans/components/clanFormComps.nut" import MAX_DESCRIPTION_CHARS, badgeSize, mkTypePropertyRow,
  mkLocationPropertyRow, mkLanguagePropertyRow, mkCampaignsPropertyRow
from "%rGui/clans/components/textInputs.nut" import mkClanInputField
from "%rGui/clans/currentClanState.nut" import currentClan, currentClanId, myClanGrade
from "%rGui/components/buttonStyles.nut" import COMMON
from "%rGui/components/modalWindows.nut" import addModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPrimary, iconTextButton, mergeStyles
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let editDesc = Watched("")
let editType = Watched(PRIVACY_OPEN)
let editLocation = Watched("")
let editLanguage = Watched("")
let editCampaigns = Watched(0)
let editBadge = Watched(defBadgeIcon)
let badgeFromClanW = Computed(@() mkClanBadge(currentClan.get()?.textFields))

let canRemoveClan = Computed(@() hasClanPermission(CLAN_REMOVE, clanGrades.get(), myClanGrade.get()))

function onApplyClan() {
  let privacyType = currentClan.get()?.privacyType == editType.get() ? null : editType.get()
  let clanData = {
    description = checkPhrase(editDesc.get().strip())
    location = editLocation.get()
    language = editLanguage.get()
    campaigns = editCampaigns.get()
    ...editBadge.get()
  }
  updateClan(currentClanId.get(), clanData, privacyType)
}

let mkBadgePreview = mkClanBadgeBtn(editBadge, badgeSize, @() addModalWindow(badgeEditorWnd(editBadge)))
let editInputField = mkClanInputField(editDesc, MAX_DESCRIPTION_CHARS)

let disbandBtn = iconTextButton("ui/gameuiskin#icon_exit.svg",
  utf8ToUpper(loc("clans/disbandBtn")),
  @() openMsgBox({
    text = loc("clans/disbandRequest/confirm")
    buttons = [
      { id = "cancel", isCancel = true, styleId = "PRIMARY" }
      { text = loc("clans/disbandBtn"), cb = @() removeClan(currentClanId.get()) }
    ]
  }),
  mergeStyles(COMMON, {
    iconOvr = {
      size = hdpx(50)
      keepAspect = true
      transform = { rotate = 180 }
    }
    textOvr = fontBoldTinyAccentedShaded
    childOvr = { gap = hdpx(20) }
    useFlexText = true
  }))

let applyBtn = textButtonPrimary(utf8ToUpper(loc("mainmenu/btnApply")), onApplyClan)

let editClanWnd = bgShaded.__merge({
  key = {}
  size = FLEX
  onAttach = function() {
    let clan = currentClan.get()
    editDesc.set(clan?.textFields.description ?? "")
    editType.set(clan?.privacyType ?? PRIVACY_OPEN)
    editLocation.set(clan?.textFields.location ?? "")
    editLanguage.set(clan?.textFields.language ?? "")
    editCampaigns.set((clan?.textFields.campaigns ?? "0").tointeger())
    editBadge.set(clone badgeFromClanW.get())
  }
  children = [
    modalWndBg.__merge({
      size = const [sw(70), sh(70)]
      children = [
        @() {
          size = FLEX
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          padding = const [0, 0, hdpx(30), 0]
          children = [
            modalWndHeaderWithClose(loc("clans/edit/title"), closeClanEditor)
            {
              size = FLEX
              flow = FLOW_VERTICAL
              padding = [hdpx(20), saBorders[0], 0, saBorders[0]]
              gap = hdpx(50)
              children = [
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
                          ...fontSmallAccented
                        }
                        editInputField
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
                        mkTypePropertyRow(editType)
                        mkLocationPropertyRow(editLocation)
                        mkLanguagePropertyRow(editLanguage)
                        mkCampaignsPropertyRow(editCampaigns)
                      ]
                    }
                  ]
                }
              ]
            }
            @() {
              watch = [clansInProgress, canRemoveClan]
              size = FLEX_H
              padding = [0, saBorders[0]]
              halign = ALIGN_CENTER
              flow = FLOW_HORIZONTAL
              gap = const {size = flex()}
              children = clansInProgress.get() ? spinner
                : canRemoveClan.get() ? [disbandBtn, applyBtn]
                : [applyBtn]
            }
          ]
        }
      ]
    })
  ]
  animations = wndSwitchAnim
})

registerScene("editClanWnd", editClanWnd, closeClanEditor, isClanEditorOpen)
