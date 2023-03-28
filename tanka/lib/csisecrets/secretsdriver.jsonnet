local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

{
  _config+: {
    namespace: error 'must define namespace',
  },

  secretsDriver: helm.template('csi', './charts/secrets-store-csi-driver', {
    namespace: $._config.namespace,
    values: {
      syncSecret: { enabled: true },
    },
  }),
}
