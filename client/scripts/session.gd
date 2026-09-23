class_name Session
## What one screen hands the next, for as long as the app runs: the heist just
## played, so the result screen can show it and the replay screen can play it.
## Nothing here is saved; saving is §24.4's platform save, not built yet.

static var replay := PackedByteArray()
static var verdict := {}
