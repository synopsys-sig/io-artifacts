#!/bin/sh

for i in "$@"; do
    case "$i" in
    --io.url=*) io_url="${i#*=}" ;;
    --username=*) userName="${i#*=}" ;;
    --password=*) password="${i#*=}" ;;
    *) ;;
    esac
done

signupResponse=$(curl --location --request POST "$io_url/io/user/signup" \
--header 'Content-Type: application/json' \
--data-raw '{
    "userName": '\"$userName\"',
    "password": '\"$password\"',
    "confirmPassword": '\"$password\"'
}');

userToken=$(curl --location --request POST "$io_url/io/user/token" \
--header 'Content-Type: application/json' \
--data-raw '{
	"userName": '\"$userName\"',
	"password": '\"$password\"'
}');

echo "IO_ACCESS_TOKEN: $userToken"

