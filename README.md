# Spark - HWC, The initial setup process

This section corresponds to all those Spark Applications with Hive Integration on HDP 3.1.4

Initial setup requires the bellow properties to be configured:

```
spark.datasource.hive.warehouse.load.staging.dir=
spark.datasource.hive.warehouse.metastoreUri=
spark.hadoop.hive.llap.daemon.service.hosts=
spark.jars=
spark.security.credentials.hiveserver2.enabled=
spark.sql.hive.hiveserver2.jdbc.url=
spark.sql.hive.hiveserver2.jdbc.url.principal=
spark.submit.pyFiles=
spark.hadoop.hive.zookeeper.quorum=
```

The above information can be manually collected as explained in our Cloudera official documentation: https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.4/integrating-hive/content/hive_configure_a_spark_hive_connection.html

The following steps will help in collecting the standard information and avoid making mistakes during the copy and paste process of parameter values between HS2I and Spark:

Steps:

```
ssh root@my-llap-host 
cd /tmp
wget https://raw.githubusercontent.com/dbompart/hive_warehouse_connector/master/hwc_info_collect.sh
chmod +x  hwc_info_collect.sh
./hwc_info_collect.sh
``` 

# LDAP/AD Authentication

#### Pre-requisite, refer to Spark - HWC, The initial setup process.

In an LDAP enabled authentication setup, the username and password will be passed in plaintext. The recommendation is to Kerberize the cluster, otherwise expect to see the username and password exposed in clear text amongst the logs.

To provide username and password, we’ll have to specify them as part of the jdbc url string in the following format:

> jdbc:hive2://zk1:2181,zk2:2181,zk3:2181/;user=myusername;password=mypassword;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2-interactive

Note: We’ll need to URL encode the password if it has a special character, for example, _user=hr1;password=BadPass#1_ will translate to _user=hr1;password=BadPass%231_

This method is not fully supported for Spark HWC integration.

# Kerberos Authentication

# Livy2 - Example

# Zeppelin - Examples

### Spark Interpreter

### Livy2 Interpreter

### Pyspark Interpreter


# Troubleshooting common errors

### No LLAP instances

### Failed to import

#### Cannot run outside HS2

#### Results no more than 1000
