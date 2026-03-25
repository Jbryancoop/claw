import SwiftUI
import CoreLocation

struct StatusView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var serverStatus: ServerStatusState = .unknown
    @State private var isTestingConnection = false

    var body: some View {
        NavigationStack {
            List {
                // Server
                Section {
                    LabeledContent {
                        Text(ServerConfig.baseURL.absoluteString)
                            .foregroundStyle(ClawTheme.textSecondary)
                    } label: {
                        Text("URL")
                            .foregroundStyle(ClawTheme.textPrimary)
                    }

                    HStack {
                        Text("Connection")
                            .foregroundStyle(ClawTheme.textPrimary)
                        Spacer()
                        statusDot(for: serverStatus)
                        Text(serverStatus.label)
                            .foregroundStyle(ClawTheme.textSecondary)
                    }

                    Button("Test Connection") {
                        Task { await testConnection() }
                    }
                    .foregroundStyle(ClawTheme.accent)
                    .disabled(isTestingConnection)
                } header: {
                    Text("Server")
                        .foregroundStyle(ClawTheme.accent)
                }

                // Location
                Section {
                    HStack {
                        Text("Permission")
                            .foregroundStyle(ClawTheme.textPrimary)
                        Spacer()
                        statusDot(for: locationManager.authorizationStatus.isAuthorized)
                        Text(locationManager.authorizationStatus.displayName)
                            .foregroundStyle(ClawTheme.textSecondary)
                    }

                    if let loc = locationManager.lastLocation {
                        LabeledContent {
                            Text(String(format: "%.5f", loc.coordinate.latitude))
                                .foregroundStyle(ClawTheme.textSecondary)
                        } label: {
                            Text("Latitude")
                                .foregroundStyle(ClawTheme.textPrimary)
                        }
                        LabeledContent {
                            Text(String(format: "%.5f", loc.coordinate.longitude))
                                .foregroundStyle(ClawTheme.textSecondary)
                        } label: {
                            Text("Longitude")
                                .foregroundStyle(ClawTheme.textPrimary)
                        }
                    } else {
                        LabeledContent {
                            Text("Unknown")
                                .foregroundStyle(ClawTheme.textSecondary)
                        } label: {
                            Text("Position")
                                .foregroundStyle(ClawTheme.textPrimary)
                        }
                    }

                    if let time = locationManager.lastUploadTime {
                        LabeledContent {
                            Text(time, format: .dateTime.hour().minute().second())
                                .foregroundStyle(ClawTheme.textSecondary)
                        } label: {
                            Text("Last sent")
                                .foregroundStyle(ClawTheme.textPrimary)
                        }
                    }

                    if let error = locationManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(ClawTheme.destructive)
                    }

                    HStack {
                        Button(locationManager.isUpdating ? "Stop Tracking" : "Start Tracking") {
                            if locationManager.isUpdating {
                                locationManager.stopUpdating()
                            } else {
                                locationManager.startUpdating()
                            }
                        }
                        .foregroundStyle(ClawTheme.accent)

                        Spacer()

                        Button("Send Now") {
                            locationManager.sendLocationNow()
                        }
                        .foregroundStyle(ClawTheme.accent)
                        .disabled(locationManager.lastLocation == nil)
                    }
                } header: {
                    Text("Location")
                        .foregroundStyle(ClawTheme.accent)
                }

                // Notifications
                Section {
                    HStack {
                        Text("Permission")
                            .foregroundStyle(ClawTheme.textPrimary)
                        Spacer()
                        statusDot(for: notificationManager.isAuthorized)
                        Text(notificationManager.isAuthorized ? "Granted" : "Not Granted")
                            .foregroundStyle(ClawTheme.textSecondary)
                    }

                    HStack {
                        Text("Token Registered")
                            .foregroundStyle(ClawTheme.textPrimary)
                        Spacer()
                        statusDot(for: notificationManager.isTokenRegistered)
                        Text(notificationManager.isTokenRegistered ? "Yes" : "No")
                            .foregroundStyle(ClawTheme.textSecondary)
                    }

                    if let error = notificationManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(ClawTheme.destructive)
                    }
                } header: {
                    Text("Notifications")
                        .foregroundStyle(ClawTheme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ClawTheme.background)
            .navigationTitle("Status")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statusDot(for ok: Bool) -> some View {
        Circle()
            .fill(ok ? ClawTheme.accent : ClawTheme.destructive)
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
        case .unknown: return ClawTheme.textTertiary
        case .connected: return ClawTheme.accent
        case .error: return ClawTheme.destructive
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
