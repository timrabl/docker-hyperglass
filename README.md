# docker-hyperglass

[![GitHub Super-Linter](https://github.com/<OWNER>/<REPOSITORY>/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)

## Repositories ##
[![Docker Repository on Quay](https://quay.io/repository/timrabl/hyperglass/status "Docker Repository on Quay")](https://quay.io/repository/timrabl/hyperglass)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/timrabl/hyperglass)

A fork of [Hyperglass](https://github.com/thatmattlove/hyperglass), a network looking glass that tries to make the internet better...
But in a docker container...

You can find the official documentation [here](https://hyperglass.dev).

## Prerequisites

Hyperglass relies on a redis as a caching host. Thank god we have docker, so for the sake of simplicity we just start a redis container next to the one that contains hyperglass. If you don't want to use redis container just overwrite the redis host parameter in the configuration to your preferred redis instance.

## Before your start

In addition to redis i highly recommend to not expose the default image port (HTTP/8001), even if this image exposes this port.
This image is intended to just encapsulate the hyperglass application in a container and does not extend any functionality of the main application. If there is a missing application feature, open a issue at the official [hyperglass repository](https://github.com/thatmattlove/hyperglass/issues).

Use a proxy container like Nginx,Caddy,Trafik,... for HTTPS instead of the HTTP port.
You can find a example docker-compose.yml using Nginx for HTTPS and Redis for caching down below.

## Variables

**None**
Yep your heard right, no environment variables are required to start this container, just the redis instance. However, I would recommend you to replace the default configurations with your own configurations. This works great with a bind mount. But a custom image would be even better. A security question generally arises here in the structure of configuring the application, but let's leave that...

## Docker Compose

### Redis & Hyperglass & NGINX (HTTPS)

Example with redis and nginx:

```yaml
---
version: "3.7"

x-restart-policy: &x-restart-policy
  restart: unless-stopped

services:
  redis:
    image: redis:7-alpine
    <<: *x-restart-policy

  app:
    # image: timrabl/hyperglass:latest
    image: ghcr.io/timrabl/hyperglass:latest
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
    ports:
      - 8001:8001

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
