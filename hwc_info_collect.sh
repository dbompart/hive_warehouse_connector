#!/bin/bash
set -e
#### For version: CDP 7.2.2 Private Cloud Base

### Notes:

### For Reading:
### 1) Spark Direct Reader (HWC):
### - Does not enforce Ranger Policies
### - Needs filesystem policies/acls.
### 2) JDBC execution mode (HWC) 
### - Enforce Ranger policies. Connects to HS2.
### - For small datasets. What is the small definition here?
### 3) Spark Native (No HWC):
### - Enforce Ranger Policies. Connects to HMS.
### 
### Note: How does the HMS-Ranger integration works? How is that applying when SparkNative is used, but not when SparkDirectReader is used, although both query the HMS? 
### 
### For Writing:
### 1) Using HWC API:
### - Enforces Ranger policies through HS2 on Managed tables.
### - Executes "LOAD DATA".
### - Can be used for both Managed/External tables.
### 2) Using Spark API:
### - Enforces Ranger policies on external tables, through HMS API - Ranger integration.
### - No Managed tables support.


# Holder for required information:
hive_site=/etc/hive/conf/hive-site.xml
beeline_site=/etc/hive/conf.cloudera.hive_on_tez/beeline-site.xml

if [ -r "$hive_site" ] && [ -r "$beeline_site" ]; then

    hive_metastore_uris=$(grep -e "thrift.*9083" "$hive_site" |awk -F"<|>" '{print $3}')
    hive_llap_daemon_service_hosts=$(grep "hive.llap.daemon.service.hosts" -A1 "$hive_site" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hwc_jar=$(find /opt/cloudera/parcels/CDH/lib/ -name *hive-warehouse-connector*assembly*.jar)
    hwc_pyfile=$(find /opt/cloudera/parcels/CDH/lib/ -name pyspark_hwc-*.zip)
    hive_jdbc_url=$(grep "jdbc:hive2" "$beeline_site" -A1 | awk 'NR==1' | awk -F"[<|>]" '{print $3}')
    hive_jdbc_url_principal=$(grep "hive.server2.authentication.kerberos.principal" -A1 "$hive_site" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hms_uri=$(grep uri /etc/hive/conf/hive-site.xml -A1  |awk 'NR==2' | awk -F"[<|>]" '{print $3}')    

    echo -e "To apply this configuration cluster wide, copy and paste the following list of properties in CM UI -> Spark -> Configuration -> Spark Client Advanced Configuration Snippet (Safety Valve) for spark-conf/spark-defaults.conf\n"
    echo -e "These are the recommended properties for a production environment.\n\n"

	    echo -e "1st Option) AutoTranslate enabled: Use regular SPARK API, the reader/writer mode will be automatically selected based on the table's type..:\n"
	    echo -e "spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvertExtension"
	    echo -e "spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator"
	    
	    echo -e "\n2nd Option) Read: SparkDirectReader, Write: HWC. \n"
	    echo -e "spark.jars="$hwc_jar
	    echo -e "spark.submit.pyFiles="$hwc_pyfile
	    echo -e "spark.sql.hive.hiveserver2.jdbc.url="$hive_jdbc_url
	    echo -e "spark.sql.hive.zookeeper.quorum="$hive_zookeeper_quorum
	    echo -e "spark.hadoop.hive.metastore.uris="$hms_uri
	    echo -e "spark.sql.hive.hwc.execution.mode=spark"

	    echo -e "\n3rd Option) Read: JDBC, Write: HWC.\n"
	    echo -e "spark.jars="$hwc_jar
	    echo -e "spark.submit.pyFiles="$hwc_pyfile
	    echo -e "spark.sql.hive.hiveserver2.jdbc.url="$hive_jdbc_url
	    echo -e "spark.hadoop.hive.zookeeper.quorum="$hive_zookeeper_quorum
	    echo -e "spark.hadoop.hive.metastore.uris="$hms_uri
	    

	    #If Kerberized:
	    [ ! -z "$hive_jdbc_url_principal"] && echo -e "spark.sql.hive.hiveserver2.jdbc.url.principal="$hive_jdbc_url_principal

	    echo -e "\n### Save and restart."
	    echo -e "\nNote: In a kerberized environment the property spark.security.credentials.hiveserver2.enabled has to be set to TRUE for deploy-mode cluster, i.e.:\n spark-submit --conf spark.security.credentials.hiveserver2.enabled=true"

	    echo -e "\nIf you'd like to test this per job instead of cluster wide, then use the following command as an example:\n

            AutoTranslate:
	    spark-shell --master yarn --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp --conf spark.datasource.hive.warehouse.metastoreUri=$hive_metastore_uris --conf spark.hadoop.hive.llap.daemon.service.hosts=$hive_llap_daemon_service_hosts --conf spark.jars=$hwc_jar --conf spark.submit.pyFiles=$hwc_pyfile --conf spark.security.credentials.hiveserver2.enabled=false --conf spark.sql.hive.hiveserver2.jdbc.url=\"$hive_jdbc_url\" --conf spark.sql.hive.zookeeper.quorum=\"$hive_zookeeper_quorum\" \n

            SparkDirectReader:

	    spark-shell --master yarn --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp --conf spark.datasource.hive.warehouse.metastoreUri=$hive_metastore_uris --conf spark.hadoop.hive.llap.daemon.service.hosts=$hive_llap_daemon_service_hosts --conf spark.jars=$hwc_jar --conf spark.submit.pyFiles=$hwc_pyfile --conf spark.security.credentials.hiveserver2.enabled=false --conf spark.sql.hive.hiveserver2.jdbc.url=\"$hive_jdbc_url\" --conf spark.sql.hive.zookeeper.quorum=\"$hive_zookeeper_quorum\" \n

            JDBC Mode::

	    spark-shell --master yarn --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp --conf spark.datasource.hive.warehouse.metastoreUri=$hive_metastore_uris --conf spark.hadoop.hive.llap.daemon.service.hosts=$hive_llap_daemon_service_hosts --conf spark.jars=$hwc_jar --conf spark.submit.pyFiles=$hwc_pyfile --conf spark.security.credentials.hiveserver2.enabled=false --conf spark.sql.hive.hiveserver2.jdbc.url=\"$hive_jdbc_url\" --conf spark.sql.hive.zookeeper.quorum=\"$hive_zookeeper_quorum\" \n
            "

	    echo -e "Once in the Scala REPL, run the following snippet example to test basic conectivity:\n"
	    echo -e "scala> import com.hortonworks.hwc.HiveWarehouseSession"
	    echo "scala> import com.hortonworks.hwc.HiveWarehouseSession._"
	    echo "scala> val hive = HiveWarehouseSession.session(spark).build()"
	    echo -e "scala> hive.showDatabases().show()\n"

	else
	     echo -e $hive_site" and/or "$beeline_site" doesn't exist on this host, or the current user $(whoami) doesn't have access to the files\n"
     echo "Try running this command as the root or hive user"
fi
