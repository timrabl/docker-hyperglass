# docker-hyperglass

![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/timrabl/hyperglass)
![Docker Image Version (latest by date)](https://img.shields.io/docker/v/timrabl/hyperglass?sort=date)

A fork of [Hyperglass](https://github.com/thatmattlove/hyperglass), a network looking glass that tries to make the internet better, but in a docker container.

You can find the official documentation [here](https://hyperglass.dev).

## Repositories

The latest docker image (based on the default branch: _main_) is build daily at **02:00 AM** for the following platforms:

- linux/amd64
- linux/arm64

Afterwards these images are pushed automatically to DockerHub (docker.io), GitHub (ghcr.io) and RedHats registry (quay.io).
You can download these images with one of the following commands:

```sh
- docker pull docker.io/timrabl/hyperglass
- docker pull ghcr.io/timrabl/hyperglass
- docker pull quay.io/timrabl/hyperglass
```

## Prerequisites

Hyperglass relies on a redis as a caching host. Thank god we have docker, so for the sake of simplicity we just start a redis container next to the one that contains hyperglass.
If you don't want to use redis container just overwrite the redis host parameter in the configuration to your preferred redis instance.

## Before you start

In addition to redis i highly recommend to not expose the default image port (HTTP/8001), even if this image exposes this port.
This image is intended to just encapsulate the hyperglass application in a container and does not extend any functionality of the main application.
If there is a missing application feature, open a issue at the official [hyperglass repository](https://github.com/thatmattlove/hyperglass/issues).

Use a proxy container like Nginx,Caddy,Traefik,... for HTTPS instead of the HTTP port.
You can find a example docker-compose.yml using Nginx for HTTPS and Redis for caching down below.

## Getting started

As mentioned in the variables section, this image does not require any variables at startup time, just a redis instance.
So lets assume, your redis instance is running at: `redis:6379`.
To start hyperglass just type one of the following commands in your cli.

```bash
docker run -it docker.io/timrabl/hyperglass:latest
docker run -it ghcr.io/timrabl/hyperglass:latest
docker run -it quay.io/timrabl/hyperglass:latest
```

Please keep in mind, that the initial image startup takes about **3-4 minutes** for the UI build.
All of the commands above are exposing the hyperglass web UI at the HTTP port **8001**.
To access your hyperglass access `http://<YOUR DOCKER HOST>:8001` in the browser.

## Variables

**None**
Yep your heard right, no environment variables are required to start this container, just the redis instance. However, I would recommend you to replace the default configurations with your own configurations. This works great with a bind mount. But a custom image would be even better. A security question generally arises here in the structure of configuring the application, but let's leave that...

## Configuration

The hyperglass application is installed at: `/opt/hyperglass`.
The current config path is: `/opt/hyperglass/hyperglass`, as hyperglass expects a path called `hyperglass` at the root app path.

To adopt the default docker configuration with your own, just replace any of the container configuration files with your own.
Either via a bind mount or a custom image.

See:

### Bind-Mount

```sh
# /bin/sh
docker run --rm -it docker.io/timrabl/hyperglass:latest -v ./overwrite-devices.yml:/opt/hyperglass/hyperglass/devices.yml
```

or

```yaml
  # docker-compose
  ...

  app:
    image: docker.io/timrabl/hyperglass:latest
    restart: unless-stopped
    depends_on:
      - redis
    volumes:
      - type: volume
        source: hyper_static
        target: /opt/hyperglass/hyperglass/static
      - type: bind
        source: ./overwrite-devices.yml
        target: /opt/hyperglass/hyperglass/devices.yml
```

### Custom image

```Dockerfile
FROM docker.io/timrabl/hyperglass:latest
COPY --chown=hyperglass:hyperglass overwrite-devices.yml /opt/hyperglass/hyperglass/devices.yml
```


## Docker Compose

### Redis & Hyperglass & NGINX (HTTPS)

Example with redis and Nginx:

```yaml
---
version: "3.4"

x-restart-policy: &x-restart-policy
  restart: unless-stopped

services:
  redis:
    image: redis:7-alpine
    <<: *x-restart-policy

  app:
    image: docker.io/timrabl/hyperglass:latest
    <<: *x-restart-policy
    depends_on:
      - redis
    volumes:
      - type: volume
        source: hyper_static
        target: /opt/hyperglass/hyperglass/static

  proxy:
    image: nginx:1.23.1-alpine
    <<: *x-restart-policy
    depends_on:
      - app
    volumes:
      - type: volume
        source: nginx/default.conf
        target: /etc/nginx/conf.d/default.conf
        # Generate selfsigned keypair with:
        # openssl req -newkey rsa:4096 -new -nodes -x509 -days 3650 -keyout hyperglass_selfsigned_key.pem -out hyperglass_selfsigned_crt.pem -subj "/C=DE/ST=Bavaria/L=Rosenheim/CN=localhost"
      - type: volume
        source: nginx/hyperglass_selfsigned_crt.pem
        target: /etc/nginx/conf.d/hyperglass_selfsigned_crt.pem
      - type: volume
        source: nginx/hyperglass_selfsigned_key.pem
        target: /etc/nginx/conf.d/hyperglass_selfsigned_key.pem
    ports:
      - 1443:443

volumes:
  hyper_static:
```
