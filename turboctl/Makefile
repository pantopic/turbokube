build:
	@go build

test:
	@go test ./...

cover:
	@mkdir -p _dist
	@go test -coverprofile=_dist/coverage.out -v
	@go tool cover -html=_dist/coverage.out -o _dist/coverage.html

cloc:
	@cloc . --exclude-dir=_example,_dist,proto --exclude-ext=pb.go

.PHONY: all test clean
