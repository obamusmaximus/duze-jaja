class_name OrderQueue
extends Node
## A unit's orders, first one active. Plain data the OrderBrain works through; the CommandIssuer fills it. Simulation.

var _orders: Array[Order] = []


func replace(order: Order) -> void:
	_orders.clear()
	_orders.append(order)


func append(order: Order) -> void:
	_orders.append(order)


func clear() -> void:
	_orders.clear()


## Drops the active order (it is done).
func finish() -> void:
	if not _orders.is_empty():
		_orders.pop_front()


func is_idle() -> bool:
	return _orders.is_empty()


## The active order, or null.
func current() -> Order:
	return null if _orders.is_empty() else _orders[0]


func size() -> int:
	return _orders.size()
