import SwiftUI
import MapKit
import CoreLocation

// MARK: - Modelos de Datos
struct BusRoute: Identifiable {
    let id = UUID()
    let name: String
    let routeNumber: String
    let color: Color
    let coordinates: [CLLocationCoordinate2D]
    let price: Double
}

struct Bus: Identifiable {
    let id = UUID()
    let routeNumber: String
    let coordinate: CLLocationCoordinate2D
    let direction: String
    let nextStop: String
    let estimatedTime: Int // minutos
}

struct BusStop: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let routes: [String]
}

// MARK: - Vista Principal
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6176, longitude: 0.6200), // Lleida
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var showingRoutes = false
    @State private var showingTicketPurchase = false
    @State private var selectedBus: Bus?
    @State private var searchText = ""
    
    // Datos simulados
    @State private var buses: [Bus] = [
        Bus(routeNumber: "L1", coordinate: CLLocationCoordinate2D(latitude: 41.6180, longitude: 0.6195), direction: "Centro", nextStop: "Pl. Ricard Viñes", estimatedTime: 3),
        Bus(routeNumber: "L2", coordinate: CLLocationCoordinate2D(latitude: 41.6165, longitude: 0.6210), direction: "Universitat", nextStop: "Hospital Arnau", estimatedTime: 5),
        Bus(routeNumber: "L3", coordinate: CLLocationCoordinate2D(latitude: 41.6190, longitude: 0.6180), direction: "Estació", nextStop: "Av. Catalunya", estimatedTime: 2),
        Bus(routeNumber: "L4", coordinate: CLLocationCoordinate2D(latitude: 41.6155, longitude: 0.6225), direction: "Zona Alta", nextStop: "Pl. Sant Joan", estimatedTime: 7)
    ]
    
    @State private var busRoutes: [BusRoute] = [
        BusRoute(name: "Línea 1 - Centro", routeNumber: "L1", color: .blue, coordinates: [], price: 1.35),
        BusRoute(name: "Línea 2 - Universitat", routeNumber: "L2", color: .green, coordinates: [], price: 1.35),
        BusRoute(name: "Línea 3 - Estació", routeNumber: "L3", color: .red, coordinates: [], price: 1.35),
        BusRoute(name: "Línea 4 - Zona Alta", routeNumber: "L4", color: .orange, coordinates: [], price: 1.35)
    ]
    
    var body: some View {
        ZStack {
            // Mapa principal
            Map(coordinateRegion: $region, annotationItems: buses) { bus in
                MapAnnotation(coordinate: bus.coordinate) {
                    BusAnnotationView(bus: bus) {
                        selectedBus = bus
                        showingTicketPurchase = true
                    }
                }
            }
            .ignoresSafeArea()
            
            // Barra de búsqueda
            VStack {
                HStack {
                    SearchBar(text: $searchText, placeholder: "Buses en Lleida")
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    Button(action: {
                        showingRoutes.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Panel de rutas (similar a la imagen)
                if showingRoutes {
                    RoutesPanel(routes: busRoutes, onRouteSelected: { route in
                        // Aquí se podría centrar el mapa en la ruta seleccionada
                        showingRoutes = false
                    })
                    .transition(.move(edge: .bottom))
                }
            }
            
            // Botón de ubicación actual
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingTicketPurchase) {
            if let bus = selectedBus {
                TicketPurchaseView(bus: bus, onPurchase: { ticketType in
                    // Lógica de compra del billete
                    print("Billete comprado: \(ticketType) para bus \(bus.routeNumber)")
                    showingTicketPurchase = false
                })
            }
        }
        .onAppear {
            locationManager.requestPermission()
            startBusSimulation()
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            region.center = location.coordinate
        }
    }
    
    private func startBusSimulation() {
        // Simular movimiento de buses cada 5 segundos
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            for i in buses.indices {
                let randomLat = Double.random(in: -0.001...0.001)
                let randomLon = Double.random(in: -0.001...0.001)
                buses[i] = Bus(
                    routeNumber: buses[i].routeNumber,
                    coordinate: CLLocationCoordinate2D(
                        latitude: buses[i].coordinate.latitude + randomLat,
                        longitude: buses[i].coordinate.longitude + randomLon
                    ),
                    direction: buses[i].direction,
                    nextStop: buses[i].nextStop,
                    estimatedTime: max(1, buses[i].estimatedTime - 1)
                )
            }
        }
    }
}

// MARK: - Vista de Anotación del Bus
struct BusAnnotationView: View {
    let bus: Bus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                ZStack {
                    Circle()
                        .fill(colorForRoute(bus.routeNumber))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "bus.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                
                Text(bus.routeNumber)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.white)
                    .cornerRadius(4)
            }
        }
    }
    
    private func colorForRoute(_ route: String) -> Color {
        switch route {
        case "L1": return .blue
        case "L2": return .green
        case "L3": return .red
        case "L4": return .orange
        default: return .gray
        }
    }
}

// MARK: - Barra de Búsqueda
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Panel de Rutas
struct RoutesPanel: View {
    let routes: [BusRoute]
    let onRouteSelected: (BusRoute) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Indicador de arrastre
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(routes) { route in
                        RouteCardView(route: route) {
                            onRouteSelected(route)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .frame(maxHeight: 300)
    }
}

// MARK: - Tarjeta de Ruta
struct RouteCardView: View {
    let route: BusRoute
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icono de la ruta con color
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(route.color)
                        .frame(width: 60, height: 40)
                    
                    Text(route.routeNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("€\(route.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vista de Compra de Billete
struct TicketPurchaseView: View {
    let bus: Bus
    let onPurchase: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTicketType = "Billete Simple"
    let ticketTypes = ["Billete Simple", "Billete Día", "Billete Semanal"]
    let prices = ["1.35€", "4.20€", "12.00€"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Información del bus
                VStack(spacing: 12) {
                    Text("Bus \(bus.routeNumber)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Dirección: \(bus.direction)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Próxima parada: \(bus.nextStop)")
                        Spacer()
                        Text("\(bus.estimatedTime) min")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                
                // Selección de tipo de billete
                VStack(alignment: .leading, spacing: 16) {
                    Text("Selecciona tu billete")
                        .font(.headline)
                    
                    ForEach(Array(ticketTypes.enumerated()), id: \.offset) { index, ticketType in
                        TicketOptionView(
                            title: ticketType,
                            price: prices[index],
                            isSelected: selectedTicketType == ticketType
                        ) {
                            selectedTicketType = ticketType
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Botón de compra
                Button(action: {
                    onPurchase(selectedTicketType)
                }) {
                    Text("Comprar Billete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Comprar Billete")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Opción de Billete
struct TicketOptionView: View {
    let title: String
    let price: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - Extensiones
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
