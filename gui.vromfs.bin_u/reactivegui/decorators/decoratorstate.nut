from "%globalsDarg/darg_library.nut" import *
let { decorators, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { doesLocTextExist } = require("dagor.localize")
let { register_command } = require("console")
let { mark_decorators_seen, mark_decorators_unseen } = require("%appGlobals/pServer/pServerApi.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let isDecoratorsSceneOpened = mkWatched(persist, "isDecoratorsSceneOpened", false)

let allDecorators = Computed(@() campConfigs.value?.allDecorators ?? {})
let myDecorators = Computed(@() decorators.value?.filter(@(d) d.name in allDecorators.value) ?? {})

let allTitles = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "title") ?? {})
let allFrames = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "nickFrame") ?? {})

let availTitles = Computed(@() decorators.value?.filter(@(frame) frame.name in allTitles.value) ?? {})
let availNickFrames = Computed(@() decorators.value?.filter(@(frame) frame.name in allFrames.value) ?? {})

let ignoreUnseenDecoratorsList = hardPersistWatched("ignoreUnseenDecoratorsList", {})
let unseenDecorators = Computed(@() myDecorators.value.filter(@(d) !d.wasSeen &&
  d.name not in ignoreUnseenDecoratorsList.value))

let chosenTitle = Computed(@() availTitles.value.findvalue(@(v) v.isCurrent))
let chosenNickFrame = Computed(@() availNickFrames.value.findvalue(@(v) v.isCurrent))

let myNameWithFrame = Computed(@() frameNick(myUserName.value, chosenNickFrame.value?.name))

let function getReceiveReason(decName){
  if(decName == null)
    return null
  let locId = $"decor/{decName}/receiveReason"
  if(doesLocTextExist(locId))
    return loc(locId)
  return loc("decor/decorNotAvailable")
}

let function markDecoratorsSeen(names) {
  let unseenNames = names.filter(@(name) name in unseenDecorators.value)
  if (unseenNames.len() == 0)
    return
  ignoreUnseenDecoratorsList.mutate(@(v) unseenNames.each(@(name) v[name] <- true))
  mark_decorators_seen(unseenNames)
}

let function markDecoratorSeen(name) {
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

return {
  isDecoratorsSceneOpened
  openDecoratorsScene = @() isDecoratorsSceneOpened(true)

  chosenNickFrame
  chosenTitle
  availTitles
  availNickFrames
  allDecorators
  myDecorators

  unseenDecorators
  ignoreUnseenDecoratorsList
  markDecoratorsSeen
  markDecoratorSeen

  allTitles
  allFrames
  myNameWithFrame
  getReceiveReason
}