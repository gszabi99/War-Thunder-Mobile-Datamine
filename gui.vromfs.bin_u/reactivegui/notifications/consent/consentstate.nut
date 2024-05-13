from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")

let isOpenedConsentWnd = mkWatched(persist, "consentMain", false)
let isOpenedManage = mkWatched(persist, "consentManage", false)
let isOpenedPartners = mkWatched(persist, "consentPartners", false)

let configManagePoints = [
  {
    id = "analytics_storage"
    loc = "consentWnd/manage/desc/analytics_storage"
  }
  {
    id = "ad_storage"
    loc = "consentWnd/manage/desc/ad_storage"
  }
  {
    id = "ad_user_data"
    loc = "consentWnd/manage/desc/ad_user_data"
  }
  {
    id = "ad_personalization"
    loc = "consentWnd/manage/desc/ad_personalization"
  }
]

let managePointsTable = configManagePoints.reduce(@(res, val) res.$rawset(val.id, true), {})

let points = Watched(managePointsTable)
eventbus_subscribe("consent.getConsentSettings", @(s) points(s))

return {
  isOpenedConsentWnd
  isOpenedManage
  isOpenedPartners

  points
}