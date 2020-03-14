#!/bin/bash
#### For version: HDP 3.1.x
#### This script has to be run on the LLAP Host.
#### It can be ported to retrieve information using the Ambari REST APIs, allowing this to work from any host. Using bash for speed.

#### Pre-requisites:
# 1) LLAP is installed on this host.
# 2) Spark Client is installed on this host.

# File holder for required information:
hive_site_llap=/etc/hive_llap/conf/hive-site.xml
beeline_site_llap=/etc/hive_llap/conf/beeline-site.xml

if [ -f "$hive_site_llap" ] && [ -f "$beeline_site_llap" ]; then

    hive_metastore_uris=$(grep -e "thrift.*9083" "$hive_site_llap" |awk -F"<|>" '{print $3}')
    hive_llap_daemon_service_hosts=$(grep "hive.llap.daemon.service.hosts" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hwc_jar=$(find /usr/hdp/current/hive_warehouse_connector/ -name *assembly*.jar)
    hwc_pyfile=$(find /usr/hdp/current/hive_warehouse_connector/ -name *hwc*.zip)
    hive_jdbc_url=$(grep "beeline.hs2.jdbc.url.llap" -A1 "$beeline_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_jdbc_url_principal=$(grep "hive.server2.authentication.kerberos.principal" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_llap" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')

    echo -e "Copy and paste the following as a bulk input in Ambari -> Spark2 -> Configs -> Advanced -> Custom spark2-hive-site-override (Bulk Property Add mode)\n"
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


else echo $hive_site_llap" and/or "$beeline_site_llap" doesn't exist on this host, make sure to run this in the LLAP Host"
fi
