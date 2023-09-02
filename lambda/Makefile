.PHONY: build

build:
	sam build

# https://www.gaunt.dev/blog/2022/glibc-error-with-aws-sam-and-go/
build-CloudTrailFunction:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main main.go
	mv main $(ARTIFACTS_DIR)