local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

{
  _config+: {
    namespace: error 'must define namespace',
  },

  vault: helm.template('vault', './charts/vault', {
    namespace: $._config.namespace,
    values: {
      server: { dev: { enabled: true } },
      injector: { enabled: false },
      csi: { enabled: true },
    },
  }),
}
