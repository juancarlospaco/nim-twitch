## **Docs, Info, etc:** https://dev.twitch.tv/docs/api/reference/
## Twitch Legacy API v5 Kraken or older is NOT supported.
## https://dev.twitch.tv/docs/api/reference/#get-streams-metadata is NOT supported.
# Follow & Subscribe my Nim coding live stream: https://www.twitch.tv/juancarlospaco
import asyncdispatch, httpclient, strutils, json, times, macros

const
  twitchApiUrl* = "https://api.twitch.tv/helix/" ## Twitch API URL (SSL).
  twitchAuth = "https://id.twitch.tv/oauth2/"    ## Twitch OAuth URL (SSL).
  t = "T00:00:00Z"  ## API uses zeroed-time on a ISO datetime as date.
  validPeriods = ["day", "week", "month", "year", "all"] ## Valid periods for API.
  validSorts = ["time", "trending", "views"]             ## Valid sorts for API.
  validTypes = ["all", "upload", "archive", "highlight"] ## Valid types for API.

type
  TwitchBase*[HttpType] = object ## Base object.
    timeout*: byte  ## Timeout Seconds for API Calls, byte type, 1~255.
    proxy*: Proxy  ## Network IPv4 / IPv6 Proxy support, Proxy type.
    api_key*: string ## Required valid Twitch API Key, Twitch OAuth access token.
  Twitch* = TwitchBase[HttpClient]           ##  Sync Twitch API Client.
  AsyncTwitch* = TwitchBase[AsyncHttpClient] ## Async Twitch API Client.

  # TwitchScopes = enum           ## https://dev.twitch.tv/docs/authentication/#scopes
  #   analytics:read:extensions   ## View analytics data for your extensions.
  #   analytics:read:games        ## View analytics data for your games.
  #   bits:read                   ## View Bits information for your channel.
  #   channel:read:subscriptions  ## Get a list of all subscribers to your channel and check if a user is subscribed to your channel
  #   clips:edit                  ## Manage a clip object.
  #   user:edit                   ## Manage a user object.
  #   user:edit:broadcast         ## Edit your channel’s broadcast configuration, including extension configuration. (This scope implies user:read:broadcast capability.)
  #   user:read:broadcast         ## View your broadcasting configuration, including extension configurations.
  #   user:read:email             ## Read authorized user’s email address.
  #   channel:moderate            ## Perform moderation actions in a channel. The user requesting the scope must be a moderator in the channel.
  #   chat:edit                   ## Send live stream chat and rooms messages.
  #   chat:read                   ## View live stream chat and rooms messages.
  #   whispers:read               ## View your whisper messages.
  #   whispers:edit               ## Send whisper messages.

# using gameId: string

template clientify(this: Twitch | AsyncTwitch): untyped =
  ## Build & inject basic HTTP Client with Proxy and Timeout.
  var client {.inject.} =
    when this is AsyncTwitch: newAsyncHttpClient(
      proxy = when declared(this.proxy): this.proxy else: nil, userAgent="")
    else: newHttpClient(
      timeout = when declared(this.timeout): this.timeout.int * 1_000 else: -1,
      proxy = when declared(this.proxy): this.proxy else: nil, userAgent="")
  client.headers = newHttpHeaders({
    "accept": "application/json", "content-type": "application/json",
    "dnt": "1", "Authorization": "Bearer " & this.api_key})

macro argify(n: string, v: typed): typed =
  ## Macro to automate a ternary operator like construct for URL params.
  result = parseStmt("""let $2 = if $1 == "": "" else: "&$1=" & $1""".format(v.strVal, n))

# proc authValidate*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ## https://dev.twitch.tv/docs/authentication/#validating-requests
#   clientify(this)
#   result =
#     when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "validate"))
#     else: parseJson(client.getContent(twitchAuth & "validate"))

# proc authRevoque*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ## https://dev.twitch.tv/docs/authentication/#revoking-access-tokens
#   POST https://id.twitch.tv/oauth2/revoke
#   ?client_id=<your client ID>
#   &token=<your OAuth token>
#   clientify(this)
#   result =
#     when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "revoque"))
#     else: parseJson(client.getContent(twitchAuth & "revoque"))

# proc authRefresh*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ## https://dev.twitch.tv/docs/authentication/#refreshing-access-tokens
#   POST https://id.twitch.tv/oauth2/token
#     --data-urlencode
#     ?grant_type=refresh_token
#     &refresh_token=<your refresh token>
#     &client_id=<your client ID>
#     &client_secret=<your client secret>
#   clientify(this)
#   result =
#     when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "revoque"))
#     else: parseJson(client.getContent(twitchAuth & "revoque"))

# proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ##  https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-implicit-code-flow
#   GET https://id.twitch.tv/oauth2/authorize
#     ?client_id=<your client ID>
#     &redirect_uri=<your registered redirect URI>
#     &response_type=<type>
#     &scope=<space-separated list of scopes>

# proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ##  https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-authorization-code-flow
#   GET https://id.twitch.tv/oauth2/authorize
#     ?client_id=<your client ID>
#     &redirect_uri=<your registered redirect URI>
#     &response_type=code
#     &scope=<space-separated list of scopes>

# proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
#   ## https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-client-credentials-flow
#   POST https://id.twitch.tv/oauth2/token
#     ?client_id=<your client ID>
#     &client_secret=<your client secret>
#     &grant_type=client_credentials
#     &scope=<space-separated list of scopes>



# Analytics ###################################################################


proc getExtensionAnalytics(first: range[1..100] = 20,
    after="", extension_id = "", started_at = "2018-01-31" & t,
    ended_at = getDateStr() & t, `type`="overview_v2"): string =
  ## https://dev.twitch.tv/docs/api/reference/#get-extension-analytics
  ## Get 1 URL that extension devs use to download analytics for extensions.
  ## The URL is valid for 5 minutes. Scope ``analytics:read:extensions``
  ## If you specify a future date, the response will be "Report Not Found."
  ## If you leave both ``started_at`` & ``ended_at`` blank, gets most recent date.
  assert `type` in ["overview_v1", "overview_v2"], "Type invalid value: " & `type`
  assert started_at.endsWith(t), "Started_at invalid value: " & started_at
  assert ended_at.endsWith(t), "Ended_at invalid value: " & ended_at
  let
    a = "?type=" & `type`
    b = if first == 20: "" else: "&first=" & $first
    c = "&started_at=" & started_at
    d = "&ended_at=" & ended_at
  argify("e", after)
  argify("f", extension_id)
  let url = twitchApiUrl & "analytics/extensions" & a & b & c & d & e & f
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getGameAnalytics(first: range[1..100] = 20,
  after="", game_id = "", started_at = getDateStr() & t,
  ended_at = getDateStr() & t, `type`="overview_v2"): string =
  ## https://dev.twitch.tv/docs/api/reference/#get-game-analytics
  ## Get a URL that game devs can use to download analytics for their games.
  ## URL is valid for 5 minutes.
  assert `type` in ["overview_v1", "overview_v2"], "Type invalid value: " & `type`
  assert started_at.endsWith(t), "Started_at invalid value: " & started_at
  assert ended_at.endsWith(t), "Ended_at invalid value: " & ended_at
  let
    a = "?type=" & `type`
    b = if first == 20: "" else: "&first=" & $first
    c = "&started_at=" & started_at
    d = "&ended_at=" & ended_at
  argify("e", after)
  argify("f", game_id)
  let url = twitchApiUrl & "analytics/games" & a & b & c & d & e & f
  when not defined(release): echo url
  return ""
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Bits ########################################################################


proc getBitsLeaderboard(count: range[1..100] = 10,
  period="all", user_id = "", started_at = getDateStr() & t): string =
  ## https://dev.twitch.tv/docs/api/reference/#get-bits-leaderboard
  ## Gets a ranked list of Bits leaderboard information for an authorized broadcaster.
  assert period in validPeriods, "Period must be one of " & $validPeriods
  assert started_at.endsWith(t), "Started_at invalid value: " & started_at
  let
    a = "?period=" & period
    b = if count == 10: "" else: "&count=" & $count
    c = "&started_at=" & started_at
  argify("d", user_id)
  let url = twitchApiUrl & "bits/leaderboard" & a & b & c & d
  when not defined(release): echo url
  return ""
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Clips #######################################################################


proc createClip(broadcaster_id: string, has_delay=false): auto =
  ## https://dev.twitch.tv/docs/api/reference/#create-clip
  ## Make a clip programmatically. Returns ID & URL for the new clip.
  ## Clip creation takes time.
  ## We recommend you query Get Clips, with clip ID that is returned here.
  ## If Get Clips returns a valid clip, your clip creation was successful.
  ## If after 15 seconds you got no valid clip from Get Clips,
  ## assume that the clip was not created and retry Create Clip.
  ## This endpoint has a global rate limit, across all callers.
  assert broadcaster_id.strip.len > 0, "broadcaster_id must not be empty string"
  let a = "?has_delay=" & $has_delay
  argify("b", broadcaster_id)
  let url = twitchApiUrl & "clips" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getClips(broadcaster_id="", game_id="", id=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-clips
  ## Get clips info by Clip ID (1 or more), Broadcaster ID (1), or Game ID (1).
  assert (broadcaster_id.len > 0 or game_id.len > 0 or id.len > 0), "Missing argument"
  argify("a", broadcaster_id)
  argify("b", broadcaster_id)
  argify("c", broadcaster_id)
  let url = twitchApiUrl & "clips" & a & b & c
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Entitlements ################################################################


proc createEntitlementUploadURL(manifest_id: string): auto =
  ## https://dev.twitch.tv/docs/api/reference/#create-entitlement-grants-upload-url
  ## Create 1 URL where you can upload manifest, notify users they have an entitlement.
  ## Entitlements are digital items that users are entitled to use.
  ## Entitlements are granted to users gratis or as part of purchase on Twitch.
  assert manifest_id.len > 0 and manifest_id.len < 64, "manifest_id must be string from 1 to 64 chars"
  const a = "?type=bulk_drops_grant" # Only supported so is hardcoded.
  argify("b", manifest_id)
  let url = twitchApiUrl & "entitlements/upload" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getCodeStatus(user_id: int, codes: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-code-status
  ## Get status of provided codes. Requires that caller is authenticated user.
  ## The API is throttled to one request per second per authenticated user.
  assert user_id > 0, "user_id must be non-zero positive integer"
  assert codes.len > 0 and codes.len < 20, "codes must be seq[string] from 1 to 20 lenght"
  let a = "?user_id=" & $user_id
  var b: string
  for item in codes:
    b.add "&code=" & item
  let url = twitchApiUrl & "entitlements/codes" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc redeemCode(user_id: int, codes: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#redeem-code
  ## This API requires that the caller is an authenticated Twitch user.
  ## The API is throttled to one request per second per authenticated user.
  assert user_id > 0, "user_id must be non-zero positive integer"
  assert codes.len > 0 and codes.len < 20, "codes must be seq[string] from 1 to 20 lenght"
  let a = "?user_id=" & $user_id
  var b: string
  for item in codes:
    b.add "&code=" & item
  let url = twitchApiUrl & "entitlements/codes" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Games #######################################################################


proc getTopGames(first: range[1..100] =  20, before="", after=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-top-games
  ## Gets games sorted by number of current viewers on Twitch, most popular first.
  let a = "?first=" & $first
  argify("b", before)
  argify("c", after)
  let url = twitchApiUrl & "games/top" & a & b & c
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getGames(id="", name=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-games
  ## Gets game information by game ID or name.
  assert id.len > 0 or name.len > 0, "ID Or Name must be provided, bad args"
  argify("a", id)
  argify("b", name)
  let url = twitchApiUrl & "games" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Streams #####################################################################


proc getStreams(first: range[1..100] = 20, before="", after="", language = @["en"],
    community_id= @[""], game_id= @[""], user_id= @[""], user_login= @[""]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-streams
  ## Gets information about active streams.
  ## Streams are returned sorted by number of current viewers, in descending order.
  assert language.len < 100, "language must be seq[string] of 100 strings max"
  assert community_id.len < 100, "community_id must be seq[string] of 100 strings max"
  assert game_id.len < 100, "game_id must be seq[string] of 100 strings max"
  assert user_id.len < 100, "user_id must be seq[string] of 100 strings max"
  assert user_login.len < 100, "user_login must be seq[string] of 100 strings max"
  let a = "?first=" & $first
  argify("b", before)
  argify("c", after)
  var d, e, f, g, h: string
  for item in language:     d.add "&language=" & item
  if community_id != @[""]: (for item in community_id: e.add "&community_id=" & item)
  if game_id != @[""]:      (for item in game_id:      f.add "&game_id=" & item     )
  if user_id != @[""]:      (for item in user_id:      g.add "&user_id=" & item     )
  if user_login != @[""]:   (for item in user_login:   h.add "&user_login=" & item  )
  let url = twitchApiUrl & "streams" & a & b & c & d & e & f & g & h
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc createStreamMarker(user_id: string, description=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-streams-metadata
  ## Creates a marker in the stream of a user specified by a user ID.
  ## Marker is an arbitrary point in stream that broadcaster wants to mark.
  ## Marker is created at current timestamp in live broadcast when request is processed.
  ## Markers can be created by the stream owner or editors.
  assert user_id.len > 0, "user_id must be not be an empty string"
  let
    body = {"user_id": user_id, "description": description}
    url = twitchApiUrl & "streams/markers"  # POST
  when not defined(release): echo body
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getStreamMarkers(user_id="", video_id="", first: range[1..100] = 20, before="", after=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-stream-markers
  ## Get 1 list of markers for specified user recent stream/VOD, ordered by recency.
  ## Marker is an arbitrary point in a stream that the broadcaster wants to mark.
  assert user_id.len > 0 or video_id.len > 0, "1 of user_id or video_id must be specified"
  let a = "?first=" & $first
  argify("b", user_id)
  argify("c", video_id)
  argify("d", before)
  argify("e", after)
  let url = twitchApiUrl & "streams/markers" & a & b & c & d & e
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Subscriptions ###############################################################


proc getBroadcasterSubscriptions(broadcaster_id: string): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-broadcaster-subscriptions
  ## Get all of a broadcasters subscriptions.
  assert broadcaster_id.len > 0, "broadcaster_id must not be empty string"
  let url = twitchApiUrl & "subscriptions" & "?broadcaster_id=" & broadcaster_id
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getUserSubscriptions(broadcaster_id: string, user_id: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-user-subscriptions
  ## Gets broadcasters subscriptions by user ID (1 or more).
  assert broadcaster_id.len > 0, "broadcaster_id must not be empty string"
  assert user_id.len < 100, "user_id must be seq[string] of 100 strings max"
  let a = "?broadcaster_id=" & broadcaster_id
  var b: string
  for item in user_id:
    b.add "&user_id=" & item
  let url = twitchApiUrl & "subscriptions" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Tags ########################################################################


proc getAllStreamTags(after="", first: range[0..100] = 20, tag_id: seq[string] = @[""]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-all-stream-tags
  ## Get 1 list of all stream tags defined by Twitch, optional filter by tag ID.
  assert tag_id.len < 100, "user_id must be seq[string] of 100 strings max"
  let a = "?first=" & $first
  argify("b", after)
  var c: string
  for item in tag_id:
    c.add "&tag_id=" & item
  let url = twitchApiUrl & "tags/streams" & a & b & c
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getStreamTags(broadcaster_id: string): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-stream-tags
  ## Gets the list of tags for a specified stream (channel).
  ## JSON Response is an array of tag elements.
  assert broadcaster_id.len > 0, "broadcaster_id must not be empty string"
  let url = twitchApiUrl & "streams/tags" & "?broadcaster_id=" & broadcaster_id
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc replaceStreamTags(broadcaster_id: string, tag_ids: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#replace-stream-tags
  ## Set tags to specified stream, overwriting existing tags to that stream.
  ## If no tags specified, all tags previously applied to stream are removed.
  ## Automated tags are not affected by this operation.
  ## Tags expire 72 hours after they are applied, unless stream is live.
  assert broadcaster_id.len > 0, "broadcaster_id must not be empty string"
  assert tag_ids.len < 100, "tag_ids must be seq[string] of 100 strings max"
  let a = "?broadcaster_id=" & broadcaster_id
  let body = {"tag_ids": tag_ids}
  let url = twitchApiUrl & "streams/tags" & a  # POST
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Users #######################################################################

proc getUsers(id, login: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-users
  ## Gets information about one or more specified Twitch users.
  ## Users are identified by optional user IDs and/or login name.
  ## If no user ID nor login name is specified, user is looked up by Bearer token.
  assert login.len < 100, "login must be seq[string] of 100 strings max"
  assert id.len < 100, "id must be seq[string] of 100 strings max"
  assert id.len > 0 or login.len > 0, "At least 1 argument must be provided"
  var a: string
  for item in id:
    a.add "&id=" & item
  var b: string
  for item in login:
    b.add "&login=" & item
  let url = twitchApiUrl & "users?" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getUsersFollows(id, login: seq[string]): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-users-follows
  ## Gets information on follow relationships between two Twitch users.
  ## Information returned is sorted in order, most recent follow first.
  ## This can return information like :
  ## who is USER following?, who is following USER?, is USER following OTHERUSER?
  assert login.len < 100, "login must be seq[string] of 100 strings max"
  assert id.len < 100, "id must be seq[string] of 100 strings max"
  assert id.len > 0 or login.len > 0, "At least 1 argument must be provided"
  var a: string
  for item in id:
    a.add "&id=" & item
  var b: string
  for item in login:
    b.add "&login=" & item
  let url = twitchApiUrl & "users/follows" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc updateUser(description: string): auto =
  ## https://dev.twitch.tv/docs/api/reference/#update-user
  ## Updates the description of a user specified by a Bearer token.
  assert description.len > 0, "description must not be empty string"
  let url = twitchApiUrl & "users/follows?description=" & description # quote?
  when not defined(release): echo url  # PUT
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getUserExtensions(): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-user-extensions
  ## Gets 1 list of all extensions (active & inactive) for user.
  let url = twitchApiUrl & "users/extensions/list"
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc getUserActiveExtensions(user_id: string): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-user-active-extensions
  ## Get info of active extensions installed by a specified user.
  assert user_id.len > 0, "user_id must not be empty string"
  let url = twitchApiUrl & "users/extensions?user_id=" & user_id
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))

proc updateUserExtensions(extensionsData: JsonNode): auto =
  ## https://dev.twitch.tv/docs/api/reference/#update-user-extensions
  ## Updates activation state, extension ID, version of installed extensions for user.
  ## If you try to activate a given extension under multiple extension types,
  ## the last write wins (and there is no guarantee of write order).
  let url = twitchApiUrl & "users/extensions" & user_id  # PUT  $extensionsData
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Videos ######################################################################


proc getVideos(user_id, game_id: string, ids: seq[string], first: range[1..100] = 20,
  before="", after="", language="en", period="all", sort="time", `type`="all"): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-videos
  ## Get video info by video ID (1 or more), user ID (1), or game ID (1).
  assert user_id.len > 0, "user_id must not be empty string"
  assert game_id.len > 0, "game_id must not be empty string"
  assert language.len == 2, "language must be 2-char Language ISO code"
  assert ids.len < 100, "ids must be seq[string] of 100 strings max"
  assert period in validPeriods, "Period must be one of " & $validPeriods
  assert sort in validSorts, "sort must be one of " & $validSorts
  assert `type` in validTypes, "type must be one of " & $validTypes
  let a = "?user_id=" & user_id & "&game_id=" & game_id & "&first=" & $first & "&type=" & `type`
  argify("b", before)
  argify("c", after)
  argify("d", language)
  argify("e", period)
  let url = twitchApiUrl & "videos" & a & b & c & d & e
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


# Webhooks ####################################################################


proc getWebhookSubscriptions(first: range[1..100] = 20, after=""): auto =
  ## https://dev.twitch.tv/docs/api/reference/#get-webhook-subscriptions
  ## Get Webhook subscriptions of user, in order of expiration.
  let a = "?first=" & $first
  argify("b", after)
  let url = twitchApiUrl & "webhooks/subscriptions" & a & b
  when not defined(release): echo url
  # clientify(this)
  # result =
  #   when this is AsyncTwitch: parseJson(await client.getContent(url))
  #   else: parseJson(client.getContent(url))


when isMainModule: updateUser("user descriptin")
