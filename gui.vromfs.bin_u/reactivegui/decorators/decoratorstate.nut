from "%globalsDarg/darg_library.nut" import *
let { decorators, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { doesLocTextExist } = require("dagor.localize")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { register_command } = require("console")
let { mark_decorators_seen, mark_decorators_unseen } = require("%appGlobals/pServer/pServerApi.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let isDecoratorsSceneOpened = mkWatched(persist, "isDecoratorsSceneOpened", false)
let isShowAllDecorators = mkWatched(persist, "isShowAllDecorators", false)

let allDecorators = Computed(@() campConfigs.value?.allDecorators ?? {})
let myDecorators = Computed(@() decorators.value?.filter(@(d) d.name in allDecorators.value) ?? {})

let allTitles = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "title") ?? {})
let allFrames = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "nickFrame") ?? {})
let allAvatars = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "avatar") ?? {})

let availTitles = Computed(@() decorators.value?.filter(@(frame) frame.name in allTitles.value) ?? {})
let availNickFrames = Computed(@() decorators.value?.filter(@(frame) frame.name in allFrames.value) ?? {})
let availAvatars = Computed(@() decorators.value?.filter(@(avatar) avatar.name in allAvatars.value) ?? {})

let ignoreUnseenDecoratorsList = hardPersistWatched("ignoreUnseenDecoratorsList", {})
let unseenDecorators = Computed(@() myDecorators.value.filter(@(d) !d.wasSeen &&
  d.name not in ignoreUnseenDecoratorsList.value))
let hasUnseenDecorators = Computed(@() unseenDecorators.value.len() != 0)

let chosenTitle = Computed(@() availTitles.value.findvalue(@(v) v.isCurrent))
let chosenNickFrame = Computed(@() availNickFrames.value.findvalue(@(v) v.isCurrent))
let chosenAvatar = Computed(@() availAvatars.value.findvalue(@(v) v.isCurrent))

let myNameWithFrame = Computed(@() frameNick(myUserName.value, chosenNickFrame.value?.name))
let myAvatarImage = Computed(@() getAvatarImage(chosenAvatar.value?.name))

function getReceiveReason(decName){
  if(decName == null)
    return null
  let locId = $"decor/{decName}/receiveReason"
  if(doesLocTextExist(locId))
    return loc(locId)
  return loc("decor/decorNotAvailable")
}

function markDecoratorsSeen(names) {
  let unseenNames = names.filter(@(name) name in unseenDecorators.value)
  if (unseenNames.len() == 0)
    return
  ignoreUnseenDecoratorsList.mutate(@(v) unseenNames.each(@(name) v[name] <- true))
  mark_decorators_seen(unseenNames)
}

function markDecoratorSeen(name) {
  if (!name)
    return
  if (name in unseenDecorators.value) {
    ignoreUnseenDecoratorsList.mutate(@(v) v[name] <- true)
    mark_decorators_seen([name])
  }
}

register_command(@() mark_decorators_seen(allDecorators.value.keys(), "consolePrintResult")
  "meta.mark_all_decorators_seen")
register_command(@() mark_decorators_unseen(allDecorators.value.keys(), "consolePrintResult")
  "meta.mark_all_decorators_unseen")
register_command(@() isShowAllDecorators(!isShowAllDecorators.value), "meta.show_all_decorators")

return {
  isDecoratorsSceneOpened
  openDecoratorsScene = @() isDecoratorsSceneOpened(true)
  isShowAllDecorators

  allDecorators
  myDecorators

  unseenDecorators
  hasUnseenDecorators
  ignoreUnseenDecoratorsList
  markDecoratorsSeen
  markDecoratorSeen

  allTitles
  allFrames
  allAvatars

  availTitles
  availNickFrames
  availAvatars

  chosenNickFrame
  chosenTitle
  chosenAvatar

  myNameWithFrame
  getReceiveReason
  myAvatarImage
}