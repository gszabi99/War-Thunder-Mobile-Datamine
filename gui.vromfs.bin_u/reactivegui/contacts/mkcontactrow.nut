from "%globalsDarg/darg_library.nut" import *
let { Contact } = require("%rGui/contacts/contact.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkContactOnlineStatus, presences } = require("%rGui/contacts/contactPresence.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { darkenBgColor, borderWidth, rowHeight, gap, contactNameBlock, contactAvatar, contactLevelBlock,
  contactOnlineStatusBlock, contactSquadStatusBlock } = require("%rGui/contacts/contactInfoPkg.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


function mkContactRow(uid, rowIdx, isSelected, onClick, responseAction = null) {
  let userId = uid.tostring()
  let contact = Contact(userId)
  let info = mkPublicInfo(userId)
  let onlineStatus = mkContactOnlineStatus(userId)
  let battleUnit = Computed(@() serverConfigs.get()?.allUnits[presences.get()?[userId].battleUnit])
  let stateFlags = Watched(0)
  let isHovered = Computed(@() (stateFlags.get() & S_HOVER) != 0)
  return @() {
    watch = [contact, info, isSelected, isHovered]
    key = uid
    size = [flex(), rowHeight]
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
        size = flex()
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap
        padding = borderWidth
        rendObj = ROBJ_BOX
        fillColor = (rowIdx % 2) ? 0 : darkenBgColor
        borderWidth = isSelected.get() || isHovered.get() ? borderWidth : 0
        borderColor = isSelected.get() ? selectColor : 0xFF3E95AB
        children = [
          {
            flow = FLOW_HORIZONTAL
            children = [
              contactLevelBlock(info.get())
              contactAvatar(info.get())
            ]
          }
          contactNameBlock(contact.get(), info.get())
          {
            size = flex()
          }
          contactSquadStatusBlock(uid.tointeger(), { margin = [0, gap, 0, 0]})
          responseAction
        ]
      }
    ]
  }
}

return mkContactRow