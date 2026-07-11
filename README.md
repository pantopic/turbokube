# Pantopic Turbokube

<img alt="Turbokube" title="Turbokube" src="https://raw.githubusercontent.com/pantopic/turbokube-loadtest/main/junk/turbokube.png" align="right" width="360" />

An [etcd](https://pkg.go.dev/github.com/tetratelabs/wazero) compatible distributed database.

## Status

This repository has two side-by-side implementations, one native and one in WebAssembly. The same test suite can be run
against native, WebAssembly, or an etcd instance to evaluate parity.

Many uncommonly used etcd features are not implemented (such as locks and leader election).

## Name

This model was originally named something else. A [load test](https://github.com/pantopic/turbokube-loadtest) was created and named Turbokube due to its architecture. We
commissioned a logo and made some stickers for the turbokube load test project and people liked the logo even knowing
nothing bout the project. At the same time, some features like Lease ID selection in the Lease API forced us to lean
toward an API that only supports the Go Client not the gRPC API which basically makes it tailor made for Kubernetes.
So this model was renamed from `config-bus` to `turbokube` to adopt the logo and make the expected use case more clear.

## Roadmap

This project is in alpha. Breaking changes should be expected until Beta.

- `v0.0.x` - Alpha
  - [ ] Migrate working implementation to Pantopic model (Wasm)
- `v0.1.x` - Beta
  - [ ] Add metrics
  - [ ] Test in production
- `v1.x.x` - General Availability
  - [ ] Proven long term stability in production
