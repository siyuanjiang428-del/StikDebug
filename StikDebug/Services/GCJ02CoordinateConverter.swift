import CoreLocation
import Foundation

enum GCJ02CoordinateConverter {
    static func isInApproximateCoverage(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // This rectangle is a coarse check. The user selects the basemap's coordinate system.
        (0.8293...55.8271).contains(coordinate.latitude) &&
        (72.004...137.8347).contains(coordinate.longitude)
    }

    static func wgs84(from coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isInApproximateCoverage(coordinate) else { return coordinate }

        var estimate = coordinate
        // Refine the inverse using the error from the forward transform.
        for _ in 0..<6 {
            let projected = gcj02(fromWGS84: estimate)
            estimate.latitude += coordinate.latitude - projected.latitude
            estimate.longitude += coordinate.longitude - projected.longitude
        }
        return estimate
    }

    private static func gcj02(fromWGS84 coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // GCJ-02 coefficients are documented in the public coordtransform implementation.
        // https://github.com/wandergis/coordtransform/blob/master/index.js
        let radius = 6_378_245.0
        let eccentricitySquared = 0.006693421622965943
        let radiansPerDegree = Double.pi / 180
        let latitudeRadians = coordinate.latitude * radiansPerDegree
        let latitudeSine = sin(latitudeRadians)
        let magic = 1 - eccentricitySquared * latitudeSine * latitudeSine
        let root = sqrt(magic)

        let x = coordinate.longitude - 105
        let y = coordinate.latitude - 35
        let xAngle = x * Double.pi
        let yAngle = y * Double.pi
        let sharedOffset = 20 * (sin(6 * xAngle) + sin(2 * xAngle))

        var north = -100.0 + 2 * x + 3 * y
        north += 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        north += (sharedOffset + 20 * sin(yAngle) + 40 * sin(yAngle / 3)
                  + 160 * sin(yAngle / 12) + 320 * sin(yAngle / 30)) * (2.0 / 3)

        var east = 300.0 + x + 2 * y
        east += 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        east += (sharedOffset + 20 * sin(xAngle) + 40 * sin(xAngle / 3)
                 + 150 * sin(xAngle / 12) + 300 * sin(xAngle / 30)) * (2.0 / 3)

        let meridionalRadius = radius * (1 - eccentricitySquared) / (magic * root)
        let parallelRadius = radius / root * cos(latitudeRadians)
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + north / (meridionalRadius * radiansPerDegree),
            longitude: coordinate.longitude + east / (parallelRadius * radiansPerDegree)
        )
    }
}
