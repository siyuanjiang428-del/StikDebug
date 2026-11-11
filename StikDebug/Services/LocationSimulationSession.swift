import Foundation
import CoreLocation
import Combine

final class LocationSimulationSession: ObservableObject {
    static let shared = LocationSimulationSession()

    @Published private(set) var isActive = false
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D]?
    private(set) var isMapSelection = false
    private var resendTimer: Timer?
    private var routeID: UUID?

    private init() {}

    func start(at coordinate: CLLocationCoordinate2D, isMapSelection: Bool = false) {
        self.isMapSelection = isMapSelection
        self.coordinate = coordinate
        if !isActive {
            isActive = true
            BackgroundAudioManager.shared.requestStart()
            BackgroundLocationManager.shared.requestStart()
        }
    }

    func startResending(
        at coordinate: CLLocationCoordinate2D,
        isMapSelection: Bool = false,
        _ operation: @escaping () -> Void
    ) {
        start(at: coordinate, isMapSelection: isMapSelection)
        resendTimer?.invalidate()
        let timer = Timer(timeInterval: 4, repeats: true) { _ in operation() }
        RunLoop.main.add(timer, forMode: .common)
        resendTimer = timer
    }

    func startRoute(at coordinate: CLLocationCoordinate2D, coordinates: [CLLocationCoordinate2D]) -> UUID {
        let routeID = UUID()
        self.routeID = routeID
        routeCoordinates = coordinates
        start(at: coordinate)
        return routeID
    }

    func isCurrentRoute(_ routeID: UUID) -> Bool {
        self.routeID == routeID
    }

    func clearRoute() {
        routeID = nil
        routeCoordinates = nil
    }

    func pauseResending() {
        resendTimer?.invalidate()
        resendTimer = nil
    }

    func updateCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    func stop() {
        pauseResending()
        clearRoute()
        guard isActive else { return }
        isActive = false
        isMapSelection = false
        coordinate = nil
        BackgroundAudioManager.shared.requestStop()
        BackgroundLocationManager.shared.requestStop()
    }
}
