#!/bin/bash

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
CA=$(cat /etc/kubernetes/ssl/kube-ca.pem | base64)
CERT=$(cat /etc/kubernetes/ssl/kube-etcd-192-168-[0-9]*-[0-9]*.pem | base64)
KEY=$(cat /etc/kubernetes/ssl/kube-etcd-192-168-[0-9]*-[0-9]*-key.pem | base64)

cat /secret-patch-template.json | \
	sed "s/CA/${CA}/" | \
	sed "s/CERT/${CERT}/" | \
	sed "s/KEY/$(KEY)/" \
	> /secret-patch.json

ls /secret-patch.json || exit 1

echo "Create secret ${SECRET}"
RESP=`curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPOST  -H "Accept: application/json, */*" -H "Content-Type: application/json" -d @/secret-patch.json https://kubernetes.default/api/v1/namespaces/storageos/secrets`
echo $RESPCODE=`echo $RESP | jq -r '.code'`

case $CODE in
200)
	echo "Secret Created"
	exit 0
	;;
*)
	echo "Unknown Error:"
	echo $RESP
	exit 1
	;;
esac
