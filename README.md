# docker-hyperglass

![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/timrabl/hyperglass)
![Docker Image Version (latest by date)](https://img.shields.io/docker/v/timrabl/hyperglass?sort=date)

A fork of [Hyperglass](https://github.com/thatmattlove/hyperglass), a network looking glass that tries to make the internet better, but in a docker container.

You can find the official documentation [here](https://hyperglass.dev).

## Repositories

The latest docker image (based on the default branch: _main_) is build daily at **02:00 AM** for the following platforms:

- linux/amd64
- linux/arm64

Afterwards these images are pushed automatically to the following registries:

- docker.io
- ghcr.io
- quay.io

## Prerequisites

Hyperglass relies on a redis as a caching host. Thank god we have docker, so for the sake of simplicity we just start a redis container next to the one that contains hyperglass. If you don't want to use redis container just overwrite the redis host parameter in the configuration to your preferred redis instance.

## Before you start

In addition to redis i highly recommend to not expose the default image port (HTTP/8001), even if this image exposes this port. This image is intended to just encapsulate the hyperglass application in a container and does not extend any functionality of the main application. If there is a missing application feature, open a issue at the official [hyperglass repository](https://github.com/thatmattlove/hyperglass/issues).

Use a proxy container like Nginx,Caddy,Traefik,... for HTTPS instead of the HTTP port.
You can find a example docker-compose.yml using Nginx for HTTPS and Redis for caching down below.

## Variables

**None**
Yep your heard right, no environment variables are required to start this container, just the redis instance. However, I would recommend you to replace the default configurations with your own configurations. This works great with a bind mount. But a custom image would be even better. A security question generally arises here in the structure of configuring the application, but let's leave that...

## Gettingg started

As mentioned in the variables section, this image does not require any variables at startup time, just a redis instance. So lets assume, your redis instance is running at: `redis:6379`.
To start hyperglass just type one of the following commands in your cli.

```bash
docker run -it docker.io/timrabl/hyperglass:latest
docker run -it ghcr.io/timrabl/hyperglass:latest
docker run -it quay.io/timrabl/hyperglass:latest
```

Please keep in mind, that the initial image startup takes about **3-4 minutes** for the UI build.
All of the commands above are exposing the hyperglass web UI at the HTTP port **8001**.
To access your hyperglass access `http://<YOUR DOCKER HOST>:8001` in the browser.

## Docker Compose

### Redis & Hyperglass & NGINX (HTTPS)

Example with redis and nginx:

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
    # image: ghcr.io/timrabl/hyperglass:latest
    # image: quay.io/timrabl/hyperglass:latest
    <<: *x-restart-policy
    depends_on:
      - redis
    volumes:
      - type: volume
        source: hyper_static
        target: /opt/hyperglass/hyperglass/static
    # Example custom configuration adoptions...
    #      - type: bind
    #        source: ./custom_config/hyperglass.yml
    #        target: /opt/hyperglass/hyperglass/hyperglass.yml
    #      - type: bind
    #        source: ./custom_config/commands.yml
    #        target: /opt/hyperglass/hyperglass/commands.yml
    #      - type: bind
    #        source: ./custom_config/devices.yml
    #        target: /opt/hyperglass/hyperglass/devices.yml

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
