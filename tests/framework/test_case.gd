class_name TestCase
extends RefCounted
## Base class for unit tests. Subclass it and add methods named `test_*`; the
## runner discovers and calls each one. Assertions record failures into
## `failures` rather than aborting, so one bad assert doesn't hide the rest.
##
## The runner clears `failures` before each test method and reports any it finds.

var failures: Array[String] = []


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_record("assert_true failed", message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_record("assert_false failed", message)


func assert_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		_record("expected %s but got %s" % [_s(expected), _s(actual)], message)


func assert_ne(actual, other, message: String = "") -> void:
	if actual == other:
		_record("expected value to differ from %s" % _s(other), message)


func assert_gt(a, b, message: String = "") -> void:
	if not (a > b):
		_record("expected %s > %s" % [_s(a), _s(b)], message)


func assert_has(dict: Dictionary, key, message: String = "") -> void:
	if not dict.has(key):
		_record("expected dictionary to contain key %s" % _s(key), message)


func fail(message: String) -> void:
	_record("explicit fail", message)


func _record(what: String, message: String) -> void:
	if message.is_empty():
		failures.append(what)
	else:
		failures.append("%s (%s)" % [what, message])


func _s(v) -> String:
	return str(v)
