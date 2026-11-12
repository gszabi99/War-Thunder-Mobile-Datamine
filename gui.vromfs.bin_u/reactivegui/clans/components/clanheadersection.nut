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
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPrimary, iconButtonCommon, textButtonInactive
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/options/optionsStyle.nut" import tabW, minContentOffset
from "%rGui/clans/clanJoinRequestsState.nut" import userClanJoinRequests


const iconSize = hdpx(40)
const btnIconSize = hdpx(70)
const badgeSize = hdpx(250)
const copyIconSize = hdpxi(28)
const gapNameCopy = hdpx(15)
const gapSection = hdpx(20)
const descriptionLinesCount = 5
let descriptionWidth = saSize[0] - tabW - minContentOffset - badgeSize - gapSection * 3
let descriptionFont = fontTinyShaded

let mkDescArea = @(text) {
  size = [descriptionWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  ...descriptionFont
}
let rowHeight = calc_comp_size(mkDescArea("W"))[1]

let descriptionHeight = rowHeight * descriptionLinesCount

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

const btnOvr = { childOvr = fontTinyShaded, ovr = { size = [SIZE_TO_CONTENT, btnIconSize] } }

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
      ? textButtonInactive(utf8ToUpper(loc("inReview")), @() null, btnOvr)
    : !isCurrentClan.get() && currentClanId.get() != NO_CLAN_ID 
      ? null
    : !isCurrentClan.get()
      ? textButtonPrimary(utf8ToUpper(loc(clan?.privacyType == PRIVACY_OPEN ? "clans/joinBtn" : "sendRequestBtn")),
          clan?.privacyType == PRIVACY_OPEN ? mkJoinBtnClick(@() sendJoinRequest(clan?.clanId))
            : @() openClanRequest(clan?.textFields.name, @(message, onSuccess) sendJoinRequest(clan?.clanId, message, onSuccess)),
          btnOvr)
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

function mkTextWithCopy(text, font) {
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

let mkClanNameRow = @(clan) {
  size = FLEX_H
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  padding = const [hdpx(-10), 0, 0, 0]
  text = getClanDisplayName(clan?.textFields.name ?? "")
  ...fontMediumShaded
}

let mkClanIdRow = @(clan) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = gapSection
  children = [
    { rendObj = ROBJ_TEXT, text = $"{loc("options/userId")}{loc("ui/colon")}", ...fontTinyShaded}
    mkTextWithCopy(getClanHexId(clan?.clanId), fontTinyShaded)
  ]
}

let openDescription = @(text) openMsgBox({
  uid = "CLAN_DESCRIPTION",
  text = {
    size = FLEX
    padding = const [hdpx(50), 0, 0, 0]
    children = makeVertScroll({
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
      ...descriptionFont
    },
    {
      size = FLEX
      barStyleCtor = clanScrollBarStyle
    })},
  buttons = [],
  onBgClick = @() closeMsgBox("CLAN_DESCRIPTION")})

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
  let descriptionW = Computed(@() clanW.get()?.textFields.description ?? "")
  let isDescriptionFit = Computed(@() calc_comp_size(mkDescArea(descriptionW.get()))[1] <= descriptionHeight)
  let onClick = @() openDescription(descriptionW.get())

  return @() {
    watch = clanW
    size = FLEX_H
    flow = FLOW_VERTICAL
    rendObj = ROBJ_IMAGE
    image = mkColoredGradientY(0xFF304453, 0xFF030C13)
    gap = hdpx(5)
    padding = const [gapSection, gapSection, 0, gapSection]
    children = clanW.get() == null
      ? null
      : [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = gapSection
            children = [
              mkClanBadgePreview(badgeFromClanW, badgeSize)
              {
                size = FLEX
                flow = FLOW_VERTICAL
                gap = hdpx(5)
                children = [
                  {
                    size = FLEX_H
                    flow = FLOW_HORIZONTAL
                    children = [
                      {
                        size = FLEX_H
                        flow = FLOW_VERTICAL
                        gap = hdpx(5)
                        children = [
                          mkClanNameRow(clanW.get())
                          mkClanIdRow(clanW.get())
                        ]
                      }
                      mkActionBtn(isCurrentClan, canEditClan, clanW.get())
                    ]
                  }
                  @() {
                    watch = [descriptionW, isDescriptionFit]
                    size = [descriptionWidth, isDescriptionFit.get() ? descriptionHeight : descriptionHeight - rowHeight ]
                    rendObj = ROBJ_TEXTAREA
                    behavior = [Behaviors.TextArea, Behaviors.Button]
                    text = descriptionW.get()
                    textOverflow = getconsttable()?.TOVERFLOW_ELLIPSIS
                    clipChildren = false
                    onClick
                    ...descriptionFont
                  }
                  @() {
                    watch = isDescriptionFit
                    size = FLEX_H
                    rendObj = ROBJ_TEXTAREA
                    behavior = [Behaviors.TextArea, Behaviors.Button]
                    onClick
                    text = isDescriptionFit.get() ? null : colorize(0xFF3CA0FD, loc("readMore"))
                    ...descriptionFont
                  }
                ]
              }
            ]
          }
          { size = hdpx(5) }
          mkInfoLabelsRow
          separator
          mkInfoDataRow({ campaignsW, locationW, languageW })
        ]
  }
}

return mkClanHeaderSection
