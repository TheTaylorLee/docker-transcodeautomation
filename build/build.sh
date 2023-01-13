# CI/CD for maintainers only and for those trying to build their own image from the source
## BuildImages
cd ~
rm docker-transcodeautomation -d -r
git clone https://github.com/TheTaylorLee/docker-transcodeautomation
cd docker-transcodeautomation
version=v2.5.0
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ttlee/docker-transcodeautomation:ubuntu22.04-lts-$version .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ttlee/docker-transcodeautomation:alpine3.14-lts-$version .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ttlee/docker-transcodeautomation:ubuntu22.04-lts .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ttlee/docker-transcodeautomation:alpine3.14-lts .

### Pushing the images
docker push ttlee/docker-transcodeautomation -a
