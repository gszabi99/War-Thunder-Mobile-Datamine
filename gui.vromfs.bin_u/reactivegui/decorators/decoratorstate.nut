from "%globalsDarg/darg_library.nut" import *
let { decorators, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { register_command } = require("console")
let { mark_decorators_seen, mark_decorators_unseen } = require("%appGlobals/pServer/pServerApi.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let isDecoratorsSceneOpened = mkWatched(persist, "isDecoratorsSceneOpened", false)
let isShowAllDecorators = mkWatched(persist, "isShowAllDecorators", false)

let allDecorators = Computed(@() campConfigs.get()?.allDecorators ?? {})
let myDecorators = Computed(@() decorators.get()?.filter(@(d) d.name in allDecorators.get()) ?? {})

let allTitles = Computed(@() allDecorators.get()?.filter(@(dec) dec.dType == "title") ?? {})
let allFrames = Computed(@() allDecorators.get()?.filter(@(dec) dec.dType == "nickFrame") ?? {})
let allAvatars = Computed(@() allDecorators.get()?.filter(@(dec) dec.dType == "avatar") ?? {})

let availTitles = Computed(@() decorators.get()?.filter(@(frame) frame.name in allTitles.get()) ?? {})
let availNickFrames = Computed(@() decorators.get()?.filter(@(frame) frame.name in allFrames.get()) ?? {})
let availAvatars = Computed(@() decorators.get()?.filter(@(avatar) avatar.name in allAvatars.get()) ?? {})

let ignoreUnseenDecoratorsList = hardPersistWatched("ignoreUnseenDecoratorsList", {})
let unseenDecorators = Computed(@() myDecorators.get().filter(@(d) !d.wasSeen &&
  d.name not in ignoreUnseenDecoratorsList.get()))
let hasUnseenDecorators = Computed(@() unseenDecorators.get().len() != 0)

let chosenTitle = Computed(@() availTitles.get().findvalue(@(v) v.isCurrent))
let chosenNickFrame = Computed(@() availNickFrames.get().findvalue(@(v) v.isCurrent))
let chosenAvatar = Computed(@() availAvatars.get().findvalue(@(v) v.isCurrent))

let chosenDecoratorsHash = Computed(@() (chosenTitle.get()?.name ?? "").hash() + (chosenNickFrame.get()?.name ?? "").hash() + (chosenAvatar.get()?.name ?? "").hash())

let myNameWithFrame = Computed(@() frameNick(myUserName.get(), chosenNickFrame.get()?.name))
let myAvatarImage = Computed(@() getAvatarImage(chosenAvatar.get()?.name))

function markDecoratorsSeen(names) {
  let unseenNames = names.filter(@(name) name in unseenDecorators.get())
  if (unseenNames.len() == 0)
    return
  ignoreUnseenDecoratorsList.mutate(@(v) unseenNames.each(@(name) v[name] <- true))
  mark_decorators_seen(unseenNames)
}

function markDecoratorSeen(name) {
  if (!name)
    return
  if (name in unseenDecorators.get()) {
    ignoreUnseenDecoratorsList.mutate(@(v) v[name] <- true)
    mark_decorators_seen([name])
  }
}

register_command(@() mark_decorators_seen(allDecorators.get().keys(), "consolePrintResult")
  "meta.mark_all_decorators_seen")
register_command(@() mark_decorators_unseen(allDecorators.get().keys(), "consolePrintResult")
  "meta.mark_all_decorators_unseen")
register_command(@() isShowAllDecorators.set(!isShowAllDecorators.get()), "meta.show_all_decorators")

return {
  isDecoratorsSceneOpened
  openDecoratorsScene = @() isDecoratorsSceneOpened.set(true)
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

  chosenDecoratorsHash

  myNameWithFrame
  myAvatarImage
}