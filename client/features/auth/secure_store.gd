class_name SecureStore
extends RefCounted
## Where the refresh token is kept (docs/security/auth.md): the platform's
## own secret storage, never a plain file. On iPhone the Keychain, as a
## generic password readable after the first unlock and never leaving this
## device (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, so it is in no
## iCloud or iTunes backup); on Android a value encrypted (AES-GCM) with an
## Android Keystore key that cannot be exported, kept in the app's private
## storage; not EncryptedSharedPreferences, which is deprecated. Both are
## reached through the platform's plugin, the engine singleton SINGLETON,
## with `read(key) -> String` ("" for none), `write(key, value) -> bool` and
## `erase(key)`.
##
## A build without the plugin — desktop, headless, the editor — keeps the
## value in memory only: the next launch signs in with the platform again,
## which is safe, rather than leaving a token on disk. A test puts a
## FakeSecureStore here.

const SINGLETON := "RulebornSecureStore"

var _memory: Dictionary = {}


## Whether a value outlives this launch: only in the platform's storage.
func persistent() -> bool:
	return Engine.has_singleton(SINGLETON)


func read(key: String) -> String:
	if persistent():
		return str(Engine.get_singleton(SINGLETON).call("read", key))
	return str(_memory.get(key, ""))


func write(key: String, value: String) -> bool:
	if persistent():
		return bool(Engine.get_singleton(SINGLETON).call("write", key, value))
	_memory[key] = value
	return true


func erase(key: String) -> void:
	if persistent():
		Engine.get_singleton(SINGLETON).call("erase", key)
	_memory.erase(key)
