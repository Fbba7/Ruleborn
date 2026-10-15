class_name Fixtures
extends RefCounted
## What the tests' services start from.


## A player past the first launch whose age check has answered — by default an
## adult's, and one the server already has, so a test's calls are only the
## ones it makes (§20.1, TD.26).
static func answered(s: Services, band := "18+", sent := true) -> Services:
	s.first.finish()
	s.age.answer(band)
	if sent:
		s.age.mark_sent()
	return s
