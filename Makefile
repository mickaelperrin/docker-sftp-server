PROJECT_NAME=sshserver

build:
	docker-compose -p "${PROJECT_NAME}" build

run:
	docker-compose -p "${PROJECT_NAME}" down
	docker-compose -p "${PROJECT_NAME}" up -d --build
	docker inspect --format='{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}' ${PROJECT_NAME}_sshd_1
	docker-compose logs -f
