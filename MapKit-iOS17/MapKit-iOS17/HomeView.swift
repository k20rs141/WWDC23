import MapKit
import SwiftUI

struct HomeView: View {
    @State private var cameraPosition: MapCameraPosition = .region(.region)
    @State private var viewingRegion: MKCoordinateRegion?
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var mapSelection: MKMapItem?
    @State private var searchResults = [MKMapItem]()
    @Namespace private var locationSpace
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
                Marker("九州産業大学", coordinate: .location)
                    .annotationTitles(.visible)
                
                ForEach(searchResults, id: \.self) { mapItem in
                    let placemark = mapItem.placemark
                    Marker(placemark.name ?? "No Name", coordinate: placemark.coordinate)
                        .tint(.red)
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
    }

    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = viewingRegion ?? .region

        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
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
