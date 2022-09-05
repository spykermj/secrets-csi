local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local tk = import 'tk';

local secrets = import 'csisecrets/main.jsonnet';

secrets {
  _config+:: {
    namespace: tk.env.spec.namespace,
  },

  local namespace = k.core.v1.namespace,

  namespace: namespace.new($._config.namespace),
}
