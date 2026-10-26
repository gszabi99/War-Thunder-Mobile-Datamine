from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge
from "%appGlobals/pServer/pServerApi.nut" import clansInProgress, clanUserJoinRequestsInProgress
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/clans/clanCfg.nut" import languagesCfg
from "%rGui/clans/clanPermissions.nut" import CLAN_EDIT, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import sendJoinRequest, getClanDisplayName, openClanEditor, getClanHexId,
  openClanSearch, isClanSearchOpen
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgePreview
from "%rGui/clans/components/clanComps.nut" import separator, mkSectionText, maskToCampaigns, clanScrollBarStyle
from "%rGui/clans/components/clanInfoColumns.nut" import clanInfoColumns
import "%rGui/clans/components/clanRequestWnd.nut" as openClanRequest
from "%rGui/clans/currentClanState.nut" import currentClanId, myClanGrade, isCurrentClanRefreshing, NO_CLAN_ID
from "%rGui/components/clipboard.nut" import copyToClipboard
import "%rGui/components/mkIconBtn.nut" as mkIconBtn
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPrimary, iconButtonCommon, textButtonInactive
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/clans/clanJoinRequestsState.nut" import userClanJoinRequests


const iconSize = hdpx(40)
const btnIconSize = hdpx(70)
const badgeSize = hdpx(180)
const copyIconSize = hdpxi(28)
const gapNameCopy = hdpx(15)
const gapSection = hdpx(20)

let mkJoinBtnClick = @(onJoin) function() {
  openMsgBox({
    text = loc("clans/joinRequest/confirm")
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "ok", styleId = "PRIMARY", isDefault = true, cb = onJoin }
    ]
  })
}


let searchClanBtn = @() {
  watch = [isClanSearchOpen, isGamepad]
  children = isClanSearchOpen.get() ? null
    : iconButtonCommon("ui/gameuiskin#icon_clan_search.svg", openClanSearch,
      {
        iconOvr = { size = iconSize }
        ovr = {
          size = isGamepad.get() ? [btnIconSize * 2, btnIconSize] : [btnIconSize, btnIconSize]
          minWidth = btnIconSize
        }
      })
}


let mkActionBtn = @(isCurrentClan, canEditClan, clan) @() {
  watch = [isCurrentClan, canEditClan, isGamepad, clansInProgress, clanUserJoinRequestsInProgress, userClanJoinRequests,
    isCurrentClanRefreshing, currentClanId]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = clansInProgress.get()
        || (!isCurrentClan.get() && (clanUserJoinRequestsInProgress.get() || isCurrentClanRefreshing.get()))
      ? spinner
    : !isCurrentClan.get() && userClanJoinRequests.get()?[clan?.clanId]
      ? textButtonInactive(utf8ToUpper(loc("inReview")), @() null)
    : !isCurrentClan.get() && currentClanId.get() != NO_CLAN_ID 
      ? null
    : !isCurrentClan.get()
      ? textButtonPrimary(utf8ToUpper(loc(clan?.privacyType == PRIVACY_OPEN ? "clans/joinBtn" : "sendRequestBtn")),
          clan?.privacyType == PRIVACY_OPEN ? mkJoinBtnClick(@() sendJoinRequest(clan?.clanId))
            : @() openClanRequest(clan?.textFields.name, @(message, onSuccess) sendJoinRequest(clan?.clanId, message, onSuccess)))
    : canEditClan.get()
      ? [
          iconButtonCommon("ui/gameuiskin#menu_edit.svg", openClanEditor,
            {
              iconOvr = { size = iconSize }
              ovr = {
                size = isGamepad.get() ? [btnIconSize * 2, btnIconSize] : [btnIconSize, btnIconSize]
                minWidth = btnIconSize
              }
            })
          searchClanBtn
        ]
    : searchClanBtn
}

function mkTextWithCopy(text, font = fontMediumShaded) {
  let stateFlags = Watched(0)

  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gapNameCopy
    behavior = Behaviors.Button
    onClick = @(evt) copyToClipboard(evt, text)
    onElemState = @(s) stateFlags.set(s)
    children = [
      {
        size = FLEX_H
        maxWidth = SIZE_TO_CONTENT
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        text
      }.__update(font)
      mkIconBtn("ui/gameuiskin#icon_copy.svg", copyIconSize, stateFlags)
    ]
  }
}

let mkInfoLabelsRow = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = clanInfoColumns.map(@(c) mkSectionText(loc(c.locId)))
}

let mkInfoDataRow = @(data) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = clanInfoColumns.map(@(c) c.mkCell(data))
}

function mkClanHeaderSection(clanW) {
  let badgeFromClanW = Computed(@(prev) prevIfEqual(prev, mkClanBadge(clanW.get()?.textFields)))
  let campaignsW = Computed(function() {
    let clan = clanW.get()
    if (clan == null)
      return []
    return maskToCampaigns(clan?.textFields.campaigns ?? "0", serverConfigs.get()?.campaignCfg ?? {})
  })
  let locationId = Computed(@() clanW.get()?.textFields.location ?? "")
  let locationW = Computed(@() locationId.get() == "" ? "" : loc($"region/{locationId.get()}"))
  let langId = Computed(@() clanW.get()?.textFields.language ?? "")
  let languageW = Computed(@() languagesCfg?[langId.get()].title ?? langId.get())
  let isCurrentClan = Computed(@() clanW.get()?.clanId != null && currentClanId.get() == clanW.get().clanId)
  let canEditClan = Computed(@() hasClanPermission(CLAN_EDIT, clanGrades.get(), myClanGrade.get()))

  return @() {
    watch = clanW
    size = FLEX_H
    flow = FLOW_VERTICAL
    rendObj = ROBJ_IMAGE
    image = mkColoredGradientY(0xFF304453, 0xFF030C13)
    gap = gapSection
    padding = gapSection
    children = clanW.get() == null
      ? null
      : [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = gapSection
            children = [
              {
                flow = FLOW_VERTICAL
                gap = hdpx(10)
                halign = ALIGN_CENTER
                children = [
                  mkClanBadgePreview(badgeFromClanW, badgeSize)
                  {
                    size = FLEX_H
                    flow = FLOW_HORIZONTAL
                    gap = gapSection
                    children = [
                      { rendObj = ROBJ_TEXT, text = $"{loc("options/userId")}:", ...fontTinyAccented}
                      mkTextWithCopy(getClanHexId(clanW.get()?.clanId), fontTinyAccented)
                    ]
                  }
                ]
              }
              {
                size = FLEX
                flow = FLOW_HORIZONTAL
                gap = gapSection
                children = {
                  size = FLEX
                  flow = FLOW_VERTICAL
                  halign = ALIGN_LEFT
                  gap = hdpx(10)
                  children = [
                    mkTextWithCopy(getClanDisplayName(clanW.get()?.textFields.name ?? ""))
                    makeVertScroll({
                        size = FLEX_H
                        rendObj = ROBJ_TEXTAREA
                        behavior = Behaviors.TextArea
                        text = clanW.get()?.textFields.description ?? ""
                      }.__update(fontTinyAccented),
                      {
                        size = FLEX
                        barStyleCtor = clanScrollBarStyle
                      })
                  ]
                }
              }
              mkActionBtn(isCurrentClan, canEditClan, clanW.get())
            ]
          }
          mkInfoLabelsRow
          separator
          mkInfoDataRow({ campaignsW, locationW, languageW })
        ]
  }
}

return mkClanHeaderSection
