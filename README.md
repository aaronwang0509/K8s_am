# Upgrade Process for AM 7.1.4 Kubernetes Cluster

This guide describes the process to upgrade an AM 7.1.4 Kubernetes cluster with external replicated Directory Servers (DS) without downtime.

## Upgrade Steps Overview
1. **Stop and Upgrade Directory Servers (DS):**
    - Stop DS1, upgrade, and restart.
    - Repeat the process for other DS instances.

2. **Upgrade AM Kubernetes Cluster:**
    - Build an image with the new AM WAR file.
    - Start a new cluster alongside the existing one.
    - Run tests, and upon passing, shut down the old cluster.

## Upgrade Diagram
![Upgrade Process Diagram](upgrade_diagram.png)

## 1. Building the Old System

### 1.1 Creating External Directory Servers (DS)

**Configuration:**
- A set of replicated DS is running on multiple AWS EC2 instances as AM configuration, CTS, and identity stores.
- Example setup uses DS version 7.1.7.

**Setup Commands for DS1:**

```bash
# dse1, ds1

export DEPLOYMENT_KEY=ACDDRasfQ4DEOCRM8u4963oSCVMSnA5CBVN1bkVDALAdRZFYWf1w2yw
echo $DEPLOYMENT_KEY

./setup \
    --serverId ds1 \
    --deploymentKey $DEPLOYMENT_KEY \
    --deploymentKeyPassword password \
    --rootUserDN uid=admin \
    --rootUserPassword password \
    --hostname ec2-52-71-219-6.compute-1.amazonaws.com \
    --adminConnectorPort 4444 \
    --ldapPort 1389 \
    --enableStartTls \
    --ldapsPort 1636 \
    --httpsPort 8443 \
    --replicationPort 8989 \
    --bootstrapReplicationServer ec2-52-71-219-6.compute-1.amazonaws.com:8989 \
    --bootstrapReplicationServer ec2-52-26-251-242.us-west-2.compute.amazonaws.com:8989 \
    --profile ds-evaluation \
    --set ds-evaluation/generatedUsers:100 \
    --profile am-config \
    --set am-config/amConfigAdminPassword:password \
    --profile am-cts \
    --set am-cts/amCtsAdminPassword:password \
    --profile am-identity-store \
    --set am-identity-store/amIdentityStoreAdminPassword:password \
    --profile idm-repo \
    --set idm-repo/domain:forgerock.com \
    --acceptLicense

cd cert
keytool -exportcert \
    -keystore ../config/keystore \
    -storepass $(cat ../config/keystore.pin) \
    -alias ssl-key-pair \
    -rfc \
    -file cert_ds1.pem

cp /usr/lib/jvm/jdk-11-oracle-x64/lib/security/cacerts ./truststore
keytool -storepasswd -keystore ./truststore

keytool \
    -importcert \
    -file cert_ds1.pem \
    -alias ds1 \
    -keystore ./truststore

keytool \
    -importcert \
    -file cert_ds2.pem \
    -alias ds2 \
    -keystore ./truststore
```
**Setup Commands for DS2:**

```bash
# dsw1, ds2

export DEPLOYMENT_KEY=ACDDRasfQ4DEOCRM8u4963oSCVMSnA5CBVN1bkVDALAdRZFYWf1w2yw
echo $DEPLOYMENT_KEY

./setup \
--serverId ds2 \
--deploymentKey $DEPLOYMENT_KEY \
--deploymentKeyPassword password \
--rootUserDN uid=admin \
--rootUserPassword password \
--hostname ec2-52-26-251-242.us-west-2.compute.amazonaws.com \
--adminConnectorPort 4444 \
--ldapPort 1389 \
--enableStartTls \
--ldapsPort 1636 \
--httpsPort 8443 \
--replicationPort 8989 \
--bootstrapReplicationServer ec2-52-71-219-6.compute-1.amazonaws.com:8989 \
--bootstrapReplicationServer ec2-52-26-251-242.us-west-2.compute.amazonaws.com:8989 \
--profile ds-evaluation \
--set ds-evaluation/generatedUsers:100 \
--profile am-config \
--set am-config/amConfigAdminPassword:password \
--profile am-cts \
--set am-cts/amCtsAdminPassword:password \
--profile am-identity-store \
--set am-identity-store/amIdentityStoreAdminPassword:password \
--profile idm-repo \
--set idm-repo/domain:forgerock.com \
--acceptLicense

cd cert
keytool -exportcert \
-keystore ../config/keystore \
-storepass $(cat ../config/keystore.pin) \
-alias ssl-key-pair \
-rfc \
-file cert_ds2.pem
```

### 1.2 Installing AM 7.1.4 Kubernetes Cluster

```bash
# Step 1: Copy the DS truststore file to the ./init/cert and ./addon/cert directories.

# Step 2: Build and push the init image from the ./init directory.
docker build -t k8sam:1.0.4 .
docker tag k8sam:1.0.4 aaronwang0509/k8sam:1.0.4
docker push aaronwang0509/k8sam:1.0.4

# Step 3: Start a Docker container to install the first AM instance.
docker run -p 18080:18080 --name am1 k8sam:1.0.4

# Step 4: Copy the security files out to the addon directory.
cd ./addon/init
docker cp am1:/usr/local/tomcat/am/tam/security/keystores .
docker cp am1:/usr/local/tomcat/am/tam/security/secrets/default ./secret

# Step 5: Build and push the addon image in the ./addon directory.
docker build -t k8sam:1.1.7 .
docker tag k8sam:1.1.7 aaronwang0509/k8sam:1.1.7
docker push aaronwang0509/k8sam:1.1.7

# Step 6: Go to the ./k8s directory, update the image tag, and deploy the cluster.
kubectl apply -f deployment.yaml

# Step 7: Shut down the initial AM instance.
docker rm -f am1
```
The Kubernetes system deployment is now complete.

## 2. Upgrade DS

### 2.1 Upgrade ds1

```bash
# Stop ds1
./ds717/bin/stop-ds

# Unzip new DS
unzip DS-7.4.1.zip && mv opendj ds741

# Copy new DS files to the old folder
sudo cp -r ds741/* ds717/

# Perform upgrade
./ds717/upgrade

# Restart ds1
./ds717/bin/start-ds
```

### 2.1 Upgrade other DS

```bash
# Repeat the process one by one for other DS instances.
```
DS upgrade complete.

## 3. Upgrade AM Kubernetes Cluster

### 3.1 Upgrade one instance

```bash
# Create a single deployment to perform the upgrade
cd ./k8s
kubectl apply -f upgrade.yaml

# Copy the new WAR file to the upgrade pod
kubectl cp AM-7.4.0.war amup-6574465fcc-9gj8d:/usr/local/tomcat

# Modify the upgrade pod
kubectl exec -it amup-6574465fcc-9gj8d /bin/bash

./bin/shutdown.sh

rm -rf ./webapps/openam.war
rm -rf ./webapps/openam
rm -rf ./work/Catalina/localhost/openam/

mv AM-7.4.0.war webapps/openam.war

./bin/startup.sh

# Wait for the pod to restart, then access the upgrade interface via the browser.
# URL: cdk.example.com:30081/openam
# Follow the instructions to upgrade AM to version 7.4.0.
```

### 3.2 Deploy a New Cluster

```bash
# Modify the addon Dockerfile to use the new AM-7.4.0.war file, then build and push the new addon image
docker build -t k8sam:1.1.8 .
docker tag k8sam:1.1.8 aaronwang0509/k8sam:1.1.8
docker push aaronwang0509/k8sam:1.1.8

# Deploy the new cluster
cd ./k8s
kubectl apply -f deploy_new.yaml
```

### 3.3 Shutdown the Old Cluster

```bash
# Now both clusters are running. Test the new cluster, then shut down the old cluster and the upgrade pod.
kubectl delete deployments tomcat-am-deployment amup
```

Cluster upgrade complete.