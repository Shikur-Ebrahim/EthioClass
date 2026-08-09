# Build stage — use latest Go to avoid toolchain version conflicts
FROM golang:latest AS builder

WORKDIR /app

# Allow Go to auto-select toolchain if needed
ENV GOTOOLCHAIN=auto

# Copy dependency files first (cache layer)
COPY go.mod go.sum ./
RUN go mod download
RUN go mod tidy

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -o server ./cmd/server

# ─────────────────────────────────────────────
# Production stage — minimal image
# ─────────────────────────────────────────────
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy ONLY the compiled binary — never copy .env into the image
COPY --from=builder /app/server .

EXPOSE 8080

CMD ["./server"]
