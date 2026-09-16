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

// Different thresholds must produce independent results, including negative angles.
var head = HeadTurnTrigger(yawThreshold: 15, pitchThreshold: 35)
assert(!head.update(yaw: 0, pitch: 25, at: 0))
assert(!head.update(yaw: 0, pitch: 25, at: 1))
assert(!head.isActive)
assert(!head.update(yaw: -20, pitch: 0, at: 2))
assert(head.update(yaw: -20, pitch: 0, at: 2.7) && head.isActive)
// Looking forward horizontally cannot clear while vertical remains outside its release margin.
assert(!head.update(yaw: 0, pitch: 30, at: 3))
assert(!head.update(yaw: 0, pitch: 30, at: 4) && head.isActive)
assert(!head.update(yaw: 0, pitch: 20, at: 5))
assert(head.update(yaw: 0, pitch: 20, at: 5.3) && !head.isActive)
assert(!head.update(yaw: 0, pitch: -40, at: 6))
assert(head.update(yaw: 0, pitch: -40, at: 6.7) && head.isActive)
head.reset()
assert(!head.isActive)
print("PASS: independent yaw/pitch thresholds, both-axis recovery, negative angles")
