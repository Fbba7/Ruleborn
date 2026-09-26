class_name FakeStorePurchases
extends StorePurchases
## A store for tests: each purchase answers what the test set — a receipt the
## server's test verifier reads, or a failure — and every purchase is kept.

var answer := {"store": "app-store"}
var failure := ""
var bought: Array[Dictionary] = []


func buy(product: String, intent: String) -> Result:
	bought.append({"product": product, "intent": intent})
	if failure != "":
		return Result.failure(failure)
	var txn := "txn-%d" % bought.size()
	return Result.success({"store": answer["store"], "transaction": txn,
		"receipt": "%s:%s:%s" % [txn, product, intent]})
