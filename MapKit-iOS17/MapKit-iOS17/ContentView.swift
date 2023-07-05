import SwiftUI
import MapKit

struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .region(.region)
    @State private var viewingRegion: MKCoordinateRegion?
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var mapSelection: MKMapItem?
    @State private var searchResults = [MKMapItem]()
    @State private var showDetails = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDistination: MKMapItem?
    @Namespace private var locationSpace
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
                Marker("Apple Park", coordinate: .location)
                    .annotationTitles(.hidden)
                
                ForEach(searchResults, id: \.self) { mapItem in
//                    if routeDisplaying {
//                        if mapItem == routeDistination {
                            let placemark = mapItem.placemark
                            Marker(placemark.name ?? "No Name", coordinate: placemark.coordinate)
                                .tint(.red)
//                        }
//                    } else {
//                        let placemark = mapItem.placemark
//                        Marker(placemark.name ?? "No Name", coordinate: placemark.coordinate)
//                            .tint(.cyan)
//                    }
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.red, lineWidth: 7)
                }

//                UserAnnotation()
            }
            .onMapCameraChange { context in
                viewingRegion = context.region
            }
    //        .mapControls {
    //            MapCompass()
    //            MapUserLocationButton()
    //            MapPitchButton()
    //        }
//            .overlay(alignment: .bottomTrailing) {
//                VStack {
//                    MapUserLocationButton(scope: locationSpace)
//                }
//                .buttonBorderShape(.circle)
//                .padding()
//            }
            .mapScope(locationSpace)
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: $showSearch)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar(routeDisplaying ? .hidden : .visible, for: .navigationBar)
            .sheet(isPresented: $showDetails, onDismiss: {
                withAnimation(.snappy) {
                    if let boundingRect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(boundingRect)
                    }
                }
            }) {
                MapDetails()
                    .presentationDetents([.height(300)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
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
                    .background(.blue.gradient, in: .rect(cornerRadius: 15))
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
                showDetails = false
                withAnimation(.snappy) {
                    cameraPosition = .region(.region)
                }
            }
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            showDetails = newValue != nil
            fetchLookAroundPreview()
        }
    }

    @ViewBuilder
    func MapDetails() -> some View {
        VStack(spacing: 15) {
            ZStack {
                if lookAroundScene == nil {
                    ContentUnavailableView("No Preview", systemImage: "eye.slash")
                } else {
                    LookAroundPreview(scene: $lookAroundScene)
                }
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 15))
            Button("Get", action: fetchRoute)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(.blue.gradient, in: .rect(cornerRadius: 15))
        }
        .padding(15)
    }

    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = viewingRegion ?? .region

        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
    }

    func fetchLookAroundPreview() {
        if let mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }

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
    ContentView()
}
//
//extension CLLocationCoordinate2D {
//    static var location: CLLocationCoordinate2D {
//        return .init(latitude: 33.65943127, longitude: 130.444117)
//    }
//}
//
//extension MKCoordinateRegion {
//    static var region: MKCoordinateRegion {
//        return .init(center: .location, latitudinalMeters: 1000, longitudinalMeters: 1000)
//    }
//}
