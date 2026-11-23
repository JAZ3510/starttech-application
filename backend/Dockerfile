FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/server .

FROM alpine:3.20
RUN adduser -D -u 10001 app
COPY --from=build /out/server /server
USER app
EXPOSE 8080
ENTRYPOINT ["/server"]
