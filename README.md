# Spark - HWC, The initial setup process

The purpose of this repo is to provide quick examples and utililities to work on a Spark and Hive integration on HDP 3.1.4

#### Prerequisites:

- HiveServer2Interactive (LLAP) installed, up and running.
- Bash and Python interpreter available.
- Ideally for connections using HTTP transport protocol, `hive.server2.thrift.http.cookie.auth.enabled` should be `true`.
- Set hadoop.proxyuser.hive.hosts=*  in the Ambari -> HDFS -> Configs -> Custom core-site section. (core-site.xml), or mention at least the LLAP Hosts, HS2 Hosts and Spark client hosts separated by commas.

Once the LLAP service is up and running, the next step for this setup requires the bellow properties to be configured in the Spark client:

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

While the above information can be manually collected as explained in our [Cloudera official documentation](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.4/integrating-hive/content/hive_configure_a_spark_hive_connection.html), the following steps will help in collecting the standard information and avoid making mistakes during the copy and paste process of parameter values between HS2I and Spark:

Steps:

```
ssh root@my-llap-host 
cd /tmp
wget https://raw.githubusercontent.com/dbompart/hive_warehouse_connector/master/hwc_info_collect.sh
chmod +x  hwc_info_collect.sh
./hwc_info_collect.sh
``` 
The above script will inmediatly provide enough information with regard to:
1. The information to enable the Spark and Hive integration (HWConnector)
2. A working spark-shell command to test initial connectivity
3. A short how-to list all Databases in Hive, in scala.

# LDAP/AD Authentication

#### Pre-requisite, refer to Spark - HWC, The initial setup process.

In an LDAP enabled authentication setup, the username and password will be passed in plaintext. The recommendation is to Kerberize the cluster, otherwise expect to see the username and password exposed in clear text amongst the logs.

To provide username and password, we’ll have to specify them as part of the jdbc url string in the following format:

> jdbc:hive2://zk1:2181,zk2:2181,zk3:2181/;user=myusername;password=mypassword;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2-interactive

**Note**: We’ll need to URL encode the password if it has a special character, for example, _user=hr1;password=BadPass#1_ will translate to _user=hr1;password=BadPass%231_

*This method is not fully supported for Spark HWC integration.*

# Kerberos Authentication

For Kerberos authentication, pre-conditions have to be met:

1. Initial "kinit" has to always be executed and validated.
	```
	$ kinit dbompart@EXAMPLE.COM
    Password for dbompart@EXAMPLE.COM:
    
    $ klist -v
	Credentials cache: API:501:9
        Principal: dbompart@EXAMPLE.COM
    Cache version: 0

	Server: krbtgt/EXAMPLE.COM@EXAMPLE.COM
	Client: dbompart@EXAMPLE.COM
	Ticket etype: aes128-cts-hmac-sha1-96
	Ticket length: 256
	Auth time:  Feb 11 16:11:36 2013
	End time:   Feb 12 02:11:22 2013
	Renew till: Feb 18 16:11:36 2013
	Ticket flags: pre-authent, initial, renewable, forwardable
	Addresses: addressless
    ```

2. For YARN, HDFS, Hive and HBase long-running jobs DelegationTokens have to be fetched, so we'll have to provide "--keytab" and "--principal" extra arguments, i.e.:
	```
	spark-submit $arg1 $arg2 $arg3 $arg-etc --keytab my_file.keytab 
	--principal dbompart@EXAMPLE.COM --class a.b.c.d app.jar
	``` 
3. For Kafka, a JAAS file has to be provided:
	
	**With a keytab, recommended for long running jobs:**
	```
	KafkaClient { 
	com.sun.security.auth.module.Krb5LoginModule required 
	useKeyTab=true 
	keyTab="./my_file.keytab" 
	storeKey=true 
	useTicketCache=false 
	serviceName="kafka" 
	principal="user@EXAMPLE.COM"; 
	};
	```

	**Without a keytab, usually used for batch jobs:**
	```
	KafkaClient { 
	com.sun.security.auth.module.Krb5LoginModule required 
	useTicketCache=true 
	renewTicket=true 
	serviceName="kafka"; 
	};
	```
	And it also has to be mentioned at the JVM level:

	```
    spark-submit $arg1 $arg2 $arg3 $arg-etc --files jaas.conf 
    --conf spark.driver.extraJava.Options="-Djava.security.auth.login.config=./jaas.conf"
    --conf spark.executor.extraJavaOptions=-Djava.security.auth.login.config=./jaas.conf"
    ```

# Livy2 - Example

```
curl -X POST --data '{"kind": "pyspark", "queue": "default", "conf": { "spark.jars": "/usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.4.32-1.jar", "spark.submit.pyFiles":"/usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.4.32-1.zip", "spark.hadoop.hive.llap.daemon.service.hosts": "@llap0","spark.sql.hive.hiveserver2.jdbc.url": "jdbc:hive2://[node2.cloudera.com:2181,node3.cloudera.com:2181,node4.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2-interactive](http://node2.cloudera.com:2181,node3.cloudera.com:2181,node4.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2-interactive)", "spark.yarn.security.credentials.hiveserver2.enabled": "false","spark.sql.hive.hiveserver2.jdbc.url.principal": "hive/[_HOST@EXAMPLE.COM](mailto:_HOST@EXAMPLE.COM)", "spark.datasource.hive.warehouse.load.staging.dir": "/tmp", "spark.datasource.hive.warehouse.metastoreUri": "thrift://node3.cloudera.com:9083", "spark.hadoop.hive.zookeeper.quorum": "[node2.cloudera.com:2181,node3.cloudera.com:2181,node4.cloudera.com:2181](http://node2.cloudera.com:2181,node3.cloudera.com:2181,node4.cloudera.com:2181)"}}' -H "X-Requested-By: admin" -H "Content-Type: application/json" --negotiate -u : [http://node3.cloudera.com:8999/sessions/](http://node3.cloudera.com:8999/sessions/) | python -mjson.tool
```
Submitting a brief example to show databases (hive.showDatabases()):
```
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/statements -X POST -H 'Content-Type: application/json' -H "X-Requested-By: admin" -d '{"code":"from pyspark_llap import HiveWarehouseSession"}'
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/statements -X POST -H 'Content-Type: application/json' -H "X-Requested-By: admin" -d '{"code":"hive = HiveWarehouseSession.session(spark).build()"}'
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/statements -X POST -H 'Content-Type: application/json' -H "X-Requested-By: admin" -d '{"code":"hive.showDatabases().show()"}'
```
Quick reference for basic API commands to check on the application status:
```
# Check sessions. Based on the ID field, update the following curl commands to replace "2" with $ID.
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/ | python -mjson.tool

# Check session status
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/status | python -mjson.tool

# Check session logs
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/log | python -mjson.tool

# Check session statements
curl --negotiate -u : http://node2.cloudera.com:8999/sessions/2/statements | python -mjson.tool
```
# Zeppelin - Example

### Livy2 Interpreter

Assumptions:

- The cluster is kerberized.
- LLAP has already been enabled.
- We got the initial setup information using the script [hwc_info_collect.sh](https://github.com/dbompart/hive_warehouse_connector/blob/master/hwc_info_collect.sh "hwc_info_collect.sh")
- In `Ambari->Spark2->Configs->Advanced livy2-conf`, the property `livy.spark.deployMode` should be set to either "yarn-cluster" or just plain "cluster". **Note:** *Client* mode is not supported.

Extra steps:

- Add the following property=value in `Ambari->Spark2->Configs->Custom livy2-conf` section:
		- livy.file.local-dir-whitelist=/usr/hdp/current/hive_warehouse_connector/

We can test our configurations before setting them statically in the Interpreter:

Notebook -> First paragraph:

```
%livy2.conf
livy.spark.datasource.hive.warehouse.load.staging.dir=/tmp
livy.spark.datasource.hive.warehouse.metastoreUri=
livy.spark.hadoop.hive.llap.daemon.service.hosts=@llap0
livy.spark.jars=file:/
livy.spark.security.credentials.hiveserver2.enabled=true
livy.spark.sql.hive.hiveserver2.jdbc.url=jdbc:hive2://
livy.spark.sql.hive.hiveserver2.jdbc.url.principal=hive/_HOST@
livy.spark.submit.pyFiles=file:/
livy.spark.hadoop.hive.zookeeper.quorum=
```
Please note that compared to a regular `spark-shell`or `spark-submit`, this time we'll have to specify the filesystem scheme `file:///`, otherwise it'll try to reference a path on HDFS by default.


# Creating a Table with Dummy data in Hive
For this specific task, we can expedite the table creation and dummy data ingest by referring to the [Cloudera's VideoKB](https://community.cloudera.com/t5/Customer/Video-KB-How-to-generate-Hive-Random-Data-based-on-input/ta-p/271204)

In the above link we'll find a Python script to create and load a table based on an input table schema, written by Pablo Junge. The script file is available in this github repo as well [HiveRandom.zip](https://github.com/dbompart/hive_warehouse_connector/blob/master/HiveRandom.zip "HiveRandom.zip")

Another short bash script is available [show_create_cleaner.sh](https://github.com/dbompart/hive_warehouse_connector/blob/master/show_create_cleaner.sh "show_create_cleaner.sh"), and it can be used as:
```
wget https://raw.githubusercontent.com/dbompart/hive_warehouse_connector/master/show_create_cleaner.sh
chmod +x  show_create_cleaner.sh
./show_create_cleaner.sh show_create_table_output_file.txt
```

This bash script is a quick cleaner, it will make the `Show create table`stmt output  re-usable in Hive or Spark by using `--clean` which will also remove the Table's Location and Table's Properties sections, i.e.:

```
./show_create_cleaner.sh show_create_table_output_file.txt --clean
```

# Common errors

### No service instances found in registry
Check again the configuration settings, specially the llap.daemon.service.hosts value and also the corresponding zNode which should be available and readable in from Zookeeper.

### error: object hortonworks is not a member of package com
This usually means that either the either the HWC jar or zip files, were not successfully uploaded to the Spark classpath. We can confirm this by looking at the logs and searching for:
```
Uploading resource file:/usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.4.32-1.jar
```

#### Cannot run get splits outside HS2
Add hive.fetch.task.conversion="more" To Custom hiveserver2-interactive section. And check the LLAP logs if needed.

#### Results no more than 1000
Follow the HWS API guide. This usually means that execute() method was incorrectly used instead of executeQuery().

#### "Blacklisted configuration values in session config: spark.master"
In the `/etc/livy2/conf/spark-blacklist.conf` file on the Livy2 server host, reconfigure this file to allow/disallow for configurations to be modified. 

#### Unable to read HiveServer2 configs from ZooKeeper. Tried all existing HiveServer2 uris from ZooKeeper
LLAP may not be up and running or there is a problem on reading its znode.
  

# Suggested documentation

- [https://community.cloudera.com/t5/Community-Articles/Integrating-Apache-Hive-with-Apache-Spark-Hive-Warehouse/ta-p/249035](https://community.cloudera.com/t5/Community-Articles/Integrating-Apache-Hive-with-Apache-Spark-Hive-Warehouse/ta-p/249035)
- [https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.4/integrating-hive/content/hive_hivewarehouseconnector_for_handling_apache_spark_data.html](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.4/integrating-hive/content/hive_hivewarehouseconnector_for_handling_apache_spark_data.html)


