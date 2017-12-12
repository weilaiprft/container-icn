# IBM Content Navigator Container Overview
IBM® Content Navigator (ICN) container is a Docker image that enables you to quickly deploy IBM Content Navigator without a traditional software installation. The IBM Content Navigator container image is based on the IBM Content Navigator v3.0.3 and Liberty v17.0.0.3 releases. 

For more details about IBM Content Navigator, see the [IBM Knowledge Center](https://www.ibm.com/support/knowledgecenter/en/SSEUEX_3.0.3/KC_ditamaps/contentnavigator_3.0.3.htm).    

# Limitations

The following features are not currently available for this image:  

- P8 repository support only
- Session replication/persistent is not supported
- IBM Content Navigator Task Manager feature and functionality assocated with it such as...
    - Teamspace deletion  
    - IBM Content Navigator Box Share  
    - IBM Case Manager Box Integration  
    - IBM Enterprise Records sweep
    - ICC for SAP

# Known Issues

The following issues have been observed:

- Benign JAXRS exceptions being logged to Liberty log
- Benign Tag Library exception being logged to Liberty log during initial startup
- Not able to export desktop configuration

# Requirements and prerequisites

Before you deploy and run the IBM Content Navigator container image, confirm the following prerequisites:

- A Docker runtime environment (a Linux host or virtual machine with Docker installed)
- IBM FileNet P8 Content Platform Engine (CPE) container, deployed and configured    
- Supported LDAP provider (Microsoft Active Directory or IBM Security Directory Server)
- Supported database provider (currently only IBM DB2 v10.5 or higher)


# Preparing for container installation

## 1. Prepare the database.

You can use the provided sample database scripts to create and configure the IBM Content Navigator database on the DB2 server: [createICNDB.sh](https://github.ibm.com/ecm-container-service/navigator-docker/blob/master/examples/createICNDB.sh). <br>

Give proper privileges to the shell script:  
```
chmod 755 createICNDB.sh
```

On Linux, run the following shell (replace the parameters with the values for your system):  
```
su db2inst1
./createICNDB.sh -n ICNDB -s ICNSCHEMA -t ICNTS -u db2inst1 -a p8admin
```
The parameters are explained in the following table:

Name | Description | Required | 
------------ | ------------- | ------------- | 
n | Navigator database name | Yes | 
s | Navigator database schema name | Yes | 
t | Navigator database tablespace name | Yes | 
u | Navigator database user name | Yes | 
a | Navigator admin ID | Yes | 


## 2. Create volumes for the container.

Create directories on shared or local storage to hold the deployment-specific configuration files as well as data that lives outside the container. Ensure that the volume for logs and overrides is not shared with the Content Platform Engine container. Create the following folders:

Container folder | Host directory example | Description
------------ | ------------- | -------------
/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides | /home/data/configDropins/overrides | Configuration files for Liberty |
/opt/ibm/wlp/usr/servers/defaultServer/logs | /home/data/logs | Navigator and Liberty logs | 
/opt/ibm/plugins | /home/data/plugins | Custom plugins for Navigator
/opt/ibm/viewerconfig/logs | /home/data/viewerlog | Daeja VieweONE logs
/opt/ibm/viewerconfig/cache | /home/data/viewercache | Daeja VieweONE cache

## 3. Change owner permission on the host mount directories.
Because the IBM Content Navigator image is already security hardening, and services run with a non-root user (`uid=501` and `gid=500`), you must set owner permission on these host mount directories.

```
e.g.
- chown -R 501:500 /home/data/viewerlog
- chown -R 501:500 /home/data/viewercache
- chown -R 501:500 /home/data/plugins
- chown -R 501:500 /home/data/logs
- chown -R 501:500 /home/data/configDropins/overrides
```
Alternatively, change the owner for the parent folder:  
```
e.g.
- chown -R 501:500 /home/data/
```
## 4. Create the configuration details.

Create the following files with data that is specific to your environment:    
- XML configuration file for LDAP  (refer to sample for Microsoft Active Directory [ldapAD.xml](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples/ldapAD.xml))<br>
- XML configuration file for JDBC Driver (refer to sample for DB2 JDBC driver [DB2JCCDriver.xml](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples/DB2JCCDriver.xml))<br>
- XML configuration file for the IBM Content Navigator data source (refer to sample for data source configuration for DB2 [ICNDS.xml](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples/ICNDS.xml))<br>

Copy XML configuration files to configDropins/overrides directory</br>
- This should include: `ldap.xml` && `JDBC driver XML file` && `JDBC driver files` && `navigator data source xml file` (see above examples folder for examples XML files) </br>
- For example<br>
[root@nome1 overrides]# pwd<br>
/home/data/configDropins/overrides<br>
[root@nome1 overrides]# ls<br>
db2jcc4.jar  DB2JCCDriver.xml  db2jcc_license_cu.jar  ICNDS.xml  ldap.xml

Examples of these files can be found in [samples](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples).  


 
# Quickstart

## 1. Pull the IBM Content Navigator Docker image.

Use the following commands with your own credentials
- ```docker login -u [Docker ID] -p [Password]```
- ```docker pull ecmcontainers/ecm_earlyadopters_icn:earlyadopters-gm5.5```


## 2. Run the container in the Docker environment.

Reminder: A Linux host or virtual machine with Docker engine installed is required to run this image. You can use the information [here](https://docs.docker.com/engine/installation/) for Docker installation.

You can use the following sample command to run the IBM Content Navigator container:  

<b>Run Navigator container without monitoring:</b></br>
- ```docker run -d --name icn -p 9080:9080 -p 9443:9443 -v /home/data/plugins:/opt/ibm/plugins -v /home/data/viewerlog:/opt/ibm/viewerconfig/logs -v /home/data/viewercache:/opt/ibm/viewerconfig/cache -v /home/data/logs:/opt/ibm/wlp/usr/servers/defaultServer/logs -v /home/data/configDropins/overrides:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides ecmcontainers/ecm_earlyadopters_icn:earlyadopters-gm5.5```

After the container is started, you can browse to http://your-host-ip:9080/navigator or https://your-host-ip:9443/navigator on the host.

# Usage

## Set environment variables.  

Name | Description | Required | Default Value
------------ | ------------- | ------------- | -------------
JVM_HEAP_XMS | Initial Java heap size | No | 512m
JVM_HEAP_XMX | Maximum Java heap size | No | 1024m
TZ | Time Zone, Refer to [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for expected TZ | No | Etc/UTC
ICNJNDIDS | Navigator data source JNDI name | No | ECMClientDS
ICNSCHEMA | Navigator database schema name | No | ICNDB
ICNTS | Navigator database tablespace name | No | ICNDB


For monitoring environment variables, pls check [ECM Monitoring Github](https://github.ibm.com/ecm-container-service/ecm-container-monitoring#environment-variables)

## Run the IBM Content Navigator container with monitoring.  

Connect to the Bluemix metrics service by using IBM Cloud Monitoring metrics writer for space or organization scope, and connect to the Bluemix logging service using Bluemix multi-tenant lumberjack writer:
- ```docker run -d --name icn -p 9080:9080 -p 9443:9443 --hostname=icn1 -e MON_METRICS_WRITER_OPTION=2 -e MON_METRICS_SERVICE_ENDPOINT=metrics.ng.bluemix.net:9095 -e MON_BMX_GROUP=com.ibm.ecm.monitor. -e MON_BMX_METRICS_SCOPE_ID={space or organization guid} -e MON_BMX_API_KEY={IAM API key} -e MON_LOG_SHIPPER_OPTION=2 -e MON_BMX_SPACE_ID={tenant id} -e MON_LOG_SERVICE_ENDPOINT=logs.opvis.bluemix.net:9091 -e MON_BMX_LOGS_LOGGING_TOKEN={log logging token} -v /home/data/viewerlog:/opt/ibm/viewerconfig/logs -v /home/data/viewercache:/opt/ibm/viewerconfig/cache -v /home/data/plugins:/opt/ibm/plugins -v /home/data/logs:/opt/ibm/wlp/usr/servers/defaultServer/logs -v /home/data/configDropins/overrides:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides ecmcontainers/ecm_earlyadopters_icn:earlyadopters-gm5.5```

## Run the IBM Content Navigator container on Kubernetes.  

1. Prepare persistence volumes:  

Refer to [kubernetes document](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for information on persistence volume preparation.

2. Create a persistence volume claim ([sample YAML file for create PVC](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples/ecmcfgstore.yml)):
```
kubectl apply ecmcfgstore.yml
```
Use the following command to check persistence volume information:
```
kubectl describe pvc <PVC_NAME>
```
You can use the command to bind the persistence volume name to this persistence volume claim.

3. Provision data in the storage volume.
- Mount the configuration storage on the Kubernetes client:
```
mkdir /cfgstore
mount -t nfs4 -o hard,intr <PV_HOST>:/<PV_FOLDER> /cfgstore
```
Where PV_HOST is the server name of the persistence volume, and PV_FOLDER is the path for the persistence volume. You can check these values by running the following command:
```
kubectl describe pv <PV_NAME>  
```

- Create the following folders under /cfgstore
```
    /cfgstore/icn/viewerlog

    /cfgstore/icn/viewercache

    /cfgstore/icn/configDropins/overrides

    /cfgstore/icn/plugins

    /cfgstore/icn/logs
```
- Copy the overrides configuration file into NFS storage (Refer to [Configurations section](https://github.ibm.com/ecm-container-service/navigator-docker#2-configurations) for the sample configuration files.)

4. Deploy IBM Content Navigator ([sample YAML file for deploy navigator](https://github.ibm.com/ecm-container-service/navigator-docker/tree/master/examples/icn-deploy.yaml)).

```
kubectl create -f icn-deploy.yaml
```


# Support
Support can be obtained at [IBM® DeveloperWorks Answers](https://developer.ibm.com/answers/)
<br>
Use the ECM-CONTAINERS tag and assistance will be provided.<br>
*Note: Limited support available during Early Adopter Program*
