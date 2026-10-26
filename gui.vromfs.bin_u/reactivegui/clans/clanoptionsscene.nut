from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/permissions.nut" import allow_clans_chat
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge
from "%rGui/clans/clanChatState.nut" import hasClanChatUnseen
from "%rGui/clans/clanPermissions.nut" import CLAN_JOIN_LIST, clanGrades, hasClanPermission
from "%rGui/clans/clanQuestsState.nut" import hasClanQuestsUnseen, clanQuestsEndsAt
from "%rGui/clans/clanState.nut" import getClanDisplayName, isClanInfoOpen, closeClanInfo, viewedClan
from "%rGui/clans/clanSubmissions.nut" import mkClanSubmissionResponse, mkClanSubmissionMessage
from "%rGui/clans/clanSubmissionsState.nut" import clanSubmissionsUids, hasClanSubmissions
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgePreview
from "%rGui/clans/currentClanState.nut" import currentClan, myClanGrade
import "%rGui/clans/pages/clanChatPage.nut" as clanChatPage
import "%rGui/clans/pages/clanQuestsPage.nut" as mkClanQuestsPage
import "%rGui/clans/pages/clanSquadsPage.nut" as clanSquadsPage
import "%rGui/clans/pages/myClanPage.nut" as myClanPage
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/timerBlock.nut" import mkTimer
from "%rGui/contacts/contactActions.nut" import PROFILE_VIEW
from "%rGui/contacts/mkContactActionBtn.nut" import mkContactActionBtn
from "%rGui/contacts/mkContactListScene.nut" import mkContactListScene
from "%rGui/options/mkOptionsScene.nut" import mkOptionsScene
from "%rGui/style/stdColors.nut" import textColor
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate
from "%rGui/unseenPriority.nut" import UNSEEN_HIGH, SEEN


const SCENE_ID = "clanOptionsScene"
const badgeSize = hdpx(80)
let isOpened = mkWatched(persist, $"{SCENE_ID}_isOpened", false)
let curTabId = Watched(null)

let clanQuestsTabContent = {
  size = FLEX_H
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    @() {
      size = FLEX_H
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("clan/quests")
      ...fontTinyAccented
    }
    mkTimer(clanQuestsEndsAt, { hplace = ALIGN_RIGHT })
  ]
}

let tabs = [
  {
    id = "myClan"
    locId = "clan/myClan"
    image = "ui/gameuiskin#icon_clan_main.svg"
    imageSizeMul = 1.3
    imageTabOffset = [ -0.1, 0 ]
    isFullWidth = true
    content = myClanPage
  }
  {
    id = "clanQuests"
    image = "ui/gameuiskin#icon_clan_tasks.svg"
    isFullWidth = true
    contentCtor = mkClanQuestsPage
    tabContent = clanQuestsTabContent
    unseen = hasClanQuestsUnseen
  }
  {
    id = "clanChat"
    locId = "clan/chat"
    image = "ui/gameuiskin#icon_clan_chat.svg"
    isFullWidth = true
    content = clanChatPage
    unseen = hasClanChatUnseen
    isVisible = allow_clans_chat
  }
  {
    id = "clanSquads"
    locId = "clan/squads"
    image = "ui/gameuiskin#icon_clan_squad.svg"
    isFullWidth = true
    content = clanSquadsPage
  }
  {
    id = "clanSubmissions"
    locId = "clan/submissions"
    image = "ui/gameuiskin#icon_clan_submissions.svg"
    isFullWidth = true
    content = mkContactListScene(clanSubmissionsUids,
      @(userId) [mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })],
      mkClanSubmissionResponse,
      loc("clan/submissions/empty"),
      mkClanSubmissionMessage
    )
    isVisible = Computed(@() hasClanSubmissions.get()
      && hasClanPermission(CLAN_JOIN_LIST, clanGrades.get(), myClanGrade.get()))
    unseen = Computed(@() hasClanSubmissions.get() ? UNSEEN_HIGH : SEEN)
  }
  {
    id = "clanActivity"
    locId = "clan/activity"
    image = "ui/gameuiskin#icon_clan_chat.svg"
    isFullWidth = true
    content = clanChatPage
    isVisible = Computed(@() !allow_clans_chat.get())
  }
]

let closeClanScene = @() isOpened.set(false)

let header = headerGradientBg([
  backButton(closeClanScene)
  {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [0, 0, 0, hdpx(20)]
    gap = hdpx(20)
    children = [
      mkClanBadgePreview(Computed(@() mkClanBadge(currentClan.get()?.textFields)), badgeSize)
      @() {
        watch = currentClan
        rendObj = ROBJ_TEXT
        text = getClanDisplayName(currentClan.get()?.textFields.name ?? "")
        color = textColor
      }.__update(fontBig)
    ]
  }
])

let clanOptionsScene = mkOptionsScene(SCENE_ID, tabs, isOpened, curTabId, header)
registerUnlocksSceneToUpdate(SCENE_ID)

currentClan.subscribe(function(v) {
  if (v == null)
    return closeClanScene()
  if (isClanInfoOpen.get() && viewedClan.get()?.clanId == v?.clanId) {
    closeClanInfo()
    clanOptionsScene()
  }
})

return {
  clanOptionsScene
  setCurTabId = @(id) curTabId.set(id)
}
