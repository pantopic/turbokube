dev:
	@go build -ldflags="-s -w" -o _dist/standalone ./cmd/standalone && cd cmd/standalone && docker compose up --build

cluster:
	@go build -ldflags="-s -w" -o _dist/cluster ./cmd/cluster && cd cmd/cluster && docker compose up --build

cluster-zig:
	@go build -ldflags="-s -w" -o _dist/cluster-zig ./cmd/cluster-zig && cd cmd/cluster-zig && docker compose up --build

build:
	@go build -ldflags="-s -w" -o _dist/pcb ./cmd/standalone

build-cluster:
	@go build -ldflags="-s -w" -o _dist/pcb ./cmd/cluster

build-cluster-zig:
	@go build -ldflags="-s -w" -o _dist/pcb ./cmd/cluster-zig

test:
	@go test -v

integration:
	@go test ./...

parity:
	@PARITY_CHECK=true go test -v

test-cluster:
	@CLUSTER_CHECK=true go test -v

test-cluster-zig:
	@CLUSTER_CHECK=true ZIG=true go test -v

bench:
	@go test -bench=. -run=_ -v

unit:
	@go test ./... -tags unit -v

scp:
	@scp -o "StrictHostKeyChecking=accept-new" ./_dist/pcb root@etcd-0:/usr/bin/pcb
	@scp -o "StrictHostKeyChecking=accept-new" ./_dist/pcb root@etcd-1:/usr/bin/pcb
	@scp -o "StrictHostKeyChecking=accept-new" ./_dist/pcb root@etcd-2:/usr/bin/pcb

scp-0:
	@scp -o "StrictHostKeyChecking=accept-new" ./_dist/pcb root@etcd-0:/usr/bin/pcb

get-logs:
	@scp -o "StrictHostKeyChecking=accept-new" root@etcd-0:~/nohup.out ./_logs/pcb.etcd-0.log
	@scp -o "StrictHostKeyChecking=accept-new" root@etcd-1:~/nohup.out ./_logs/pcb.etcd-1.log
	@scp -o "StrictHostKeyChecking=accept-new" root@etcd-2:~/nohup.out ./_logs/pcb.etcd-2.log

cover:
	@mkdir -p _dist
	@go test -coverprofile=_dist/coverage.out -v
	@go tool cover -html=_dist/coverage.out -o _dist/coverage.html

cloc:
	@cloc . --exclude-dir=_example,_dist,internal --exclude-ext=pb.go

cloc-native:
	@cloc . --exclude-dir=_example,_dist,internal,module --exclude-ext=pb.go

cloc-wasm:
	@cloc ./module --exclude-dir=_example,_dist,internal,patch --exclude-ext=pb.go

gen: gen-host gen-lite gen-zig

gen-host:
	@protoc internal/*.proto \
		--go_out=internal \
		--go_opt=paths=source_relative \
		--go-grpc_out=internal \
		--go-grpc_opt=paths=source_relative \
		-I internal

gen-lite:
	@protoc internal/*.proto \
		--plugin protoc-gen-go-lite="${GOBIN}/protoc-gen-go-lite" \
		--go-lite_out=module/service-grpc/internal  \
		--go-lite_opt=paths=source_relative \
		--go-lite_opt=features=marshal+unmarshal+size \
		-I internal
	@cp module/service-grpc/internal/* module/storage-kv/internal
	@cp module/service-grpc/internal/* module/storage-lease/internal

gen-install:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

gen-lite-install:
	go install github.com/aperturerobotics/protobuf-go-lite/cmd/protoc-gen-go-lite@latest

WASM_MODULES := \
	bridge-kv \
	bridge-lease \
	control-basic \
	service-grpc \
	storage-kv \
	storage-lease 

WASM_MODULES_ZIG := \
	service-grpc \
	storage-kv 

define WASM_BUILD_GO
cd module/$(1) && tinygo build -buildmode=wasi-legacy -target=wasi -opt=2 -gc=leaking -scheduler=none -o ../../embed/wasm/$(1).dev.wasm && cd ../..;
cd module/$(1) && tinygo build -buildmode=wasi-legacy -target=wasi -opt=s -gc=leaking -scheduler=none -o ../../embed/wasm/$(1).wasm -no-debug && cd ../..;
endef

wasm-go:
	$(foreach mod,$(WASM_MODULES),$(call WASM_BUILD_GO,$(mod)))

wasm-go-mod:
	$(call WASM_BUILD_GO,$(filter-out $@,$(MAKECMDGOALS)))

# Catch-all target to prevent Make from failing on unknown targets (ie. arguments to wasm-go-mod)
%:
	@true

define WASM_BUILD_ZIG
cd module-zig/$(1) && zig build --release=small && cp zig-out/bin/$(1).wasm ../../embed/wasm/$(1).zig.wasm && cd ../..;
cd module-zig/$(1) && zig build && cp zig-out/bin/$(1).wasm ../../embed/wasm/$(1).zig.dev.wasm && cd ../..;
endef

wasm-zig:
	$(foreach mod,$(WASM_MODULES_ZIG),$(call WASM_BUILD_ZIG,$(mod)))

wasm: wasm-go wasm-zig

define GO_WORK_USE
go work use module/$(1);
endef

work:
	$(foreach mod,$(WASM_MODULES),$(call GO_WORK_USE,$(mod)))

gen-zig:
	@cd module-zig/service-grpc && zig build gen-proto
	@cd module-zig/storage-kv && zig build gen-proto

.PHONY: test
