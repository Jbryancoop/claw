# Claw iOS App - API Contract

The Claw iOS app expects the following REST endpoints on the openclaw server.
All requests include `Authorization: Bearer <token>` header when a token is configured.
All request/response bodies are JSON with `Content-Type: application/json`.

---

## GET /api/status

Health check / connectivity test.

**Response:**
```json
{
  "ok": true,
  "data": {
    "message": "Server is running",
    "status": "ok"
  }
}
```

---

## POST /api/location

Receives the device's GPS coordinates.

**Request body:**
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "altitude": 10.0,
  "horizontalAccuracy": 5.0,
  "verticalAccuracy": 3.0,
  "timestamp": "2026-03-25T12:00:00Z"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "message": "Location received"
  }
}
```

---

## POST /api/device-token

Registers the APNs device token for push notifications.

**Request body:**
```json
{
  "device_token": "a1b2c3d4e5f6...hex string...",
  "platform": "ios"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "message": "Token registered"
  }
}
```

---

## POST /api/command

Sends a chat command from the user and receives a text response.

**Request body:**
```json
{
  "command": "turn on the lights"
}
```

**Response:**
```json
{
  "ok": true,
  "response": "Lights turned on."
}
```

**Error response:**
```json
{
  "ok": false,
  "error": "Unknown command"
}
```

---

## Push Notification Payload

The server should send APNs notifications in this format:

```json
{
  "aps": {
    "alert": {
      "title": "Claw",
      "body": "Notification message here"
    },
    "sound": "default",
    "badge": 1
  }
}
```

---

## Authentication

All endpoints accept an optional `Authorization: Bearer <token>` header.
The token is configured by the user in iOS Settings > Claw > API Token.
If no token is set, the header is omitted.

## Battery Optimization Notes

- Location updates use **significant change monitoring** when the app is backgrounded
  (~500m cell/Wi-Fi transitions, near-zero additional battery cost)
- Foreground location updates are throttled to every 30 seconds minimum
- Network calls use `waitsForConnectivity` to avoid repeated retry loops on poor connections
- The distance filter is set to 100m to avoid sending redundant nearby positions
