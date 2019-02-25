## **Docs, Info, etc:** https://dev.twitch.tv/docs/api
## Twitch Legacy API v5 Kraken is NOT supported.
# Follow & Subscribe my Nim coding live stream: https://www.twitch.tv/juancarlospaco
import asyncdispatch, httpclient, strutils, json

const
  twitchApiUrl* = "https://api.twitch.tv/helix/" ## Twitch API URL (SSL).
  twitchAuth = "https://id.twitch.tv/oauth2/"    ## Twitch OAuth URL (SSL).

type
  TwitchBase*[HttpType] = object ## Base object.
    timeout*: byte  ## Timeout Seconds for API Calls, byte type, 1~255.
    proxy*: Proxy  ## Network IPv4 / IPv6 Proxy support, Proxy type.
    api_key*: string ## Required valid Twitch API Key, Twitch OAuth access token.
  Twitch* = TwitchBase[HttpClient]           ##  Sync Twitch API Client.
  AsyncTwitch* = TwitchBase[AsyncHttpClient] ## Async Twitch API Client.

  TwitchScopes = enum           ## https://dev.twitch.tv/docs/authentication/#scopes
    analytics:read:extensions   ## View analytics data for your extensions.
    analytics:read:games        ## View analytics data for your games.
    bits:read                   ## View Bits information for your channel.
    channel:read:subscriptions  ## Get a list of all subscribers to your channel and check if a user is subscribed to your channel
    clips:edit                  ## Manage a clip object.
    user:edit                   ## Manage a user object.
    user:edit:broadcast         ## Edit your channel’s broadcast configuration, including extension configuration. (This scope implies user:read:broadcast capability.)
    user:read:broadcast         ## View your broadcasting configuration, including extension configurations.
    user:read:email             ## Read authorized user’s email address.
    channel:moderate            ## Perform moderation actions in a channel. The user requesting the scope must be a moderator in the channel.
    chat:edit                   ## Send live stream chat and rooms messages.
    chat:read                   ## View live stream chat and rooms messages.
    whispers:read               ## View your whisper messages.
    whispers:edit               ## Send whisper messages.

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

proc authValidate*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ## https://dev.twitch.tv/docs/authentication/#validating-requests
  clientify(this)
  result =
    when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "validate"))
    else: parseJson(client.getContent(twitchAuth & "validate"))

proc authRevoque*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ## https://dev.twitch.tv/docs/authentication/#revoking-access-tokens
  POST https://id.twitch.tv/oauth2/revoke
  ?client_id=<your client ID>
  &token=<your OAuth token>
  clientify(this)
  result =
    when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "revoque"))
    else: parseJson(client.getContent(twitchAuth & "revoque"))

proc authRefresh*(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ## https://dev.twitch.tv/docs/authentication/#refreshing-access-tokens
  POST https://id.twitch.tv/oauth2/token
    --data-urlencode
    ?grant_type=refresh_token
    &refresh_token=<your refresh token>
    &client_id=<your client ID>
    &client_secret=<your client secret>
  clientify(this)
  result =
    when this is AsyncTwitch: parseJson(await client.getContent(twitchAuth & "revoque"))
    else: parseJson(client.getContent(twitchAuth & "revoque"))

proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ##  https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-implicit-code-flow
  GET https://id.twitch.tv/oauth2/authorize
    ?client_id=<your client ID>
    &redirect_uri=<your registered redirect URI>
    &response_type=<type>
    &scope=<space-separated list of scopes>

proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ##  https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-authorization-code-flow
  GET https://id.twitch.tv/oauth2/authorize
    ?client_id=<your client ID>
    &redirect_uri=<your registered redirect URI>
    &response_type=code
    &scope=<space-separated list of scopes>

proc foo(this: Twitch | AsyncTwitch): Future[JsonNode] {.multisync.} =
  ## https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#oauth-client-credentials-flow
  POST https://id.twitch.tv/oauth2/token
    ?client_id=<your client ID>
    &client_secret=<your client secret>
    &grant_type=client_credentials
    &scope=<space-separated list of scopes>


