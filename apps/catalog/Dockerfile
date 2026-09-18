FROM docker.io/library/golang:1.22.7-bookworm AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/catalog .
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/catalog /catalog
COPY schema.sql /app/schema.sql
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/catalog"]
