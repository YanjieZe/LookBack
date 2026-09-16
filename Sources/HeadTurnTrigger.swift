import Foundation

/// Either axis may trigger blur; both must return inside their release margins to clear it.
struct HeadTurnTrigger {
    var yawThreshold: Double = 15
    var pitchThreshold: Double = 15
    private var dwell = DwellTrigger(threshold: 0, enterDwell: 0.6)

    init(yawThreshold: Double = 15, pitchThreshold: Double = 15) {
        self.yawThreshold = yawThreshold
        self.pitchThreshold = pitchThreshold
    }

    var enterDwell: TimeInterval {
        get { dwell.enterDwell }
        set { dwell.enterDwell = newValue }
    }
    var isActive: Bool { dwell.isActive }

    mutating func update(yaw: Double, pitch: Double, at time: TimeInterval) -> Bool {
        let excess = max(abs(yaw) - yawThreshold, abs(pitch) - pitchThreshold)
        return dwell.update(excess, at: time)
    }

    mutating func reset() { dwell.reset() }
}
