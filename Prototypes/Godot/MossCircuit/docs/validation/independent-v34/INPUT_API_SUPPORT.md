# Input fixture API support

Read-only official Godot4.6 documentation consulted2026-10-26 before running the independent fixture:
- https://docs.godotengine.org/en/4.6/classes/class_viewport.html#class-viewport-method-push-input — the second argument true specifies viewport-local coordinates; normal GUI handling precedes unhandled input. The fixture deliberately uses push_input, not push_unhandled_input, so GUI consumption is exercised.
- https://docs.godotengine.org/en/4.6/classes/class_canvasitem.html#class-canvasitem-method-make-canvas-position-local — viewport-to-local conversion and the opposite global canvas transform.

Documentation explains fixture construction, not proof of executed native mouse behavior. Actual runtime receipts remain separate.
