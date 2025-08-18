let presentations = {
  event_new_year = {
    icon = "event_christmas_gift_box.avif"
    link = "auto_local auto_login https://wtmobile.com/news/winter-gifts-2024"
    locId = "mainmenu/btnSendGift"
  }
  anniversary_2025 = {
    icon = "event_anniversary_gift_box.avif"
    link = "auto_local auto_login https://wtmobile.com/news/summer-gifts-2025"
    locId = "mainmenu/btnSendGift"
  }
}

return {
  getGiftPresentation = @(id) presentations?[id] ?? {}
  availableGifts = presentations
}
