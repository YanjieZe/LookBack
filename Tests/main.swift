import Foundation

var trigger = DwellTrigger(threshold: 30, enterDwell: 0.6)
// A brief glance must not trigger the overlay.
assert(!trigger.update(40, at: 0))
assert(!trigger.update(0, at: 0.3))
assert(!trigger.isActive)
// Sustained turns trigger it, while motion in the hysteresis band keeps it active.
assert(!trigger.update(40, at: 1))
assert(trigger.update(40, at: 1.7) && trigger.isActive)
assert(!trigger.update(25, at: 1.8) && trigger.isActive)
// Returning forward must persist for the exit dwell.
assert(!trigger.update(0, at: 2))
assert(trigger.update(0, at: 2.3) && !trigger.isActive)
// Pausing or disconnecting must clear both the active state and a pending turn.
assert(!trigger.update(40, at: 3))
trigger.reset()
assert(!trigger.update(40, at: 4))
assert(trigger.update(40, at: 4.7) && trigger.isActive)
trigger.reset()
assert(!trigger.isActive)
print("PASS: brief glance, sustained turn, hysteresis, recovery, reset")
