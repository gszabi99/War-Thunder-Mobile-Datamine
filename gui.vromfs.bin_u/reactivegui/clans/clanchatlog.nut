from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/chat/chatPkg.nut" import mkChatEventMsg
from "%rGui/chat/chatMsgCtors.nut" import registerChatMessageCreator
from "%rGui/clans/clanLogsState.nut" import clanLogs
from "%rGui/contacts/contact.nut" import Contact, getContactNick, validateNickNames
from "%rGui/style/stdColors.nut" import localPlayerColor, nameColor
from "%rGui/clans/components/clanComps.nut" import mkGradeIcon
from "%rGui/clans/clanCfg.nut" import gradesSettingscfg


const CLAN_LOG_LIFE_TIME = 30 * 24 * 3600
const MIN_LOG_TIME_STEP = 3600
const gradeIconSize = hdpxi(36)
const CLAN_LOG_MSG_CTOR = "clanLog"

let logTextCtors = {
  ClanAddUserOrder = @(nick, _) loc("clans/log/memberAdded", { nick })
  ClanRemoveUserOrder = @(nick, _) loc("clans/log/memberRemoved", { nick })
  ClanSetUserGradeOrder = @(nick, gradeStr)
    loc("clans/log/gradeChanged", { nick, role = colorize(nameColor, loc(gradesSettingscfg.valToString(gradeStr))) })
}
let logBorderColors = {
  ClanAddUserOrder = 0xFF177649
  ClanRemoveUserOrder = 0xFF761717
}

let minLogTimestamp = Computed(@() serverTime.get() / MIN_LOG_TIME_STEP * MIN_LOG_TIME_STEP - CLAN_LOG_LIFE_TIME)

let clanChatLogItems = keepref(Computed(function(prev) {
  let minTs = minLogTimestamp.get()
  let lastStateByUser = {}
  let res = []
  foreach (item in (clanLogs.get() ?? [])) {
    let { userIdStr, kind, gradeStr, timestamp } = item
    if (kind == null || kind not in logTextCtors)
      continue
    
    let state = $"{kind}|{gradeStr}"
    if (lastStateByUser?[userIdStr] == state)
      continue
    lastStateByUser[userIdStr] <- state
    if (timestamp >= minTs)
      res.append(item.__merge({ ctorId = CLAN_LOG_MSG_CTOR }))
  }
  return prevIfEqual(prev, res)
}))

let validateLogNickNames = @(items) validateNickNames(items.map(@(l) l.userIdStr))
validateLogNickNames(clanChatLogItems.get())
clanChatLogItems.subscribe(validateLogNickNames)

let mkClanLogText = @(kind, nick, gradeStr, isMe)
  logTextCtors[kind](colorize(isMe ? localPlayerColor : nameColor, nick), gradeStr)

function mkClanLogComp(item, maxTextWidth) {
  let { key, userIdStr, kind, gradeStr } = item
  let contact = Contact(userIdStr)
  let borderColor = logBorderColors?[kind]
  let icon = kind == "ClanSetUserGradeOrder"
    ? mkGradeIcon(gradeStr, gradeIconSize)
    : null

  return @() {
    key
    watch = [contact, myUserId]
    size = FLEX_H
    children = mkChatEventMsg(mkClanLogText(kind, getContactNick(contact.get()), gradeStr,
      myUserId.get().tostring() == userIdStr), maxTextWidth, borderColor, icon)
  }
}

registerChatMessageCreator(CLAN_LOG_MSG_CTOR, mkClanLogComp)

return {
  clanChatLogItems
}
