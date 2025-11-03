dev:
	@go build -ldflags="-s -w" -o _dist/turbokube ./cmd/turbokube && cd cmd/turbokube && docker compose up --build

test:
	@go test ./...

cover:
	@mkdir -p _dist
	@go test -coverprofile=_dist/coverage.out -v
	@go tool cover -html=_dist/coverage.out -o _dist/coverage.html

cloc:
	@cloc . --exclude-dir=_example,_dist,proto --exclude-ext=pb.go
