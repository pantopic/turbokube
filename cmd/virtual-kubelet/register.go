package main

import (
	"github.com/pantopic/turbokube/cmd/virtual-kubelet/internal/provider"
	"github.com/pantopic/turbokube/cmd/virtual-kubelet/internal/provider/mock"
)

func registerMock(s *provider.Store) {
	/* #nosec */
	s.Register("mock", func(cfg provider.InitConfig) (provider.Provider, error) { //nolint:errcheck
		return mock.NewMockProvider(
			cfg.ConfigPath,
			cfg.NodeName,
			cfg.OperatingSystem,
			cfg.InternalIP,
			cfg.DaemonPort,
		)
	})
}
