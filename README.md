# Vault Secrets in k8s

This was set up basically following a [tutorial](https://learn.hashicorp.com/tutorials/vault/kubernetes-secret-store-driver)
from HashiCorp.

The only changes made were in the area of not using default as the namespace.

## Build Environment with Tanka

Not covered yet.

## Set Up Vault

~~~
kubectl -n csi-system exec -it vault-0 -- /bin/sh
vault kv put secret/db-pass password="db-secret-password"
vault kv get secret/db-pass
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
vault policy write internal-app - <<EOF
path "secret/data/db-pass" {
  capabilities = ["read"]
}
EOF
vault write auth/kubernetes/role/database \
    bound_service_account_names=webapp-sa \
    bound_service_account_namespaces=csi-system \
    policies=internal-app \
    ttl=20m
exit
~~~


## Define SecretProviderClass Resource

~~~
cat > spc-vault-database.yaml <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database
spec:
  provider: vault
  secretObjects:
  - data:
    - key: password
      objectName: db-password
    secretName: dbpass
    type: Opaque
  parameters:
    vaultAddress: "http://vault.csi-system:8200"
    roleName: "database"
    objects: |
      - objectName: "db-password"
        secretPath: "secret/data/db-pass"
        secretKey: "password"
EOF
kubectl -n csi-system apply -f spc-vault-database.yaml
~~~


## Deploy Application to Use the Secret

~~~
kubectl -n csi-system create serviceaccount webapp-sa
cat > webapp-pod.yaml <<EOF
kind: Pod
apiVersion: v1
metadata:
  name: webapp
spec:
  serviceAccountName: webapp-sa
  containers:
  - image: jweissig/app:0.0.1
    name: webapp
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: dbpass
          key: password
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "vault-database"
EOF
kubectl -n csi-system apply -f webapp-pod.yaml
~~~
