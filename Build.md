# CI/CD for maintainers only and for those trying to build their own image from the source
```sh
docker login -u ttlee
cd ~
git clone https://github.com/TheTaylorLee/docker-transcodeautomation
cd ~/docker-transcodeautomation
build01=ubuntu22.04
version=1.0
DOCKER_BUILDKIT=1 docker build -t ttlee/docker-transcodeautomation:$build01-$version .
```

- Pushing the images
```sh
docker login -u ttlee
build01=ubuntu22.04
version=1.0
docker push ttlee/docker-transcodeautomation:$build01-$version
```