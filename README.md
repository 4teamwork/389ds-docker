# 389 Directory Server

Dockerized [389 Directory Server (389ds)](https://directory.fedoraproject.org/) 

389ds is an enterprise-class open source LDAP server for Linux.

## Usage

The easiest way to use this image, is by adapting the given `docker-compose.yml`
file.

```
version: "3"

services:
  389ds:
    image: 4teamwork/389ds:latest
    ports:
      - 3389:3389
      - 3636:3636
    volumes:
      - ./data:/data
    environment:
      - SUFFIX_NAME=dc=example,dc=com
      - DS_DM_PASSWORD=secret
```

## Configuration

### `DS_DM_PASSWORD`

The password for the `cn=Directory Manager` user. The password is set only on
the first startup of the container. If not provided, a random one will be
generated.

### `SUFFIX_NAME`

The name of the suffix stored in the instance configuration. This does not
create the suffix! See [Creating Databases](#creating-databases) for how to
create a suffix.

## Volumes

The 389ds image exposes a volume under `/data`. You should mount a volume or a
host directory to that point to persist the data of your 389ds instance.

If the volume is empty, a new instance will be created on startup.

## Exposed Ports

The following ports are exposed:

 * 3389 (LDAP)
 * 3636 (LDAPS)

## Creating Databases

No backends or suffixes are created by default. To create a new backend with a
new suffix run: 

```
docker-compose exec 389ds dsconf localhost backend create --suffix="dc=example,dc=com" --be-name="example"
```

To populate the new backend with sample data run:

```
docker-compose exec 389ds dsidm localhost initialise
```
