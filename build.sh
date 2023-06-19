# Build from source
cd ~
rm docker-transcodeautomation -d -r
git clone https://github.com/thetaylorlee/docker-transcodeautomation
cd docker-transcodeautomation
version=$(cat version)

## Build Dev
#DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:ubuntu22.04-lts-develop .
#DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:alpine3.14-lts-develop .

## Build Prod
### Ubuntu
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:ubuntu22.04-lts-$version .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:ubuntu22.04-lts .

### Alpine
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:alpine3.14-lts-$version .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:alpine3.14-lts .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ghcr.io/thetaylorlee/docker-transcodeautomation:latest .

### Pushing the images for maintainers only. Currently managed by actions
#docker push ghcr.io/thetaylorlee/docker-transcodeautomation -a