import SwiftUI
import MapKit
import CoreLocation

// MARK: - Modelos de datos
struct BusRoute: Identifiable {
    let id: UUID
    let name: String
    let routeNumber: String
    let color: Color
    let coordinates: [CLLocationCoordinate2D]
    let estimatedTime: String
    let distance: String
    let fare: Double
    
    init(name: String, routeNumber: String, color: Color, coordinates: [CLLocationCoordinate2D], estimatedTime: String, distance: String, fare: Double) {
        self.id = UUID()
        self.name = name
        self.routeNumber = routeNumber
        self.color = color
        self.coordinates = coordinates
        self.estimatedTime = estimatedTime
        self.distance = distance
        self.fare = fare
    }
}

struct BusStop: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let routes: [String]
    
    init(name: String, coordinate: CLLocationCoordinate2D, routes: [String]) {
        self.id = UUID()
        self.name = name
        self.coordinate = coordinate
        self.routes = routes
    }
}

struct Bus: Identifiable {
    let id: UUID
    let routeNumber: String
    let coordinate: CLLocationCoordinate2D
    let nextStop: String
    let estimatedArrival: String
    
    init(routeNumber: String, coordinate: CLLocationCoordinate2D, nextStop: String, estimatedArrival: String) {
        self.id = UUID()
        self.routeNumber = routeNumber
        self.coordinate = coordinate
        self.nextStop = nextStop
        self.estimatedArrival = estimatedArrival
    }
}

// MARK: - Vista Principal
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedRoute: BusRoute?
    @State private var selectedBus: Bus?
    @State private var showingRouteDetail = false
    @State private var showingTicketPurchase = false
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200), // Lleida
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudineDelta: 0.05)
    )
    
    private let busRoutes = [
        BusRoute(
            name: "Línea Centro",
            routeNumber: "L1",
            color: .blue,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200),
                CLLocationCoordinate2D(latitude: 41.6186, longitude: 0.6210),
                CLLocationCoordinate2D(latitude: 41.6196, longitude: 0.6220)
            ],
            estimatedTime: "12 min",
            distance: "3.2 km",
            fare: 1.40
        ),
        BusRoute(
            name: "Ronda Universitaria",
            routeNumber: "L2",
            color: .green,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6156, longitude: 0.6180),
                CLLocationCoordinate2D(latitude: 41.6166, longitude: 0.6190),
                CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200)
            ],
            estimatedTime: "8 min",
            distance: "2.1 km",
            fare: 1.40
        ),
        BusRoute(
            name: "Barrios Norte",
            routeNumber: "L3",
            color: .red,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6196, longitude: 0.6160),
                CLLocationCoordinate2D(latitude: 41.6206, longitude: 0.6170),
                CLLocationCoordinate2D(latitude: 41.6216, longitude: 0.6180)
            ],
            estimatedTime: "15 min",
            distance: "4.8 km",
            fare: 1.40
        )
    ]
    
    private let buses = [
        Bus(routeNumber: "L1", coordinate: CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200), nextStop: "Plaza España", estimatedArrival: "3 min"),
        Bus(routeNumber: "L2", coordinate: CLLocationCoordinate2D(latitude: 41.6166, longitude: 0.6190), nextStop: "Universidad", estimatedArrival: "5 min"),
        Bus(routeNumber: "L3", coordinate: CLLocationCoordinate2D(latitude: 41.6196, longitude: 0.6160), nextStop: "Hospital", estimatedArrival: "7 min")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mapa
                MapView(
                    region: $mapRegion,
                    routes: busRoutes,
                    buses: buses,
                    selectedRoute: $selectedRoute,
                    selectedBus: $selectedBus,
                    showingRouteDetail: $showingRouteDetail
                )
                .ignoresSafeArea()
                
                // Barra de búsqueda
                VStack {
                    HStack {
                        Button(action: {
                            showingSearch.toggle()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                Text(searchText.isEmpty ? "Buscar líneas en Lleida" : searchText)
                                    .foregroundColor(searchText.isEmpty ? .gray : .primary)
                                Spacer()
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                        .sheet(isPresented: $showingSearch) {
                            SearchView(searchText: $searchText, routes: busRoutes, selectedRoute: $selectedRoute, showingRouteDetail: $showingRouteDetail)
                        }
                        
                        Button(action: {
                            // Acción de localización
                        }) {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                
                // Lista de rutas filtradas (si hay búsqueda)
                if showingSearch {
                    VStack {
                        Spacer()
                            .frame(height: 120)
                        
                        ScrollView {
                            LazyVStack {
                                ForEach(filteredRoutes, id: \.id) { route in
                                    RouteCard(route: route) {
                                        selectedRoute = route
                                        showingRouteDetail = true
                                        showingSearch = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.white.opacity(0.95))
                    }
                }
            }
        }
        .sheet(isPresented: $showingRouteDetail) {
            if let route = selectedRoute {
                RouteDetailView(route: route, showingTicketPurchase: $showingTicketPurchase)
            }
        }
        .sheet(isPresented: $showingTicketPurchase) {
            if let route = selectedRoute {
                TicketPurchaseView(route: route)
            }
        }
    }
    
    private var filteredRoutes: [BusRoute] {
        if searchText.isEmpty {
            return busRoutes
        } else {
            return busRoutes.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.routeNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Vista del Mapa
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routes: [BusRoute]
    let buses: [Bus]
    @Binding var selectedRoute: BusRoute?
    @Binding var selectedBus: Bus?
    @Binding var showingRouteDetail: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Agregar anotaciones de buses
        for bus in buses {
            let annotation = BusAnnotation(bus: bus)
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Actualizar overlays de rutas
        mapView.removeOverlays(mapView.overlays)
        for route in routes {
            let polyline = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
            polyline.title = route.routeNumber
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Determinar color basado en el título (número de ruta)
                switch polyline.title {
                case "L1":
                    renderer.strokeColor = UIColor.blue
                case "L2":
                    renderer.strokeColor = UIColor.green
                case "L3":
                    renderer.strokeColor = UIColor.red
                default:
                    renderer.strokeColor = UIColor.blue
                }
                
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let busAnnotation = annotation as? BusAnnotation {
                let identifier = "BusAnnotation"
                var view: MKAnnotationView
                
                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                } else {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view.canShowCallout = true
                    
                    // Crear vista personalizada para el bus
                    let busView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                    busView.backgroundColor = UIColor.blue
                    busView.layer.cornerRadius = 15
                    
                    let busIcon = UIImageView(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
                    busIcon.image = UIImage(systemName: "bus")
                    busIcon.tintColor = .white
                    busView.addSubview(busIcon)
                    
                    view.addSubview(busView)
                }
                
                return view
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let busAnnotation = view.annotation as? BusAnnotation {
                parent.selectedBus = busAnnotation.bus
                
                // Encontrar la ruta correspondiente
                if let route = parent.routes.first(where: { $0.routeNumber == busAnnotation.bus.routeNumber }) {
                    parent.selectedRoute = route
                    parent.showingRouteDetail = true
                }
            }
        }
    }
}

// MARK: - Anotación personalizada para buses
class BusAnnotation: NSObject, MKAnnotation {
    let bus: Bus
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(bus: Bus) {
        self.bus = bus
        self.coordinate = bus.coordinate
        self.title = "Línea \(bus.routeNumber)"
        self.subtitle = "Próxima parada: \(bus.nextStop) - \(bus.estimatedArrival)"
    }
}

// MARK: - Vista de búsqueda
struct SearchView: View {
    @Binding var searchText: String
    let routes: [BusRoute]
    @Binding var selectedRoute: BusRoute?
    @Binding var showingRouteDetail: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Buscar líneas", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                .padding()
                
                List(filteredRoutes, id: \.id) { route in
                    RouteCard(route: route) {
                        selectedRoute = route
                        showingRouteDetail = true
                        dismiss()
                    }
                }
            }
            .navigationTitle("Buscar líneas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filteredRoutes: [BusRoute] {
        if searchText.isEmpty {
            return routes
        } else {
            return routes.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.routeNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Tarjeta de ruta
struct RouteCard: View {
    let route: BusRoute
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icono de la línea
                RoundedRectangle(cornerRadius: 8)
                    .fill(route.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(route.routeNumber)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(route.distance)
                        Text("•")
                        Text(route.estimatedTime)
                        Text("•")
                        Text("€\(String(format: "%.2f", route.fare))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vista de detalle de ruta
struct RouteDetailView: View {
    let route: BusRoute
    @Binding var showingTicketPurchase: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mapa pequeño
                MapPreview(route: route)
                    .frame(height: 200)
                
                // Información de la ruta
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(route.name)
                            .font(.title2.bold())
                        
                        Spacer()
                        
                        Button("Cancelar") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(route.distance)
                                .font(.title3.bold())
                            Text("Distancia")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text(route.estimatedTime)
                                .font(.title3.bold())
                            Text("Tiempo estimado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("€\(String(format: "%.2f", route.fare))")
                                .font(.title3.bold())
                            Text("Precio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Información adicional
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Información")
                            .font(.headline)
                        Text("Consulta la información de seguridad antes del viaje.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Botones de acción
                    HStack(spacing: 12) {
                        Button("Añadir a Favoritos") {
                            // Acción de añadir a favoritos
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Comprar Billete") {
                            showingTicketPurchase = true
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Vista previa del mapa
struct MapPreview: UIViewRepresentable {
    let route: BusRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        
        // Configurar región para mostrar la ruta
        if !route.coordinates.isEmpty {
            let region = MKCoordinateRegion(
                center: route.coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudineDelta: 0.01)
            )
            mapView.setRegion(region, animated: false)
            
            // Agregar overlay de la ruta
            let polyline = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
            mapView.addOverlay(polyline)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // No necesita actualizaciones
    }
    
    func makeCoordinator() -> MapPreviewCoordinator {
        MapPreviewCoordinator(route: route)
    }
    
    class MapPreviewCoordinator: NSObject, MKMapViewDelegate {
        let route: BusRoute
        
        init(route: BusRoute) {
            self.route = route
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(route.color)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

// MARK: - Vista de compra de billetes
struct TicketPurchaseView: View {
    let route: BusRoute
    @Environment(\.dismiss) private var dismiss
    @State private var ticketQuantity = 1
    @State private var selectedPaymentMethod = "Tarjeta"
    
    private let paymentMethods = ["Tarjeta", "Bizum", "PayPal"]
    
    var totalPrice: Double {
        return route.fare * Double(ticketQuantity)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancelar") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Comprar Billete")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Listo") {
                        // Procesar compra
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                // Información de la línea
                VStack(alignment: .leading, spacing: 12) {
                    Text(route.name)
                        .font(.title2.bold())
                    
                    Text("¿Quieres recordar algo sobre esta línea?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Selector de cantidad
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cantidad de billetes")
                        .font(.headline)
                    
                    HStack {
                        Button("-") {
                            if ticketQuantity > 1 {
                                ticketQuantity -= 1
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .disabled(ticketQuantity <= 1)
                        
                        Text("\(ticketQuantity)")
                            .font(.title2)
                            .frame(minWidth: 50)
                        
                        Button("+") {
                            if ticketQuantity < 10 {
                                ticketQuantity += 1
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .disabled(ticketQuantity >= 10)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("€\(String(format: "%.2f", totalPrice))")
                                .font(.title2.bold())
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Método de pago
                VStack(alignment: .leading, spacing: 12) {
                    Text("Método de pago")
                        .font(.headline)
                    
                    ForEach(paymentMethods, id: \.self) { method in
                        Button(action: {
                            selectedPaymentMethod = method
                        }) {
                            HStack {
                                Image(systemName: selectedPaymentMethod == method ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPaymentMethod == method ? .blue : .gray)
                                
                                Text(method)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Botón de compra
                Button("Comprar por €\(String(format: "%.2f", totalPrice))") {
                    // Procesar compra
                    dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Gestor de ubicación
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - App Principal
@main
struct LleidaBusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Vista previa para Xcode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

struct RouteCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoute = BusRoute(
            name: "Línea Centro",
            routeNumber: "L1",
            color: .blue,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200)
            ],
            estimatedTime: "12 min",
            distance: "3.2 km",
            fare: 1.40
        )
        
        RouteCard(route: sampleRoute) {
            // Acción de ejemplo
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoute = BusRoute(
            name: "Línea Centro",
            routeNumber: "L1",
            color: .blue,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200)
            ],
            estimatedTime: "12 min",
            distance: "3.2 km",
            fare: 1.40
        )
        
        RouteDetailView(route: sampleRoute, showingTicketPurchase: .constant(false))
    }
}

struct TicketPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRoute = BusRoute(
            name: "Línea Centro",
            routeNumber: "L1",
            color: .blue,
            coordinates: [
                CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200)
            ],
            estimatedTime: "12 min",
            distance: "3.2 km",
            fare: 1.40
        )
        
        TicketPurchaseView(route: sampleRoute)
    }
}
