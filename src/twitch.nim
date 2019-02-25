## **Docs, Info, etc:** https://dev.twitch.tv/docs/api
# Follow & Subscribe my Nim coding live stream: https://www.twitch.tv/juancarlospaco
import asyncdispatch, httpclient, strutils, json

const
  twitchApiUrl* = "https://api.twitch.tv/helix/" ## Twitch API URL (SSL).

type
  TwitchBase*[HttpType] = object ## Base object.
    timeout*: byte  ## Timeout Seconds for API Calls, byte type, 1~255.
    proxy*: Proxy  ## Network IPv4 / IPv6 Proxy support, Proxy type.
    api_key*: string ## Required valid Twitch API Key, Twitch OAuth access token.
  Twitch* = TwitchBase[HttpClient]           ##  Sync Twitch API Client.
  AsyncTwitch* = TwitchBase[AsyncHttpClient] ## Async Twitch API Client.

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
