class_name DeviceRepository
extends RefCounted
## What the device tells the server about itself: its time zone and push
## token for §20.2's night and §14.6's pushes (server/src/notifications.mjs),
## and its sessions for §24's telemetry (server/src/telemetry.mjs).

var api: Api


func _init(a: Api) -> void:
	api = a


## The phone's IANA time zone, on every launch, and its push token once it has
## one (G34).
func report(time_zone: String, push_token: String) -> Result:
	var body := {"timeZone": time_zone}
	if push_token != "":
		body["pushToken"] = push_token
	return await api.json(HTTPClient.METHOD_PUT, "/v1/notifications", body)


## A batch of device events, `[{kind, data, at}]`.
func events(batch: Array) -> Result:
	return await api.post_json("/v1/events", batch)
