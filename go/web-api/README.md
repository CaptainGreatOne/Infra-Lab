# web-api

A lightweight REST API written in Go as part of the [infra-lab](https://github.com/CaptainGreatOne/Infra-Lab) project. Built to demonstrate REST API design, JSON handling, URL parameter routing, external API consumption, and system introspection using Go's standard library.

---

## Running the API

```bash
cd go/web-api
go run main.go
```

The server starts on port `8080` by default.

---

## Endpoints

| Endpoint Method | Endpoint Name | 
| ---- | ---- | 
| GET | /hello | 
| GET | /hello/:name |
| GET | /system | 
| POST | /echo | 
| GET | /repo | 

### GET /hello
Returns a static greeting message.

**Request**
```
GET /hello
```

**Response**
```json
{
  "message": "Hello from infra-lab web-api!"
}
```

---

### GET /hello/:name
Returns a personalised greeting using the provided name as a URL parameter.

**Request**
```
GET /hello/Alex
```

**Response**
```json
{
  "message": "Hello, Alex!"
}
```

---

### GET /system
Returns system information about the machine the API is running on. Data is retrieved at request time using Go's standard library.

**Request**
```
GET /system
```

**Response**
```json
{
  "hostname": "infra-lab-sister",
  "os": "linux",
  "architecture": "amd64",
  "cpu_count": 6,
  "goroutines": 4,
  "memory_alloc_mb": 1.2,
  "go_version": "go1.22.4"
}
```

---

### POST /echo
Accepts a JSON body and returns it with a server timestamp appended. Useful for testing JSON parsing and POST request handling.

**Request**
```
POST /echo
Content-Type: application/json

{
  "message": "test payload",
  "value": 42
}
```

**Response**
```json
{
  "message": "test payload",
  "value": 42,
  "received_at": "2026-02-27T01:00:00Z"
}
```

---

### GET /repo
Calls the GitHub API to retrieve live information about the infra-lab repository. Demonstrates external HTTP calls and JSON response parsing.

**Request**
```
GET /repo
```

**Response**
```json
{
  "name": "Infra-Lab",
  "description": "A personal infrastructure lab built with Terraform, Ansible, and Go.",
  "stars": 0,
  "forks": 0,
  "open_issues": 0,
  "last_updated": "2026-02-27T01:00:00Z",
  "url": "https://github.com/CaptainGreatOne/Infra-Lab"
}
```

---

## Project Structure

```
web-api/
├── main.go           # Entry point, server setup, route registration
├── handlers/
│   ├── hello.go      # GET /hello and GET /hello/:name handlers
│   ├── system.go     # GET /system handler
│   ├── echo.go       # POST /echo handler
│   └── repo.go       # GET /repo handler
├── models/
│   └── models.go     # Request and response struct definitions
├── go.mod            # Go module definition
└── go.sum            # Dependency checksums
```

---

## Dependencies

This project uses the Go standard library only, with the exception of a router package for clean URL parameter handling.

| Package | Purpose |
|---|---|
| `net/http` | HTTP server and client |
| `encoding/json` | JSON marshaling and unmarshaling |
| `runtime` | Go runtime information for /system |
| `os` | Hostname and OS information for /system |

---

## Swagger / OpenAPI

Interactive API documentation is available via Swagger UI when the server is running:

```
http://localhost:8080/swagger/index.html
```

The OpenAPI spec is auto-generated from code annotations using [swaggo/swag](https://github.com/swaggo/swag). To regenerate after making changes:

```bash
swag init
```