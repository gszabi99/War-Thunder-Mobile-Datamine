from "%globalsDarg/darg_library.nut" import *
from "math" import min
from "%sqstd/math.nut" import getRomanNumeral
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import campaignsList
from "%appGlobals/squadState.nut" import isInSquad, squadData
from "%appGlobals/updater/gameModeAddons.nut" import maxReleasedUnitRanks
from "%rGui/clans/clanSquadsState.nut" import updateClanSquad, squadInProgress, SQUAD_OPEN, SQUAD_CLOSED,
  isClanSquadLeader, updateClanSquadField
from "%rGui/clans/components/chooseValueWnd.nut" import openChooseValueWnd
from "%rGui/clans/components/clanComps.nut" import mkSectionText
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanChangeBtn
from "%rGui/clans/currentClanState.nut" import currentClanId
from "%rGui/components/buttonStyles.nut" import defButtonHeight, defButtonMinWidth
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, buttonsHGap


const WND_UID = "create_clan_squad"
const btnIconSize = hdpx(70)

let playerSelectedCampaign = mkWatched(persist, "playerSelectedCampaign", null)
let playerSelectedRank = mkWatched(persist, "playerSelectedRank", 1)
let playerSelectedType = mkWatched(persist, "playerSelectedType", SQUAD_OPEN)
let campaign = Computed(@() isClanSquadLeader.get() ? (squadData.get()?.campaign ?? campaignsList.get()?[0])
  : campaignsList.get().contains(playerSelectedCampaign.get()) ? playerSelectedCampaign.get()
  : campaignsList.get()?[0])
let mRank = Computed(@() isClanSquadLeader.get() ? (squadData.get()?.mRank ?? 1)
  : clamp(playerSelectedRank.get(), 1, maxReleasedUnitRanks.get()?[campaign.get()] ?? 1))
let squadType = Computed(@() isClanSquadLeader.get() ? (squadData.get()?.squadType ?? SQUAD_OPEN)
  : playerSelectedType.get())

currentClanId.subscribe(@(_) removeModalWindow(WND_UID))
isInSquad.subscribe(@(_) removeModalWindow(WND_UID))

let mkOption = @(header, valueText, onClick) @() {
  watch = valueText
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    mkSectionText(header, { size = SIZE_TO_CONTENT })
    mkClanChangeBtn(valueText.get(),
      onClick,
      [SIZE_TO_CONTENT, btnIconSize],
      {
        childOvr = { padding = [0, hdpx(20), 0, hdpx(10)] }
        textOvr = { minWidth = hdpx(170) }
      })
  ]
}

let openChangeCampaign = @() openChooseValueWnd(
  {
    locTitle = "campaign"
    values = campaignsList.get()
    valToString = @(v) loc(getCampaignPresentation(v).headerLocId)
    col = 3
    btnMinWidth = hdpx(350)
  },
  campaign,
  function(v) {
    if (!isClanSquadLeader.get()) {
      playerSelectedCampaign.set(v)
      return
    }
    updateClanSquadField("campaign", v)
    updateClanSquadField("mRank", clamp(mRank.get(), 1, maxReleasedUnitRanks.get()?[v] ?? 1))
  })

function openChangeRank() {
  let maxRank = maxReleasedUnitRanks.get()?[campaign.get()] ?? 1
  openChooseValueWnd(
    {
      locTitle = "attrib_section/mRank"
      values = array(maxRank).map(@(_, i) i + 1)
      valToString = @(v) getRomanNumeral(v)
      col = min(10, maxRank)
      btnMinWidth = hdpx(100)
    },
    mRank,
    @(v) isClanSquadLeader.get() ? updateClanSquadField("mRank", v) : playerSelectedRank.set(v))
}

let mkOptions = @() {
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap
  children = [
    mkOption(loc("campaign"),
      Computed(@() loc(getCampaignPresentation(campaign.get()).headerLocId)),
      openChangeCampaign)
    mkOption(loc("attrib_section/mRank"),
      Computed(@() getRomanNumeral(mRank.get())),
      openChangeRank)
    mkOption(loc("squad/type"),
      Computed(@() loc($"clan/squadType/{squadType.get()}")),
      function() {
        let newType = squadType.get() == SQUAD_OPEN ? SQUAD_CLOSED : SQUAD_OPEN
        if (isClanSquadLeader.get())
          updateClanSquadField("squadType", newType)
        else
          playerSelectedType.set(newType)
      })
  ]
}

let openSquadCreateWnd = @() addModalWindowWithHeader(WND_UID,
  @() {
    watch = isClanSquadLeader
    rendObj = ROBJ_TEXT
    text = loc(isClanSquadLeader.get() ? "clan/squad" : "clan/createSquad")
    ...fontSmall
  },
  @() {
    watch = isClanSquadLeader
    padding = buttonsHGap
    flow = FLOW_VERTICAL
    gap = buttonsHGap
    halign = ALIGN_CENTER
    children = [
      mkOptions()
      isClanSquadLeader.get() ? null
        : mkSpinnerHideBlock(squadInProgress,
            textButtonPrimary(utf8ToUpper(loc("clans/create/createBtn")),
              function() {
                if (updateClanSquad(campaign.get(), mRank.get(), squadType.get()))
                  removeModalWindow(WND_UID)
              }),
            { size = [ defButtonMinWidth, defButtonHeight ], halign = ALIGN_CENTER, valign = ALIGN_CENTER })
    ]
  })

return openSquadCreateWnd