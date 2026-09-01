from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/contacts/contact.nut" import Contact
from "%rGui/contacts/contactInfoPkg.nut" import darkenBgColor, borderWidth, rowHeight, gap, contactNameBlock,
  contactAvatar, contactLevelBlock, contactOnlineStatusBlock, contactSquadStatusBlock
from "%rGui/contacts/contactPresence.nut" import mkContactOnlineStatus, presences
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo
from "%rGui/style/stdColors.nut" import selectColor


function mkContactRow(uid, rowIdx, isSelected, onClick, responseAction = null, leftContent = null) {
  let userId = uid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  let onlineStatus = mkContactOnlineStatus(userId)
  let battleUnit = Computed(@() serverConfigs.get()?.allUnits[presences.get()?[userId].battleUnit])
  let stateFlags = Watched(0)
  return @() {
    watch = [contact, info, isSelected]
    key = uid
    size = [FLEX, rowHeight]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    xmbNode = {}
    onAttach = @() refreshPublicInfo(uid)
    gap
    children = [
      contactOnlineStatusBlock(onlineStatus, battleUnit)
      {
        size = FLEX
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap
        padding = borderWidth
        rendObj = ROBJ_BOX
        fillColor = (rowIdx % 2) ? 0 : darkenBgColor
        borderWidth = isSelected.get() ? borderWidth : 0
        borderColor = isSelected.get() ? selectColor : null
        children = [
          leftContent
          {
            flow = FLOW_HORIZONTAL
            children = [
              contactLevelBlock(info.get())
              contactAvatar(info.get())
            ]
          }
          contactNameBlock(contact.get(), info.get())
          {
            size = FLEX
          }
          contactSquadStatusBlock(uid.tointeger(), { margin = [0, gap, 0, 0]})
          responseAction
        ]
      }
    ]
  }
}

return mkContactRow