extends RefCounted
## Test-only strict B -> exact A -> unchanged historical A inverse.
const B=preload("res://tests/support/v39_B_catalog_projection.gd")
const A=preload("res://tests/support/v39_catalog_projection.gd")
static func project(catalog:Dictionary,raw:String)->Dictionary:
	var intermediate:Dictionary=B.project(catalog,raw)
	if not intermediate.pass:return intermediate
	return A.project(intermediate.catalog,intermediate.bytes)
