import SwiftUI

struct StatusView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var serverStatus: ServerStatusState = .unknown
    @State private var isTestingConnection = false

    var body: some View {
        NavigationStack {
            List {
                // Server
                Section("Server") {
                    LabeledContent("URL", value: ServerConfig.baseURL.absoluteString)

                    HStack {
                        Text("Connection")
                        Spacer()
                        statusDot(for: serverStatus)
                        Text(serverStatus.label)
                            .foregroundStyle(.secondary)
                    }

                    Button("Test Connection") {
                        Task { await testConnection() }
                    }
                    .disabled(isTestingConnection)
                }

                // Location
                Section("Location") {
                    HStack {
                        Text("Permission")
                        Spacer()
                        statusDot(for: locationManager.authorizationStatus.isAuthorized)
                        Text(locationManager.authorizationStatus.displayName)
                            .foregroundStyle(.secondary)
                    }

                    if let loc = locationManager.lastLocation {
                        LabeledContent("Latitude", value: String(format: "%.5f", loc.coordinate.latitude))
                        LabeledContent("Longitude", value: String(format: "%.5f", loc.coordinate.longitude))
                    } else {
                        LabeledContent("Position", value: "Unknown")
                    }

                    if let time = locationManager.lastUploadTime {
                        LabeledContent("Last sent", value: time, format: .dateTime.hour().minute().second())
                    }

                    if let error = locationManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Button(locationManager.isUpdating ? "Stop Tracking" : "Start Tracking") {
                            if locationManager.isUpdating {
                                locationManager.stopUpdating()
                            } else {
                                locationManager.startUpdating()
                            }
                        }

                        Spacer()

                        Button("Send Now") {
                            locationManager.sendLocationNow()
                        }
                        .disabled(locationManager.lastLocation == nil)
                    }
                }

                // Notifications
                Section("Notifications") {
                    HStack {
                        Text("Permission")
                        Spacer()
                        statusDot(for: notificationManager.isAuthorized)
                        Text(notificationManager.isAuthorized ? "Granted" : "Not Granted")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Token Registered")
                        Spacer()
                        statusDot(for: notificationManager.isTokenRegistered)
                        Text(notificationManager.isTokenRegistered ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }

                    if let error = notificationManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Status")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statusDot(for ok: Bool) -> some View {
        Circle()
            .fill(ok ? .green : .red)
            .frame(width: 8, height: 8)
    }

    @ViewBuilder
    private func statusDot(for state: ServerStatusState) -> some View {
        Circle()
            .fill(state.color)
            .frame(width: 8, height: 8)
    }

    private func testConnection() async {
        isTestingConnection = true
        defer { isTestingConnection = false }
        do {
            let _: ServerResponse = try await APIClient.shared.checkStatus()
            serverStatus = .connected
        } catch {
            serverStatus = .error(error.localizedDescription)
        }
    }
}

// MARK: - Server Status

private enum ServerStatusState {
    case unknown, connected, error(String)

    var label: String {
        switch self {
        case .unknown: return "Not tested"
        case .connected: return "Connected"
        case .error(let msg): return msg
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .connected: return .green
        case .error: return .red
        }
    }
}

// MARK: - CLAuthorizationStatus helpers

private extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorizedAlways || self == .authorizedWhenInUse
    }

    var displayName: String {
        switch self {
        case .notDetermined: return "Not Asked"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    StatusView()
        .environmentObject(LocationManager())
}
