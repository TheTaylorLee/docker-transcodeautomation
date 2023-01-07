# CI/CD for maintainers only and for those trying to build their own image from the source
```sh
cd ~
git clone https://github.com/TheTaylorLee/docker-transcodeautomation
cd ~/docker-transcodeautomation
build01=ubuntu22.04
version=1.0
DOCKER_BUILDKIT=1 docker build -t ttlee/docker-transcodeautomation:$build-$version .
```

- Pushing the images
```sh
build01=ubuntu22.04
version=1.0
docker login -u ttlee
docker push ttlee/docker-transcodeautomation:$build01-$version
```