
tag-api-1 = 10



### api-1-amd64
docker-build-api-1-amd64:
	docker build --build-arg PLATFORM_ARCH=amd64 --build-arg APP_DIR=apis/api-1 -t zolinz/api-1-amd64:$(tag-api-1) -f docker/Dockerfile.apis .

docker-build-push-api-1-amd64: docker-build-api-1-amd64
	docker push zolinz/api-1-amd64:$(tag-api-1)


label-ns:
	 kubectl label namespace monkey istio-injection=enabled

rollout:
	kubectl -n monkey rollout restart deployment monkey
