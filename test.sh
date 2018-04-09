#!/bin/bash

RED='\033[01;31m'
GREEN='\033[01;32m'
NONE='\033[00m'

# build test image if no image name passed
if [ -z "$1" ]; then
  echo "Building test image from jwt-nginx"
  DOCKER_IMAGE_NAME=jwt-nginx-test
  docker build -f Dockerfile.test -t ${DOCKER_IMAGE_NAME} .
  if [ $? -ne 0 ]
  then
    echo -e "${RED}Build Failed${NONE}";
    exit 1;
  fi
else
  DOCKER_IMAGE_NAME=$1
  echo "Using image ${DOCKER_IMAGE_NAME} for tests"
fi

DOCKER_CONTAINER_NAME=${DOCKER_IMAGE_NAME}-cont
CONTAINER_ID=$(docker run --rm --name "${DOCKER_CONTAINER_NAME}" -d -p 8000:8000 ${DOCKER_IMAGE_NAME})

#MACHINE_IP=`docker-machine ip`
MACHINE_IP=localhost

VALIDJWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzb21lLWxvbmctdXVpZCIsImZpcnN0TmFtZSI6ImhlbGxvIiwgImxhc3ROYW1lIjoid29ybGQiLCJlbWFpbEFkZHJlc3MiOiJoZWxsb3dvcmxkQGV4YW1wbGUuY29tIiwgInJvbGVzIjpbInRoaXMiLCJ0aGF0IiwidGhlb3RoZXIiXSwgImlzcyI6Imlzc3VlciIsInBlcnNvbklkIjoiNzViYjNjYzctYjkzMy00NGYwLTkzYzYtMTQ3YjA4MmZhZGI1IiwgImV4cCI6MTkwODgzNTIwMCwiaWF0IjoxNDg4ODE5NjAwLCJ1c2VybmFtZSI6ImhlbGxvLndvcmxkIn0.TvDD63ZOqFKgE-uxPDdP5aGIsbl5xPKz4fMul3Zlti4

TEST_INSECURE_EXPECT_200=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000 -H 'cache-control: no-cache'`
if [ "$TEST_INSECURE_EXPECT_200" -eq "200" ];then
  echo -e "${GREEN}Insecure test pass ${TEST_INSECURE_EXPECT_200}${NONE}";
else
  echo -e "${RED}Insecure test fail ${TEST_INSECURE_EXPECT_200}${NONE}";
fi

TEST_SECURE_COOKIE_EXPECT_302=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000/secure/index.html -H 'cache-control: no-cache'`
if [ "$TEST_SECURE_COOKIE_EXPECT_302" -eq "302" ];then
  echo -e "${GREEN}Secure test without jwt cookie pass ${TEST_SECURE_COOKIE_EXPECT_302}${NONE}";
else
  echo -e "${RED}Secure test without jwt cookie fail ${TEST_SECURE_COOKIE_EXPECT_302}${NONE}";
fi

TEST_SECURE_COOKIE_EXPECT_200=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000/secure/index.html -H 'cache-control: no-cache' --cookie "rampartjwt=${VALIDJWT}"`
if [ "$TEST_SECURE_COOKIE_EXPECT_200" -eq "200" ];then
  echo -e "${GREEN}Secure test with jwt cookie pass ${TEST_SECURE_COOKIE_EXPECT_200}${NONE}";
else
  echo -e "${RED}Secure test with jwt cookie fail ${TEST_SECURE_COOKIE_EXPECT_200}${NONE}";
fi

TEST_SECURE_HEADER_EXPECT_200=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000/secure-auth-header/index.html -H 'cache-control: no-cache' --header "Authorization: Bearer ${VALIDJWT}"`
if [ "$TEST_SECURE_HEADER_EXPECT_200" -eq "200" ];then
  echo -e "${GREEN}Secure test with jwt auth header pass ${TEST_SECURE_HEADER_EXPECT_200}${NONE}";
else
  echo -e "${RED}Secure test with jwt auth header fail ${TEST_SECURE_HEADER_EXPECT_200}${NONE}";
fi

TEST_SECURE_HEADER_EXPECT_302=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000/secure-auth-header/index.html -H 'cache-control: no-cache'`
if [ "$TEST_SECURE_HEADER_EXPECT_302" -eq "302" ];then
  echo -e "${GREEN}Secure test without jwt auth header pass ${TEST_SECURE_HEADER_EXPECT_302}${NONE}";
else
  echo -e "${RED}Secure test without jwt auth header fail ${TEST_SECURE_HEADER_EXPECT_302}${NONE}";
fi

TEST_SECURE_NO_REDIRECT_EXPECT_401=`curl -X GET -o /dev/null --silent --head --write-out '%{http_code}\n' http://${MACHINE_IP}:8000/secure-no-redirect/index.html -H 'cache-control: no-cache'`
if [ "$TEST_SECURE_NO_REDIRECT_EXPECT_401" -eq "401" ];then
  echo -e "${GREEN}Secure test without jwt no redirect pass ${TEST_SECURE_NO_REDIRECT_EXPECT_401}${NONE}";
else
  echo -e "${RED}Secure test without jwt no redirect fail ${TEST_SECURE_NO_REDIRECT_EXPECT_401}${NONE}";
fi

docker stop ${DOCKER_CONTAINER_NAME} > /dev/null