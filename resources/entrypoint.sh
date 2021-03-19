#!/bin/bash

### wait for a directory to exist or 60 seconds timeout
function waitForDeploy {
    waitfordir="$1"
    timeout=60
    while [[ ! -d  "$waitfordir" ]]  
    do
        sleep 5
        let timeout-=5
        if [[ $timeout -le "0" ]]; then 
            echo "Timeout waiting for war to deploy, $waitfordir still does not exist."; 
            exit 401 
        fi
    done
}

if [[ ! -f "$ZOO_DATA_DIR/myid" ]]; then
    echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
fi

${ZOOKEEPER_TRUE_HOME}/bin/zkServer.sh start

sed -i "s/localhost/${HOSTNAME}/" ${ACCUMULO_HOME}/conf/masters
sed -i "s/localhost/${HOSTNAME}/" ${ACCUMULO_HOME}/conf/slaves
envsubst < ${ACCUMULO_HOME}/conf/accumulo-site.xml > ${ACCUMULO_HOME}/conf/accumulo-site.xml.new
mv -f ${ACCUMULO_HOME}/conf/accumulo-site.xml.new ${ACCUMULO_HOME}/conf/accumulo-site.xml

${ACCUMULO_HOME}/bin/accumulo init --clear-instance-name --instance-name dev --password root
${ACCUMULO_HOME}/bin/start-all.sh  || exit 107
chmod -R a+rwX ${ACCUMULO_HOME}/logs/

chown -R tomcat:tomcat /opt/tomcat/webapps/
chown -R tomcat:tomcat /root
chmod 777 -R /opt/tomcat/webapps/
chmod 777 -R /root
${TOMCAT_HOME}/bin/startup.sh

waitForDeploy ${TOMCAT_HOME}/webapps/rdf4j-workbench/WEB-INF/lib/
waitForDeploy ${TOMCAT_HOME}/webapps/rdf4j-server/WEB-INF/lib/

chown -R tomcat:tomcat /opt/tomcat/webapps/
chmod 777 -R /opt/tomcat/webapps/

# soft linking the files doesn't seem to work in tomcat, so we copy them instead :(
sudo -u tomcat cp ${RYA_INDEXING}/dist/lib/* ${TOMCAT_HOME}/webapps/rdf4j-workbench/WEB-INF/lib/ || exit 113
sudo -u tomcat cp ${RYA_INDEXING}/dist/lib/* ${TOMCAT_HOME}/webapps/rdf4j-server/WEB-INF/lib/    || exit 114
# These are older libs that break tomcat and rdf4j that come with Rya above.
sudo -u tomcat rm --force ${TOMCAT_HOME}/webapps/rdf4j-workbench/WEB-INF/lib/servlet-api-2.5.jar
sudo -u tomcat rm --force ${TOMCAT_HOME}/webapps/rdf4j-workbench/WEB-INF/lib/jsp-api-2.1.jar

s=${TOMCAT_HOME}/webapps/rdf4j-server/WEB-INF/lib/
rm --force $s/servlet-api-2.5.jar   $s/lib/jsp-api-2.1.jar
find "$s" -name 'spring-*-3.*.jar' -exec rm --force {} +
rm $s/spring-aop-4.2.1.RELEASE.jar $s/rdf4j-http-server-spring-2.3.1.jar
rm --force  $s/slf4j-log4j12-1.7.25.jar   $s/slf4j-api-1.7.25.jar  $s/jcabi-log-0.14.jar   $s/jcl-over-slf4j-1.7.25.jar   $s/minlog-1.3.0.jar   $s/commons-logging-1.1.1.jar   $s/log4j-1.2.16.jar
chown -R tomcat:tomcat ${TOMCAT_HOME}/webapps/rdf4j-workbench/WEB-INF/lib/
chown -R tomcat:tomcat ${TOMCAT_HOME}/webapps/rdf4j-server/WEB-INF/lib/

waitForDeploy ${TOMCAT_HOME}/webapps/rdf4j-workbench/transformations
cp ${RYA_VAGRANT}/*.xsl ${TOMCAT_HOME}/webapps/rdf4j-workbench/transformations/
chown tomcat:tomcat ${TOMCAT_HOME}/webapps/rdf4j-workbench/transformations/*

rm -rf ${TOMCAT_HOME}/webapps/web.rya/WEB-INF/classes
cp ${RYA_WAR} ${TOMCAT_HOME}/webapps/web.rya.war
# Wait for the war to deploy
waitForDeploy ${TOMCAT_HOME}/webapps/web.rya/WEB-INF/classes/
# These are older libs that break tomcat
rm --force ${TOMCAT_HOME}/webapps/web.rya/WEB-INF/lib/servlet-api-2.5*.jar
rm --force ${TOMCAT_HOME}/webapps/web.rya/WEB-INF/lib/jsp-api-2.1.jar
echo "Modify Rya Web Config"
chmod -R a+rwX ${TOMCAT_HOME}/webapps/web.rya/
cat > ${TOMCAT_HOME}/webapps/web.rya/WEB-INF/classes/environment.properties <<EOF
instance.name=dev
instance.zk=localhost:2181
instance.username=root
instance.password=root
rya.tableprefix=rya_
rya.displayqueryplan=true
EOF
echo "sleeping 60 sek. and then restarting tomcat"
sleep 60
echo "restarting tomcat"
${TOMCAT_HOME}/bin/shutdown.sh
sleep 10
${TOMCAT_HOME}/bin/startup.sh

echo "Rya web deployed at http://${HOSTNAME}:8080/web.rya/sparqlQuery.jsp"
echo "RDF4J workbench deployed at http://${HOSTNAME}:8080/rdf4j-workbench"
echo "RDF4J server deployed at http://${HOSTNAME}:8080/rdf4j-server"
tail -f /dev/null