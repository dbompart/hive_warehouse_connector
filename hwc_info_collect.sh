#!/bin/bash
set -e
#### For version: HDP 3.1.x
#### This script has to be run on the LLAP Host.
#### It can be ported to retrieve information using the Ambari REST APIs, allowing this to work from any host. Using bash for speed.

#### Pre-requisites:
# 1) LLAP is installed on this host.
# 2) Spark Client is installed on this host.

# File holder for required information:
hive_site_llap=/etc/hive_llap/conf/hive-site.xml
beeline_site_llap=/etc/hive_llap/conf/beeline-site.xml

if [ -r "$hive_site_llap" ] && [ -r "$beeline_site_llap" ]; then

    hive_metastore_uris=$(grep -e "thrift.*9083" "$hive_site_llap" |awk -F"<|>" '{print $3}')
    hive_llap_daemon_service_hosts=$(grep "hive.llap.daemon.service.hosts" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hwc_jar=$(find /usr/hdp/current/hive_warehouse_connector/ -name *assembly*.jar)
    hwc_pyfile=$(find /usr/hdp/current/hive_warehouse_connector/ -name *hwc*.zip)
    hive_jdbc_url=$(grep "beeline.hs2.jdbc.url.llap" -A1 "$beeline_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_jdbc_url_principal=$(grep "hive.server2.authentication.kerberos.principal" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')

    echo -e "Copy and paste the following list of properties in Ambari UI -> Spark2 -> Configs -> Advanced -> Custom spark2-hive-site-override (Bulk Property Add mode)\n"
    echo -e "spark.datasource.hive.warehouse.load.staging.dir=/tmp"
    echo -e "spark.datasource.hive.warehouse.metastoreUri="$hive_metastore_uris
    echo -e "spark.hadoop.hive.llap.daemon.service.hosts="$hive_llap_daemon_service_hosts
    echo -e "spark.jars="$hwc_jar
    echo -e "spark.pyFiles="$hwc_pyfile
    echo -e "spark.security.credentials.hiveserver2.enabled=false"
    echo -e "spark.sql.hive.hiveserver2.jdbc.url="$hive_jdbc_url
    echo -e "spark.sql.hive.zookeeper.quorum="$hive_zookeeper_quorum
    #If Kerberized:
    [ ! -z "$hive_jdbc_url_principal"] && echo -e "spark.sql.hive.hiveserver2.jdbc.url.principal="$hive_jdbc_url_principal

    echo -e "\nNote: In a kerberized environment the property spark.security.credentials.hiveserver2.enabled has to be set to TRUE for deploy-mode cluster, i.e.:\n spark-submit --conf spark.security.credentials.hiveserver2.enabled=true"

    echo -e "\nFor a quick test before proceeding to configure this cluster wide, try the following command:\n

    spark-shell --master yarn --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp --conf spark.datasource.hive.warehouse.metastoreUri=$hive_metastore_uris --conf spark.hadoop.hive.llap.daemon.service.hosts=$hive_llap_daemon_service_hosts --conf spark.jars=$hwc_jar --conf spark.pyFiles=$hwc_pyfile --conf spark.security.credentials.hiveserver2.enabled=false --conf spark.sql.hive.hiveserver2.jdbc.url=$hive_jdbc_url --conf spark.sql.hive.zookeeper.quorum=$hive_zookeeper_quorum \n"

else
     echo -e $hive_site_llap" and/or "$beeline_site_llap" doesn't exist on this host, or the current user $(whoami) doesn't have access to the files\n"
     echo "Try running this command as the root or hive user"
fi
