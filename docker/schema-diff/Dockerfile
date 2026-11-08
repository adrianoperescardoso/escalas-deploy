FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git ca-certificates
RUN CGO_ENABLED=0 go install github.com/stripe/pg-schema-diff/cmd/pg-schema-diff@v1.0.9

FROM alpine:3.22
RUN apk add --no-cache ca-certificates
COPY --from=builder /go/bin/pg-schema-diff /usr/local/bin/pg-schema-diff
ENTRYPOINT ["/usr/local/bin/pg-schema-diff"]
