let presentations = {
  season_5 = { color = 0xA500A556 }
  season_6 = { imageOffset = [0, -0.06] }
  season_7 = { color = 0xA584C827, imageOffset = [0, -0.08] }
  season_8 = { color = 0xA50A65B1 }
  season_9 = { color = 0XA57E34FF }
  season_11 = { color = 0xFFFFBB10 }
}

let genParams = {
  name = @(name) name
  image = @(name) $"ui/gameuiskin#banner_event_{name}.avif"
  color = @(_) 0xA5FF2B00
  imageOffset = @(_) [0, 0]
}

function mkEventPresentation(name) {
  let res = presentations?[name] ?? {}
  foreach (id, gen in genParams)
    if (id not in res)
      res[id] <- gen(name)
  return res
}

let cache = {}

function getEventPresentationByName(name) {
  if (name not in cache)
    cache[name ?? ""] <- mkEventPresentation(name)
  return cache[name ?? ""]
}

return {
  getEventPresentation = @(name) getEventPresentationByName(name)
}