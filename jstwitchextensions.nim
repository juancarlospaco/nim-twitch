## Twitch Extensions API to create https://www.twitch.tv Extensions using Nim.
## * https://dev.twitch.tv/docs/extensions/reference#javascript-helper
when not defined(js):
  {.fatal: "Module jstwitchextensions is designed to be used with the JavaScript backend.".}

import std/[jsffi, asyncjs]

type Product* = ref object of JsRoot
  amount*, displayName*, sku*: cstring
  tipe* {.importc: "type".}: cstring
  inDevelopment*: bool
  cost*: JsObject

let
  twitchVersion* {.importjs: "window.Twitch.ext.version".}: cstring
  twitchEnvironment* {.importjs: "window.Twitch.ext.environment".}: cstring
  broadcaster* {.importjs: "window.Twitch.ext.configuration.broadcaster".}: JsObject
  developer* {.importjs: "window.Twitch.ext.configuration.developer".}: JsObject
  globalConfiguration* {.importjs: "window.Twitch.ext.configuration.global".}: JsObject
  isBitsEnabled* {.importjs: "window.Twitch.ext.features.isBitsEnabled".}: bool
  isChatEnabled* {.importjs: "window.Twitch.ext.features.isChatEnabled".}: bool
  isSubscriptionStatusAvailable* {.importjs: "window.Twitch.ext.features.isSubscriptionStatusAvailable".}: bool
  isSubscriptionStatusAvailable* {.importjs: "window.Twitch.ext.features.isSubscriptionStatusAvailable".}: bool
  opaqueId* {.importjs: "window.Twitch.ext.viewer.opaqueId".}: cstring
  idTwitch* {.importjs: "window.Twitch.ext.viewer.id".}: cstring
  role* {.importjs: "window.Twitch.ext.viewer.role".}: cstring
  isLinked* {.importjs: "window.Twitch.ext.viewer.isLinked".}: bool
  sessionToken* {.importjs: "window.Twitch.ext.viewer.sessionToken".}: string
  subscriptionStatus* {.importjs: "window.Twitch.ext.viewer.subscriptionStatus".}: JsObject
  subscriptionStatus* {.importjs: "window.Twitch.ext.viewer.subscriptionStatus".}: JsObject


func getProducts*(): Future[Product] {.importjs: "window.Twitch.ext.bits.getProducts(@)".}

func onAuthorized*[T](authCallback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func onContext*[T](contextCallback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func onError*[T](errorCallback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func onHighlightChanged*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func onPositionChanged*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func onVisibilityChanged*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func send*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func listen*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func unlisten*[T](callback: T) {.importjs: "window.Twitch.ext.$1(#)".}

func followChannel*[T](callback: T) {.importjs: "window.Twitch.ext.actions.$1(#)".}

func minimize*[T](callback: T) {.importjs: "window.Twitch.ext.actions.$1(#)".}

func onFollow*[T](callback: T) {.importjs: "window.Twitch.ext.actions.$1(#)".}

func requestIdShare*[T](callback: T) {.importjs: "window.Twitch.ext.actions.$1(#)".}

func onChangedConfiguration*[T](callback: T) {.importjs: "window.Twitch.ext.configuration.$1(#)".}

func setConfiguration*[T](callback: T) {.importjs: "window.Twitch.ext.configuration.set(#)".}

func onChangedFeatures*[T](callback: T) {.importjs: "twitch.ext.features.onChanged(#)".}

func onTransactionCancelled*[T](callback: T) {.importjs: "twitch.ext.bits.$1(#)".}

func onTransactionComplete*[T](callback: T) {.importjs: "twitch.ext.bits.$1(#)".}

func setUseLoopBack*(a: bool) {.importjs: "window.Twitch.ext.bits.$1(#)".}

func showBitsBalance*() {.importjs: "window.Twitch.ext.bits.$1(@)".}

func useBits*[T](callback: T) {.importjs: "window.Twitch.ext.bits.$1(#)".}

func onChangedViewer*[T](callback: T) {.importjs: "window.Twitch.ext.viewer.$1(#)".}
