let { memoize } = require("%sqstd/functools.nut")

let mkDefPresentation = @(id) {
  id
  locId = $"infoPopup/{id}/title"
  descLocId = $"infoPopup/{id}/desc"
  image = null
  imageSize = [1000, 400]
}

let presentations = {
  lootbox_rewards_change = {
    image = "ui/images/trophies_changes_header.avif"
  }
}

return memoize(@(id) mkDefPresentation(id).__update(presentations?[id] ?? {}))