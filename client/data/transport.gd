class_name Transport
extends Node
## How a request reaches server/: the one seam between the client and the
## network, so tests put a `FakeTransport` here and nothing else changes.
## `send` answers {"status": int, "body": PackedByteArray}, or {"error": code}
## when no answer came.

func send(_method: HTTPClient.Method, _url: String, _headers: PackedStringArray,
		_body: PackedByteArray) -> Dictionary:
	push_error("Transport.send is abstract")
	return {"error": "no_transport"}
