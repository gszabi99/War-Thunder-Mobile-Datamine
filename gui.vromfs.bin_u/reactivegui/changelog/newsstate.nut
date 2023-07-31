from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")
let { ceil } = require("math")
let utf8 = require("utf8")
let { httpRequest, HTTP_SUCCESS } = require("dagor.http")
let { parse_unix_time } = require("dagor.iso8601")
let { get_time_msec } = require("dagor.time")
let { setTimeout, clearTimer } = require("dagor.workcycle")
let { parse_json } = require("json")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { get_cur_circuit_name } = require("app")
let { platformId } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn, isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { get_blk_value_by_path, set_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { sharedStats } = require("%appGlobals/pServer/campaign.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let logN = log_with_prefix("[NEWSFEED] ")

const NEWSFEED_RECEIVED = "NewsFeedReceived"
const ARTICLE_RECEIVED = "NewsArticleReceived"
const SEEN_SAVE_ID = "news/lastSeenId"
const MSEC_BETWEEN_REQUESTS = 600000
const MIN_SESSIONS_TO_FORCE_SHOW = 5
const EMPTY_PAGE_ID = -1

let shortLang = loc("current_lang")
let newsPlatform = platformId == "android" ? "android" : "ios"
let cfgId = get_cur_circuit_name().indexof("production") != null || get_cur_circuit_name().indexof("stable") != null
  ? "wtm_production" : "wtm_test"
let getFeedUrl = $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/?platform={newsPlatform}&kind=news"
let getArticleUrl = @(id) $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/{id}/?platform={newsPlatform}"

let receivedArticles = hardPersistWatched("news.receivedArticles", {})
let newsfeed = hardPersistWatched("news.newsfeed", [])
let isNewsWndOpened = mkWatched(persist, "isOpened", false)
let isFeedReceived = Computed(@() newsfeed.value.len() > 0)
let receivedNewsFeedLang = persist("receivedNewsFeedLang", @() { value = null })
let playerSelectedArticleId = Watched(null)
let lastSeenId = Watched(-1)
let articlesPerPage = Watched(8)
local requestMadeTime = 0

if (receivedNewsFeedLang.value != shortLang) {
  receivedArticles({})
  newsfeed([])
}

let unseenArticleId = Computed(function() {
  if (lastSeenId.value == -1)
    return null
  // Searching for the newest unseen Pinned article on the first page.
  let lastId = lastSeenId.value
  foreach (idx, info in newsfeed.value) {
    if (idx >= articlesPerPage.value)
      break
    if (info.isPinned && info.id > lastId)
      return info.id
  }
  // Searching for the oldest unseen ordinary article on the first page.
  local res = null
  foreach (idx, info in newsfeed.value) {
    if (idx >= articlesPerPage.value)
      break
    if (info.id > lastId)
      res = info.id
    else
      break
  }
  return res
})

let curArticleId = Computed(function() {
  let id = playerSelectedArticleId.value
  if (id != null && newsfeed.value.findvalue(@(v) v.id == id) != null)
    return id
  return unseenArticleId.value ?? newsfeed.value?[0].id
})
let curArticleContent = Computed(@() receivedArticles.value?[curArticleId.value])
let curArticleIdx = Computed(@() newsfeed.value.findindex(@(v) v.id == curArticleId.value) ?? -1)
let haveUnseenArticles = Computed(@() unseenArticleId.value != null)
let needShowNewsWnd = Computed(@() isMainMenuAttached.value
  && haveUnseenArticles.value
  && (sharedStats.value?.sessionsCountPersist ?? 0) >= MIN_SESSIONS_TO_FORCE_SHOW
  && !hasModalWindows.value
  && (curArticleContent.value?.id ?? EMPTY_PAGE_ID) != EMPTY_PAGE_ID
)

let pagesCount = Computed(@() ceil(newsfeed.value.len() * 1.0 / articlesPerPage.value))
let curPageIdx = Computed(@() curArticleIdx.value / articlesPerPage.value)

isNewsWndOpened.subscribe(@(_) haveUnseenArticles.value ? playerSelectedArticleId(null) : null)

let function loadLastSeenArticleId() {
  let sBlk = get_local_custom_settings_blk()
  lastSeenId(get_blk_value_by_path(sBlk, SEEN_SAVE_ID) ?? 0)
}
isOnlineSettingsAvailable.subscribe(@(v) v ? loadLastSeenArticleId() : null)
if (isOnlineSettingsAvailable.value)
  loadLastSeenArticleId()

let isArticleSeen = @(id, lastSeenIdVal) id <= lastSeenIdVal

let function markArticleSeenById(id) {
  if (isArticleSeen(id, lastSeenId.value))
    return
  lastSeenId(id)
  let sBlk = get_local_custom_settings_blk()
  set_blk_value_by_path(sBlk, SEEN_SAVE_ID, id)
  send("saveProfile", {})
}

let markCurArticleSeen = @() markArticleSeenById(curArticleId.value)
let markAllArticlesSeen = @()
  markArticleSeenById(newsfeed.value.reduce(@(res, v) max(res, v.id), -1))

let sortNewsfeed = @(a, b) b.isPinned <=> a.isPinned
  || b.iDate <=> a.iDate
  || b.id <=> a.id

let function mkInfo(v) {
  let { id = null, date = null, title = "", thumb = null, alwaysShowPopup = false } = v
  if (type(id) != "integer") {
    logerr($"Bad newsfeed id type: {type(id)}  (id = {id})")
    return null
  }
  let iDate = type(date) == "string" ? (parse_unix_time(date) ?? -1) : -1
  local shortTitle = v?.titleshort ?? "undefined"
  if (shortTitle == "undefined" || utf8(shortTitle).charCount() > 50)
    shortTitle = null
  return { id, iDate, date, title, shortTitle, thumb, isPinned = alwaysShowPopup }
}

subscribe(NEWSFEED_RECEIVED, function processNewsFeedList(response) {
  let { status = -1, http_code = -1, context = "" } = response
  if (context != shortLang)
    return // Ingnore request result for wrong lang

  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    logN($"Error getting feed response (http_code = {response?.http_code}, status = {status})")
    return
  }

  local result = null
  try {
    result = parse_json(response.body.as_string()).result
  }
  catch(e) {
    logN($"Error parsing JSON in feed response: {e}")
    return
  }

  logN($"Feed received successfully ({result.len()} items)")
  let arr = result.map(mkInfo).filter(@(v) v != null)
  arr.sort(sortNewsfeed)
  newsfeed(arr)
  receivedNewsFeedLang.value = shortLang
})

let function requestNewsFeed() {
  let currTimeMsec = get_time_msec()
  if (requestMadeTime > 0
      && (currTimeMsec - requestMadeTime < MSEC_BETWEEN_REQUESTS))
    return

  httpRequest({
    method = "GET"
    url = getFeedUrl
    context = shortLang
    respEventId = NEWSFEED_RECEIVED
  })
  requestMadeTime = currTimeMsec
}

isMainMenuAttached.subscribe(@(v) v ? requestNewsFeed() : null)

let ERROR_PAGE = {
  id = EMPTY_PAGE_ID
  title = loc("browser/error_load_url") // Error loading page
  content = [ { v = loc("yn1/error/80022B30") } ] // Please try again later
}

subscribe(ARTICLE_RECEIVED, function onArticleReceived(response) {
  let { status = -1, http_code = -1, context = null } = response
  let { id = null, lang = null } = context
  if (lang != shortLang)
    return // Ingnore request result for wrong lang

  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code || id == null) {
    logN($"Error getting article #{id} response (http_code = {response?.http_code}, status = {status})")
    receivedArticles.mutate(@(v) v[id] <- ERROR_PAGE)
    return
  }

  local result = null
  try {
    result = parse_json(response.body.as_string()).result
  }
  catch(e) {
    logN($"Error parsing JSON in article #{id} response: {e}")
    receivedArticles.mutate(@(v) v[id] <- ERROR_PAGE)
    return
  }

  logN($"News article #{id} received successfully")
  receivedArticles.mutate(@(v) v[id] <- result)
})

let function requestNewsArticle(id) {
  if (id == null || (receivedArticles.value?[id].id ?? EMPTY_PAGE_ID) != EMPTY_PAGE_ID)
    return

  if (id in receivedArticles.value)
    receivedArticles.mutate(@(v) delete v[id])

  httpRequest({
    method = "GET"
    url = getArticleUrl(id)
    context = { id, lang = shortLang }
    respEventId = ARTICLE_RECEIVED
  })
}

let function changeArticle(delta = 1) {
  if (newsfeed.value.len() == 0)
    return
  let nextIdx = clamp(curArticleIdx.value - delta, 0, newsfeed.value.len() - 1)
  let item = newsfeed.value[nextIdx]
  markCurArticleSeen()
  playerSelectedArticleId(item.id)
}

let openNewsWnd = @() isNewsWndOpened(true)
let openNewsWndIfNeed = @() needShowNewsWnd.value ? openNewsWnd() : null
needShowNewsWnd.subscribe(@(v) v ? setTimeout(0.1, openNewsWndIfNeed) : clearTimer(openNewsWndIfNeed))

let requestCurArticle = @() requestNewsArticle(curArticleId.value)
isFeedReceived.subscribe(function(value) {
  if (value && (haveUnseenArticles.value || isNewsWndOpened.value))
    requestCurArticle()
})
isNewsWndOpened.subscribe(@(v) v ? requestCurArticle() : null)
curArticleId.subscribe(@(v) isNewsWndOpened.value ? requestNewsArticle(v) : null)
if (isLoggedIn.value && isFeedReceived.value && (isNewsWndOpened.value || haveUnseenArticles.value))
  requestNewsArticle(curArticleId.value)

register_command(function() {
  lastSeenId(0)
  let sBlk = get_local_custom_settings_blk()
  set_blk_value_by_path(sBlk, SEEN_SAVE_ID, 0)
  send("forceSaveProfile", {})
}, "ui.resetNewsSeen")

return {
  isNewsWndOpened
  newsfeed
  playerSelectedArticleId
  curArticleId
  curArticleIdx
  curArticleContent
  isFeedReceived

  openNewsWnd
  closeNewsWnd = @() isNewsWndOpened(false)

  lastSeenId
  isArticleSeen
  markCurArticleSeen
  markAllArticlesSeen

  articlesPerPage
  pagesCount
  curPageIdx
  nextArticle = @() changeArticle(1)
  prevArticle = @() changeArticle(-1)
}
