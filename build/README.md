# CI/CD for maintainers only and for those trying to build their own image from the source
```sh
docker login -u ttlee
cd ~
git clone https://github.com/TheTaylorLee/docker-transcodeautomation
cd docker-transcodeautomation
version=v2.1.0
DOCKER_BUILDKIT=1 docker build -f Dockerfile.ubuntu22.04-lts -t ttlee/docker-transcodeautomation:ubuntu22.04-lts-$version .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.alpine3.14-lts -t ttlee/docker-transcodeautomation:alpine3.14-lts-$version .
```

- Pushing the images
```sh
docker push ttlee/docker-transcodeautomation:ubuntu22.04-lts-$version
docker push ttlee/docker-transcodeautomation:alpine3.14-lts-$version
```