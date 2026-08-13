let { memoize } = require("%sqstd/functools.nut")

let mkDefPresentation = @(id) {
  id
  locId = $"infoPopup/{id}/title"
  descLocId = $"infoPopup/{id}/desc"
  image = null
  imageSize = [1000, 400]
  innerImage = null
  innerImageSize = [750, 300]
}

let presentations = {
  lootbox_rewards_change = {
    image = "ui/images/trophies_changes_header.avif"
  }
  anniversary_2025 = {
    image = "ui/images/event_bg_anniversary_2025.avif"
    imageSize = [1200, 554]
  }
  halloween_2025 = {
    image = "ui/images/event_bg_halloween_2025.avif"
    imageSize = [1200, 554]
  }
  tanks_legacy_tree = {
    image = "ui/images/tanks_legacy_tree_info.avif"
  }
  new_year_2026 = {
    image = "ui/images/event_bg_christmas_2024.avif"
    imageSize = [1200, 554]
  }
  april_event_2026 = {
    image = "ui/images/event_bg_event_april_2026.avif"
    imageSize = [1200, 554]
  }
  anniversary_2026 = {
    image = "ui/bkg/login_bkg_anniversary_2026.avif"
    imageSize = [1200, 554]
  }
  china_tanks_early_access = {
    image = "ui/images/tanks_china_tree_info.avif"
  }
  spend_event_lunar_ny = {
    image = "ui/images/spending_event_lunar_info.avif"
  }
  uk_air_early_access = {
    image = "ui/images/event_bg_uk_air_early_access.avif"
  }
  japan_tanks_early_access = {
    image = "ui/images/tanks_japan_tree_info.avif"
  }
  collectors_pass_tanks_s35 = {
    image = "ui/images/blueprint_folder_bg_tanks.avif"
    innerImage = "ui/gameuiskin/past_events_box_seasons_1_to_32.avif"
  }
  collectors_pass_ships_s35 = {
    image = "ui/images/ship_blueprint_bg.avif"
    innerImage = "ui/gameuiskin/past_events_box_seasons_1_to_32.avif"
  }
  collectors_pass_air_s35 = {
    image = "ui/images/air_beta_access_bg.avif"
    innerImage = "ui/gameuiskin/past_events_box_seasons_1_to_32.avif"
  }
  senrai_maidens = {
    image = "ui/images/WTM_anime_2700x1080.avif"
    imageSize = [1200, 480]
  }
}

return memoize(@(id) mkDefPresentation(id).__update(presentations?[id] ?? {}))
