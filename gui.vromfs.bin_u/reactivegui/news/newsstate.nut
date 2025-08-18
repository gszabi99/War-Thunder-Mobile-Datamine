from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
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
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
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
let getFeedUrl = $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/?platform={newsPlatform}"
let getArticleUrl = @(id) $"https://newsfeed.gap.gaijin.net/api/patchnotes/{cfgId}/{shortLang}/{id}/?platform={newsPlatform}"

let receivedArticles = hardPersistWatched("news.receivedArticles", {})
let newsfeed = hardPersistWatched("news.newsfeed", [])
let requestMadeTime = hardPersistWatched("news.requestMadeTime", 0)
let isNewsWndOpened = mkWatched(persist, "isOpened", false)
let isFeedReceived = Computed(@() newsfeed.get().len() > 0)
let receivedNewsFeedLang = persist("receivedNewsFeedLang", @() { value = null })
let playerSelectedArticleId = Watched(null)
let lastSeenId = Watched(-1)
let articlesPerPage = Watched(8)
let unreadArticles = hardPersistWatched("news.unreadArticles" {})

let updateUnreadArticles = @() unreadArticles.mutate(function(v) {
  let lastId = lastSeenId.get()
  v.clear()
  foreach (_idx, info in newsfeed.get())
    if (info.id > lastId)
      v[info.id] <- true
})

if (receivedNewsFeedLang.value != shortLang) {
  receivedArticles({})
  newsfeed([])
  unreadArticles({})
  requestMadeTime(0)
}

let unseenArticleId = Computed(function() {
  if (lastSeenId.get() == -1)
    return null
  
  let lastId = lastSeenId.get()
  foreach (idx, info in newsfeed.get()) {
    if (idx >= articlesPerPage.get())
      break
    if (info.pinned > 0 && info.id > lastId)
      return info.id
  }
  
  local res = null
  foreach (idx, info in newsfeed.get()) {
    if (idx >= articlesPerPage.get())
      break
    if (info.id > lastId)
      res = info.id
  }
  return res
})

let curArticleId = Computed(function() {
  let id = playerSelectedArticleId.get()
  if (id != null && newsfeed.get().findvalue(@(v) v.id == id) != null)
    return id
  return unseenArticleId.get() ?? newsfeed.get()?[0].id
})
let curArticleContent = Computed(@() receivedArticles.get()?[curArticleId.get()])
let curArticleIdx = Computed(@() newsfeed.get().findindex(@(v) v.id == curArticleId.get()) ?? -1)
let haveUnseenArticles = Computed(@() unseenArticleId.get() != null)
let needShowNewsWnd = Computed(@() isMainMenuAttached.get()
  && haveUnseenArticles.get()
  && (sharedStats.get()?.sessionsCountPersist ?? 0) >= MIN_SESSIONS_TO_FORCE_SHOW
  && !hasModalWindows.get()
  && (curArticleContent.get()?.id ?? EMPTY_PAGE_ID) != EMPTY_PAGE_ID
)

let pagesCount = Computed(@() ceil(newsfeed.get().len() * 1.0 / articlesPerPage.get()))
let curPageIdx = Computed(@() curArticleIdx.get() / articlesPerPage.get())

function saveLastSeenId(id) {
  lastSeenId.set(id)
  let sBlk = get_local_custom_settings_blk()
  setBlkValueByPath(sBlk, SEEN_SAVE_ID, id)
  eventbus_send("saveProfile", {})
}

isNewsWndOpened.subscribe(function (v) {
  if (haveUnseenArticles.get())
    playerSelectedArticleId.set(null)

  if (v)
    updateUnreadArticles()
  else
    saveLastSeenId(newsfeed.get().reduce(@(res, val) max(res, val.id), lastSeenId.get()))
})

function loadLastSeenArticleId() {
  let sBlk = get_local_custom_settings_blk()
  lastSeenId.set(getBlkValueByPath(sBlk, SEEN_SAVE_ID) ?? 0)
  updateUnreadArticles()
}
isOnlineSettingsAvailable.subscribe(@(v) v ? loadLastSeenArticleId() : null)
if (isOnlineSettingsAvailable.get())
  loadLastSeenArticleId()

function markArticleSeenById(id) {
  if (unreadArticles.get()?[id])
    unreadArticles.mutate(@(v) v.$rawdelete(id))
}

let markCurArticleSeen = @() markArticleSeenById(curArticleId.get())

let sortNewsfeed = @(a, b) b.pinned <=> a.pinned
  || b.iDate <=> a.iDate
  || b.id <=> a.id

function mkInfo(v) {
  let { id = null, date = null, title = "", thumb = null, pinned = 0, tags = [] } = v
  if (type(id) != "integer") {
    logerr($"Bad newsfeed id type: {type(id)}  (id = {id})")
    return null
  }
  let iDate = type(date) == "string" ? (parse_unix_time(date) ?? -1) : -1
  local shortTitle = v?.titleshort ?? "undefined"
  if (shortTitle == "undefined" || utf8(shortTitle).charCount() > 50)
    shortTitle = null
  return { id, iDate, date, title, shortTitle, thumb, pinned, tags }
}

eventbus_subscribe(NEWSFEED_RECEIVED, function processNewsFeedList(response) {
  let { status = -1, http_code = -1, context = "" } = response
  if (context != shortLang)
    return 

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
  updateUnreadArticles()
  receivedNewsFeedLang.value = shortLang
})

function requestNewsFeed() {
  let currTimeMsec = get_time_msec()
  if (requestMadeTime.get() > 0
      && (currTimeMsec - requestMadeTime.get() < MSEC_BETWEEN_REQUESTS))
    return

  httpRequest({
    method = "GET"
    url = getFeedUrl
    context = shortLang
    respEventId = NEWSFEED_RECEIVED
  })
  requestMadeTime(currTimeMsec)
}

isMainMenuAttached.subscribe(@(v) v ? requestNewsFeed() : null)

let ERROR_PAGE = {
  id = EMPTY_PAGE_ID
  title = loc("browser/error_load_url") 
  content = [ { v = loc("yn1/error/80022B30") } ] 
}

eventbus_subscribe(ARTICLE_RECEIVED, function onArticleReceived(response) {
  let { status = -1, http_code = -1, context = null } = response
  let { id = null, lang = null } = context
  if (lang != shortLang)
    return 

  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code || id == null) {
    logN($"Error getting article #{id} response (http_code = {response?.http_code}, status = {status})")
    if (id != null)
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

function requestNewsArticle(id) {
  if (id == null || (receivedArticles.get()?[id].id ?? EMPTY_PAGE_ID) != EMPTY_PAGE_ID)
    return

  if (id in receivedArticles.get())
    receivedArticles.mutate(@(v) v.$rawdelete(id))

  httpRequest({
    method = "GET"
    url = getArticleUrl(id)
    context = { id, lang = shortLang }
    respEventId = ARTICLE_RECEIVED
  })
}

function changeArticle(delta = 1) {
  if (newsfeed.get().len() == 0)
    return
  let nextIdx = clamp(curArticleIdx.get() - delta, 0, newsfeed.get().len() - 1)
  let item = newsfeed.get()[nextIdx]
  markCurArticleSeen()
  playerSelectedArticleId.set(item.id)
}

let openNewsWnd = @() isNewsWndOpened.set(true)
let openNewsWndIfNeed = @() needShowNewsWnd.get() ? openNewsWnd() : null
needShowNewsWnd.subscribe(@(v) v ? setTimeout(0.1, openNewsWndIfNeed) : clearTimer(openNewsWndIfNeed))

function openNewsWndTagged(tag) {
  let article = newsfeed.get().findvalue(@(v) v.tags?.contains(tag))
  if (article)
    playerSelectedArticleId.set(article.id)
  else
    logN($"No news article found with tag: \"{tag}\"")
  openNewsWnd()
}

let requestCurArticle = @() requestNewsArticle(curArticleId.get())
isFeedReceived.subscribe(function(value) {
  if (value && (haveUnseenArticles.get() || isNewsWndOpened.get()))
    requestCurArticle()
})
isNewsWndOpened.subscribe(@(v) v ? requestCurArticle() : null)
curArticleId.subscribe(@(v) isNewsWndOpened.get() ? requestNewsArticle(v) : null)
if (isLoggedIn.get() && isFeedReceived.get() && (isNewsWndOpened.get() || haveUnseenArticles.get()))
  requestCurArticle()

register_command(@() saveLastSeenId(0), "ui.resetNewsSeen")

register_command(function(count) {
  let news = clone newsfeed.get()
  news.sort(@(a, b) b.id <=> a.id)
  saveLastSeenId(news?[count]?.id ?? 0)
}, "ui.resetNewsSeenOnlyLast")

return {
  isNewsWndOpened
  newsfeed
  playerSelectedArticleId
  curArticleId
  curArticleIdx
  curArticleContent
  isFeedReceived

  openNewsWnd
  closeNewsWnd = @() isNewsWndOpened.set(false)
  openNewsWndTagged

  unreadArticles
  markCurArticleSeen

  articlesPerPage
  pagesCount
  curPageIdx
  nextArticle = @() changeArticle(1)
  prevArticle = @() changeArticle(-1)
}
