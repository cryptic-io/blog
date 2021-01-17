+++
title = "Test Post"
date = 2020-10-10
[taxonomies]
tags = ["Nix"]
+++

# First post

Multi Stage builds are great for minimizing the size of your container. The
general idea is you have a stage as your builder and another stage as your
product. This allows you to have a full development and build container while
still having a lean production container. The production container only
carries its runtime dependencies.

```dockerfile
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]
```

(from Docker's docs on multi-stage)

Sounds great, right? What's the catch? Well, it's not always easy to know
what the runtime dependencies are. For example you may have installed
something in /lib that was needed in the build process. But it turned out to
be a shared library and now it needs to be included in the production
container. Tricky! Is there some automated way