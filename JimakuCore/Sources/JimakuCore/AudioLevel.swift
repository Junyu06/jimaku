import Foundation

/// Turns audio samples into a level for a meter.
public enum AudioLevel {
    /// Signals at or below this level read as zero on the meter.
    public static let floorDecibels = -50.0

    /// The loudness of `samples` on a scale from 0 (silent) to 1 (full scale).
    ///
    /// The scale follows decibels, because that is how loudness is heard: each step
    /// up the meter is the same perceived increase.
    public static func meter(for samples: [Int16]) -> Double {
        guard !samples.isEmpty else { return 0 }
        var sumOfSquares = 0.0
        for sample in samples {
            let value = Double(sample) / Double(Int16.max)
            sumOfSquares += value * value
        }
        let rootMeanSquare = (sumOfSquares / Double(samples.count)).squareRoot()
        guard rootMeanSquare > 0 else { return 0 }
        let decibels = 20 * log10(rootMeanSquare)
        return min(max((decibels - floorDecibels) / -floorDecibels, 0), 1)
    }
}
