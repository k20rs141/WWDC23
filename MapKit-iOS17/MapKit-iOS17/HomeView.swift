import MapKit
import SwiftUI

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .region(.region)
    @State private var viewingRegion: MKCoordinateRegion?
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var mapSelection: MKMapItem?
    @State private var searchResults = [MKMapItem]()
    @State private var showDetails = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDistination: MKMapItem?
    @Namespace private var locationSpace
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
                Marker("九州産業大学", coordinate: .location)
                    .annotationTitles(.visible)

                ForEach(searchResults, id: \.self) { mapItem in
                    let placemark = mapItem.placemark
                    Marker(placemark.name ?? "No Name", coordinate: placemark.coordinate)
                        .tint(Color(red: 0.545, green: 0.133, blue: 0.176))
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.red, lineWidth: 7)
                }
            }
            .onMapCameraChange { context in
                viewingRegion = context.region
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapPitchButton()
            }
            .mapScope(locationSpace)
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: $showSearch)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showDetails, onDismiss: {
                withAnimation(.snappy) {
                    if let boundingRect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(boundingRect)
                    }
                }
            }) {
                MapDetails()
                    .presentationDetents([.height(100)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(100)))
                    .presentationCornerRadius(25)
                    .interactiveDismissDisabled(true)
            }
            .safeAreaInset(edge: .bottom) {
                if routeDisplaying {
                    Button("ルート終了") {
                        withAnimation(.snappy) {
                            routeDisplaying = false
                            showDetails = false
                            mapSelection = routeDistination
                            routeDistination = nil
                            route = nil
                            cameraPosition = .region(.region)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.545, green: 0.133, blue: 0.176).gradient, in: .rect(cornerRadius: 15))
                }
            }
        }
        .onSubmit(of: .search) {
            Task {
                guard !searchText.isEmpty else { return }
                await searchPlaces()
            }
        }
        .onChange(of: showSearch, initial: false) {
            if !showSearch {
                searchResults.removeAll(keepingCapacity: false)
                withAnimation(.snappy) {
                    cameraPosition = .region(.region)
                }
            }
        }
        .onChange(of: mapSelection) {
            showDetails = true
        }
    }

    @ViewBuilder
    func MapDetails() -> some View {
        VStack(spacing: 15) {
            Button("ルート案内", action: fetchRoute)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(Color(red: 0.545, green: 0.133, blue: 0.176).gradient, in: .rect(cornerRadius: 15))
        }
        .padding(15)
    }

    // マップ検索
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = viewingRegion ?? .region

        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
    }

    // ルート検索
    func fetchRoute() {
        if let mapSelection {
            let request = MKDirections.Request()
            request.source = .init(placemark: .init(coordinate: .location))
            request.destination = mapSelection

            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                routeDistination = mapSelection
                
                withAnimation(.snappy) {
                    routeDisplaying = true
                    showDetails = false
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

extension CLLocationCoordinate2D {
    static var location: CLLocationCoordinate2D {
        return .init(latitude: 33.65943127, longitude: 130.444117)
    }
}

extension MKCoordinateRegion {
    static var region: MKCoordinateRegion {
        return .init(center: .location, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}
