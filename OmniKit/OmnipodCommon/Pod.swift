//
//  Pod.swift
//  OmniKit
//
//  Created by Pete Schwamb on 4/4/18.
//  Copyright © 2018 Pete Schwamb. All rights reserved.
//

import Foundation

public struct Pod {
    // Volume of U100 insulin in one motor pulse
    // Must agree with value returned by pod during the pairing process.
    public static let pulseSize: Double = 0.05

    // Number of pulses required to deliver one unit of U100 insulin
    public static let pulsesPerUnit: Double = 1 / Pod.pulseSize

    // Seconds per pulse for boluses
    // Checked to verify it agrees with value returned by pod during the pairing process.
    public static let secondsPerBolusPulse: Double = 2

    // Units per second for boluses
    public static let bolusDeliveryRate: Double = Pod.pulseSize / Pod.secondsPerBolusPulse

    // Seconds per pulse for priming/cannula insertion
    // Checked to verify it agrees with value returned by pod during the pairing process.
    public static let secondsPerPrimePulse: Double = 1

    // Units per second for priming/cannula insertion
    public static let primeDeliveryRate: Double = Pod.pulseSize / Pod.secondsPerPrimePulse

    // Expiration advisory window: time after expiration alert, and end of service imminent alarm
    public static let expirationAdvisoryWindow = TimeInterval(hours: 7)

    // End of service imminent window, relative to pod end of service
    public static let endOfServiceImminentWindow = TimeInterval(hours: 1)

    // Total pod service time. A fault is triggered if this time is reached before pod deactivation.
    // Checked to verify it agrees with value returned by pod during the pairing process.
    public static let serviceDuration = TimeInterval(hours: 80)

    // Nomimal pod life (72 hours)
    public static let nominalPodLife = Pod.serviceDuration - Pod.endOfServiceImminentWindow - Pod.expirationAdvisoryWindow

    // Maximum reservoir level reading
    public static let maximumReservoirReading: Double = 50

    // Reservoir level magic number indicating 50+ U remaining
    public static let reservoirLevelAboveThresholdMagicNumber: Double = 51.15

    // Reservoir Capacity
    public static let reservoirCapacity: Double = 200

    // Supported basal rates
    // Eros minimum scheduled basal rate is 0.05 U/hr while Dash supports 0 U/hr.
    public static let supportedBasalRates: [Double] = (1...600).map { Double($0) / Double(pulsesPerUnit) }

    // Supported temp basal rates
    // Both Eros and Dash support a minimum temp basal rate of 0 U/hr.
    public static let supportedTempBasalRates: [Double] = (0...600).map { Double($0) / Double(pulsesPerUnit) }

    // The internal basal rate used for zero basal rates
    // Eros uses 0.0 while Dash uses a near zero rate
    public static let zeroBasalRate: Double = 0.0

    // Maximum number of basal schedule entries supported
    public static let maximumBasalScheduleEntryCount: Int = 24

    // Minimum duration of a single basal schedule entry
    public static let minimumBasalScheduleEntryDuration = TimeInterval.minutes(30)

    // Supported temp basal durations (30m to 12h)
    public static let supportedTempBasalDurations: [TimeInterval] = (1...24).map { Double($0) * TimeInterval(minutes: 30) }

    // Default amount for priming bolus using secondsPerPrimePulse timing.
    // Checked to verify it agrees with value returned by pod during the pairing process.
    public static let primeUnits = 2.6

    // Default amount for cannula insertion bolus using secondsPerPrimePulse timing.
    // Checked to verify it agrees with value returned by pod during the pairing process.
    public static let cannulaInsertionUnits = 0.5

    public static let cannulaInsertionUnitsExtra = 0.0 // edit to add a fixed additional amount of insulin during cannula insertion

    // Default and limits for expiration reminder alerts
    public static let defaultExpirationReminderOffset = TimeInterval(hours: 2)
    public static let expirationReminderAlertMinHoursBeforeExpiration = 1
    public static let expirationReminderAlertMaxHoursBeforeExpiration = 24

    // Threshold used to display pod end of life warnings
    public static let timeRemainingWarningThreshold = TimeInterval(days: 1)

    // Default low reservoir alert limit in Units
    public static let defaultLowReservoirReminder: Double = 10

    // Allowed Low Reservoir reminder values
    public static let allowedLowReservoirReminderValues = Array(stride(from: 1, through: 50, by: 1))
}

// DeliveryStatus used in StatusResponse and DetailedStatus
// Since bits 1 & 2 are exclusive and bits 4 & 8 are exclusive,
// these are all the possible values that can be returned.
public enum DeliveryStatus: UInt8, CustomStringConvertible {
    case suspended = 0
    case scheduledBasal = 1
    case tempBasalRunning = 2
    case priming = 4 // bolusing while suspended, should only occur during priming
    case bolusInProgress = 5
    case bolusAndTempBasal = 6
    case extendedBolusWhileSuspended = 8 // should never occur
    case extendedBolusRunning = 9
    case extendedBolusAndTempBasal = 10

    public var suspended: Bool {
        // returns true if both the tempBasal and basal bits are clear
        let suspendedStates: Set<DeliveryStatus> = [
            .suspended,
            .priming,
            .extendedBolusWhileSuspended,
        ]
        return suspendedStates.contains(self)
    }

    public var bolusing: Bool {
        // returns true if either the immediateBolus or extendedBolus bits are set
        let bolusingStates: Set<DeliveryStatus> = [
            .priming,
            .bolusInProgress,
            .bolusAndTempBasal,
            .extendedBolusWhileSuspended,
            .extendedBolusRunning,
            .extendedBolusAndTempBasal,
        ]
        return bolusingStates.contains(self)
    }

    public var tempBasalRunning: Bool {
        // returns true if the tempBasal bit is set
        let tempBasalRunningStates: Set<DeliveryStatus> = [
            .tempBasalRunning,
            .bolusAndTempBasal,
            .extendedBolusAndTempBasal,
        ]
        return tempBasalRunningStates.contains(self)
    }

    public var extendedBolusRunning: Bool {
        // returns true if the extendedBolus bit is set
        let extendedBolusRunningStates: Set<DeliveryStatus> = [
            .extendedBolusWhileSuspended,
            .extendedBolusRunning,
            .extendedBolusAndTempBasal,
        ]
        return extendedBolusRunningStates.contains(self)
    }

    public var description: String {
        switch self {
        case .suspended:
            return LocalizedString("Suspended", comment: "Delivery status when insulin delivery is suspended")
        case .scheduledBasal:
            return LocalizedString("Scheduled basal", comment: "Delivery status when scheduled basal is running")
        case .tempBasalRunning:
            return LocalizedString("Temp basal running", comment: "Delivery status when temp basal is running")
        case .priming:
            return LocalizedString("Priming", comment: "Delivery status when pod is priming")
        case .bolusInProgress:
            return LocalizedString("Bolusing", comment: "Delivery status when bolusing")
        case .bolusAndTempBasal:
            return LocalizedString("Bolusing with temp basal", comment: "Delivery status when bolusing and temp basal is running")
        case .extendedBolusWhileSuspended:
            return LocalizedString("Extended bolus running while suspended", comment: "Delivery status when extended bolus is running while suspended")
        case .extendedBolusRunning:
            return LocalizedString("Extended bolus running", comment: "Delivery status when extended bolus is running")
        case .extendedBolusAndTempBasal:
            return LocalizedString("Extended bolus running with temp basal", comment: "Delivery status when extended bolus and temp basal is running")
        }
    }
}
