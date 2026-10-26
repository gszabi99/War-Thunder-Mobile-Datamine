from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/platform.nut" import is_pc
from "%sqstd/timers.nut" import debounce
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/pServerApi.nut" import clansLookupInProgress, clanInfoInProgress
from "%rGui/clans/clanState.nut" import searchClanName, closeClanSearch, openClanCreate, isClanSearchOpen,
  openClanFilters, getClanDisplayName, openClanInfo, lookupClans, foundedClans, searchClanNameCleared
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgePreview
from "%rGui/clans/components/clanComps.nut" import maskToCampaigns
from "%rGui/clans/currentClanState.nut" import currentClanId, NO_CLAN_ID
from "%rGui/clans/lastClanRewardsBtn.nut" import lastClanRewardsBtn
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/components/textInput.nut" import floatingTextInput
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim, mkPressTransitionScale
from "%rGui/style/stdColors.nut" import selectColor, hoverColor
from "%rGui/unitCustom/unitCustomComps.nut" import mkIcon


const onChangeDelay = 0.8 
const wndPadding = hdpx(50)
const searchIconSize = hdpx(40)
const filterIconSize = hdpx(30)
const textInputHeight = hdpx(60)
const clanAvatarSize = hdpx(60)
const campaignIconSize = hdpx(40)
const rowBgOddColor = 0x60000000
const rowBgEvenColor = 0x60141414
const defMaxUsersCount = 30

let lookupClansDebounced = debounce(lookupClans, onChangeDelay)
searchClanNameCleared.subscribe(@(_) is_pc ? lookupClansDebounced() : lookupClans())

let searchIcon = {
  size = searchIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:P")
  color = 0xFFFFFFFF
}

function mkInputIcon(img, onClick) {
  let sf = Watched(0)

  return @() {
    watch = sf
    behavior = Behaviors.Button
    size = filterIconSize
    onClick
    onElemState = @(s) sf.set(s)
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{img}.svg:{filterIconSize}:P")
    color = sf.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
    ...mkPressTransitionScale(sf.get(), 0.9)
  }
}

let filterIcon = mkInputIcon("filter_icon", openClanFilters)
let refreshIcon = mkInputIcon("btn_trash_return", lookupClans)

let searchBlock = floatingTextInput(searchClanName, {
  ovr = { size = const [FLEX, textInputHeight] }
  placeholder = loc("input/serach_by_name")
  mkEditContent = @(_, inputComp) {
    size = FLEX
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(50)
    children = [
      searchIcon
      inputComp
      filterIcon
      refreshIcon
    ]
  }
})

let mkRowImage = @(iconName, size = clanAvatarSize) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{iconName}:{size}:P")
}

let clanCampaigns = @(campaignsMask) @() {
  watch = serverConfigs
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(10)
  children = maskToCampaigns(campaignsMask, serverConfigs.get()?.campaignCfg ?? {})
    .map(@(c) mkRowImage(getCampaignPresentation(c).clanIcon, campaignIconSize))
}

let mkRow = @(clan) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  padding = const[0, hdpx(20), 0, 0]
  children = [
    mkClanBadgePreview(Watched(mkClanBadge(clan?.textFields)), clanAvatarSize)
    {
      size = FLEX
      rendObj = ROBJ_TEXT
      valign = ALIGN_CENTER
      text = getClanDisplayName(clan?.textFields.name ?? "")
    }.__update(fontTinyAccentedShaded)
    clan?.privacyType && clan.privacyType != PRIVACY_OPEN ? mkIcon("ui/gameuiskin#lock_icon.svg")
      : null
    clanCampaigns(clan?.textFields.campaigns ?? "0")
    {
      size = FLEX_V
      rendObj = ROBJ_TEXT
      valign = ALIGN_CENTER
      text = $"{clan?.usersCount ?? 0}/{clan?.maxUsersCount ?? defMaxUsersCount}"
    }.__update(fontTinyAccentedShaded)
  ]
}

let pannableArea = verticalPannableAreaCtor(sh(37), [0, 0])
let mkClansTable = @() pannableArea(@() {
  watch = foundedClans
  rendObj = ROBJ_SOLID
  size = FLEX_H
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  color = 0xFF030C13
  children = foundedClans.get().len() == 0 ? null
    : foundedClans.get().map(@(clan, idx) {
        size = const [FLEX, hdpx(60)]
        rendObj = ROBJ_BOX
        fillColor = (idx % 2) ? rowBgOddColor : rowBgEvenColor
        flow = FLOW_HORIZONTAL
        borderColor = selectColor
        behavior = Behaviors.Button
        onClick = @() openClanInfo(clan)
        children = mkRow(clan)
      })
})

let lookupInProgress = Computed(@() clansLookupInProgress.get().len() > 0 || clanInfoInProgress.get().len() > 0)

let searchClanWnd = bgShaded.__merge({
  key = {}
  size = FLEX
  children = [
    modalWndBg.__merge({
      size = const [sw(70), sh(80)]
      children = [
        function() {
          let clansTable = mkClansTable()
          let searchSpinner = mkSpinner(hdpx(100), { hplace = ALIGN_CENTER, margin = const [hdpx(100), 0, 0, 0] })

          return {
            size = FLEX
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            padding = const [0, 0, wndPadding, 0]
            children = [
              modalWndHeaderWithClose(loc("clans"), closeClanSearch)
              {
                size = FLEX
                halign = ALIGN_CENTER
                flow = FLOW_VERTICAL
                padding = wndPadding
                children = [
                  {
                    rendObj = ROBJ_TEXT
                    text = loc("clans/search/desc")
                    margin = const[0, 0, hdpx(30), 0]
                  }.__update(fontSmallShaded)
                  searchBlock
                  @() {
                    watch = [foundedClans, lookupInProgress]
                    size = FLEX
                    children = foundedClans.get().len() > 0 ? clansTable
                      : lookupInProgress.get() ? searchSpinner
                      : {
                          rendObj = ROBJ_TEXT
                          padding = wndPadding
                          text = loc("contacts/searchNotFound")
                        }.__update(fontSmallShaded)
                  }
                ]
              }
              { size = FLEX }
              @() {
                watch = currentClanId
                flow = FLOW_HORIZONTAL
                gap = hdpx(40)
                children = [
                  lastClanRewardsBtn
                  currentClanId.get() != NO_CLAN_ID ? null 
                    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_createNew")), openClanCreate)
                  ]
              }
            ]
          }
        }
      ]
    })
  ]
  animations = wndSwitchAnim
})


registerScene("searchClanWnd", searchClanWnd, closeClanSearch, isClanSearchOpen)
