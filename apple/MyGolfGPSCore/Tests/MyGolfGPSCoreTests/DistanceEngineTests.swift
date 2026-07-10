import Testing
@testable import MyGolfGPSCore

@Test func distanceYardsSanFranciscoToOakland() {
    let engine = DistanceEngine()
    let sf = GpsPoint(lat: 37.7749, lon: -122.4194)
    let oakland = GpsPoint(lat: 37.8044, lon: -122.2712)
    let yards = engine.distanceYards(from: sf, to: oakland)
    #expect(yards > 10_000)
    #expect(yards < 15_000)
}

@Test func holeWithoutGreenReturnsNil() {
    let engine = DistanceEngine()
    let hole = HoleData(number: 1, greenCenter: nil, hasGreen: false)
    let player = GpsPoint(lat: 37.0, lon: -122.0)
    #expect(engine.distanceYards(from: player, to: hole) == nil)
}
