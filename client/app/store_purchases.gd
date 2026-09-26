class_name StorePurchases
extends RefCounted
## The platform's store (§22.1): StoreKit on an iPhone, Play Billing on
## Android. `buy` asks the store to sell `product`, carrying the server's
## intent (StoreKit's appAccountToken, Play's obfuscatedAccountId), and
## answers the store's name, its transaction and the receipt to send.
##
## The stores are reached through each platform's billing plugin, which a
## desktop or headless build does not have: this one refuses, and says so,
## and a test puts a FakeStorePurchases in its place.

## `{store, transaction, receipt}`, or a failure: "store_not_connected",
## "purchase_cancelled", "purchase_pending" (a family's Ask to Buy).
func buy(_product: String, _intent: String) -> Result:
	return Result.failure("store_not_connected")


## The store's own price for `product`, in the player's currency, or "" when
## the store has not said (the server's euro price is shown then).
func price(_product: String) -> String:
	return ""
