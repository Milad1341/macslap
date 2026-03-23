import Foundation
import IOKit
import IOKit.hid

final class IOKitHIDBridge {
    typealias SampleCallback = (AccelerometerSample) -> Void

    private static let vendorUsagePage: Int64 = 0xFF00
    private static let accelUsage: Int64 = 3
    private static let reportBufferSize = 4096
    private static let accelScale: Double = 65536.0

    private var callback: SampleCallback?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private var hidDevice: IOHIDDevice?
    private var sensorThread: Thread?
    private var runLoop: CFRunLoop?
    private var isRunning = false

    deinit {
        stop()
        reportBuffer?.deallocate()
    }

    // MARK: - Public API

    static func isAvailable() -> Bool {
        guard let matching = IOServiceMatching("AppleSPUHIDDevice") as? [String: Any] else {
            return false
        }
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching as CFDictionary, &iterator)
        guard kr == KERN_SUCCESS else { return false }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            if deviceMatchesAccelerometer(service) {
                IOObjectRelease(service)
                return true
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return false
    }

    func start(callback: @escaping SampleCallback) throws {
        guard !isRunning else { return }
        self.callback = callback
        isRunning = true

        try wakeDrivers()

        sensorThread = Thread { [weak self] in
            guard let self else { return }
            do {
                try self.setupAndRun()
            } catch {
                print("[MacSlap] Sensor error: \(error)")
                self.isRunning = false
            }
        }
        sensorThread?.name = "MacSlap-Accelerometer"
        sensorThread?.qualityOfService = .userInteractive
        sensorThread?.start()
    }

    func stop() {
        isRunning = false
        if let rl = runLoop {
            CFRunLoopStop(rl)
        }
        if let device = hidDevice {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            hidDevice = nil
        }
        sensorThread = nil
        callback = nil
    }

    // MARK: - Private

    private func wakeDrivers() throws {
        guard let matching = IOServiceMatching("AppleSPUHIDDriver") else {
            throw SensorError.driverNotFound
        }
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { throw SensorError.driverNotFound }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            IORegistryEntrySetCFProperty(service, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(service, "SensorPropertyPowerState" as CFString, 1 as CFNumber)
            IORegistryEntrySetCFProperty(service, "ReportInterval" as CFString, 1000 as CFNumber)
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    private func setupAndRun() throws {
        guard let matching = IOServiceMatching("AppleSPUHIDDevice") else {
            throw SensorError.deviceNotFound
        }
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { throw SensorError.deviceNotFound }
        defer { IOObjectRelease(iterator) }

        var foundDevice: IOHIDDevice?
        var service = IOIteratorNext(iterator)
        while service != 0 {
            if Self.deviceMatchesAccelerometer(service) {
                foundDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service)
                IOObjectRelease(service)
                break
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        guard let device = foundDevice else {
            throw SensorError.deviceNotFound
        }

        let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            throw SensorError.permissionDenied
        }
        hidDevice = device

        reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Self.reportBufferSize)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer!,
            CFIndex(Self.reportBufferSize),
            hidReportCallback,
            context
        )

        self.runLoop = CFRunLoopGetCurrent()
        IOHIDDeviceScheduleWithRunLoop(device, self.runLoop!, CFRunLoopMode.defaultMode.rawValue)

        while isRunning {
            CFRunLoopRunInMode(.defaultMode, 0.25, false)
        }
    }

    private static func deviceMatchesAccelerometer(_ service: io_service_t) -> Bool {
        guard let usagePage = readIntProperty(service, key: "PrimaryUsagePage"),
              let usage = readIntProperty(service, key: "PrimaryUsage") else {
            return false
        }
        return usagePage == vendorUsagePage && usage == accelUsage
    }

    private static func readIntProperty(_ service: io_service_t, key: String) -> Int64? {
        guard let ref = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        let value = ref.takeRetainedValue()
        if let num = value as? NSNumber {
            return num.int64Value
        }
        return nil
    }

    fileprivate func handleReport(_ report: UnsafePointer<UInt8>, length: CFIndex) {
        guard length >= 18 else { return }

        let x = report.loadInt32(at: 6)
        let y = report.loadInt32(at: 10)
        let z = report.loadInt32(at: 14)

        let sample = AccelerometerSample(
            x: Double(x) / Self.accelScale,
            y: Double(y) / Self.accelScale,
            z: Double(z) / Self.accelScale,
            timestamp: ProcessInfo.processInfo.systemUptime
        )
        callback?(sample)
    }
}

// C-convention callback for IOKit HID
private func hidReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context else { return }
    let bridge = Unmanaged<IOKitHIDBridge>.fromOpaque(context).takeUnretainedValue()
    bridge.handleReport(report, length: reportLength)
}

// Helper to read little-endian Int32 from a byte pointer
private extension UnsafePointer where Pointee == UInt8 {
    func loadInt32(at offset: Int) -> Int32 {
        var value: Int32 = 0
        memcpy(&value, self + offset, MemoryLayout<Int32>.size)
        return value
    }
}

enum SensorError: LocalizedError {
    case driverNotFound
    case deviceNotFound
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .driverNotFound:
            return "Apple SPU HID driver not found. Is this an Apple Silicon Mac?"
        case .deviceNotFound:
            return "Accelerometer device not found."
        case .permissionDenied:
            return "Permission denied. Try running with sudo."
        }
    }
}
