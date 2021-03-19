FROM ubuntu:18.04

RUN /bin/bash -c 'set -x;\
    apt-get -qq update; \
    useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat; \
    apt-get install -y openjdk-8-jre wget bsdtar ssh sudo gettext vim; \
    usermod -a -G tomcat root'

ENV ACCUMULO_VERSION=1.7.1
ENV HADOOP_VERSION=2.7.2
ENV RYA_EXAMPLE_VERSION=4.0.1
ENV RDF4J_VERSION=2.5.5
ENV ZOOKEEPER_VERSION=3.6.2
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
ENV HADOOP_HOME=/root/hadoop-${HADOOP_VERSION}
# Accumulo requires ZOOKEEPER_HOME to point to ZOOKEEPER_HOME/lib
ENV ZOOKEEPER_HOME=/root/apache-zookeeper-${ZOOKEEPER_VERSION}-bin/lib
ENV ZOOKEEPER_TRUE_HOME=/root/apache-zookeeper-${ZOOKEEPER_VERSION}-bin
ENV ZOO_LOG_DIR=${ZOOKEEPER_TRUE_HOME}/logs/
ENV ZOO_DATA_DIR=${ZOOKEEPER_TRUE_HOME}/data/
ENV PATHADD=$JAVA_HOME/bin:$ZOOKEEPER_TRUE_HOME/bin:$ACCUMULO_HOME/bin:$HADOOP_HOME/bin
ENV PATH=$PATH:$PATHADD
ENV HADOOP_PREFIX="$HADOOP_HOME"
ENV HADOOP_CONF_DIR="$HADOOP_PREFIX/etc/hadoop"
ENV ACCUMULO_HOME=/root/accumulo-${ACCUMULO_VERSION}
ENV ACCUMULO_LOG_DIR=$ACCUMULO_HOME/logs
ENV ACCUMULO_TSERVER_OPTS="-Xmx384m -Xms384m "
ENV ACCUMULO_MASTER_OPTS="-Xmx128m -Xms128m"
ENV ACCUMULO_MONITOR_OPTS="-Xmx64m -Xms64m"
ENV ACCUMULO_GC_OPTS="-Xmx64m -Xms64m"
ENV ACCUMULO_GENERAL_OPTS="-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -Djava.net.preferIPv4Stack=true"
ENV ACCUMULO_OTHER_OPTS="-Xmx128m -Xms64m"
ENV ACCUMULO_KILL_CMD='kill -9 %p'
ENV ACCUMULO_RC=/root/.accumulo_rc.sh
ENV MAVEN_REPO_URL=https://repo1.maven.org/maven2/
ENV RYA_INDEXING=rya.indexing.example-${RYA_EXAMPLE_VERSION}-distribution
ENV WORKBENCH=/opt/tomcat/webapps/rdf4j-workbench.war
ENV RDF4J_WAR=/opt/tomcat/webapps/rdf4j-server.war
ENV RYA_VAGRANT=rya.vagrant.example-${RYA_EXAMPLE_VERSION}
ENV RYA_WAR=web.rya-${RYA_EXAMPLE_VERSION}.war
ENV TOMCAT_HOME=/opt/tomcat

WORKDIR /root

RUN /bin/bash -c 'wget -c https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -O - | tar -zx ; \
    wget -c https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz -O - | tar -zx ; \
    wget -c https://archive.apache.org/dist/accumulo/${ACCUMULO_VERSION}/accumulo-${ACCUMULO_VERSION}-bin.tar.gz -O - | tar -zx ; \
    wget -O ${RYA_INDEXING}.zip ${MAVEN_REPO_URL}org/apache/rya/rya.indexing.example/${RYA_EXAMPLE_VERSION}/${RYA_INDEXING}.zip; \
    wget -O ${RYA_VAGRANT}.jar ${MAVEN_REPO_URL}org/apache/rya/rya.vagrant.example/${RYA_EXAMPLE_VERSION}/${RYA_VAGRANT}.jar; \
    wget -O ${RYA_WAR} ${MAVEN_REPO_URL}org/apache/rya/web.rya/${RYA_EXAMPLE_VERSION}/${RYA_WAR}; \
    wget -O ${TOMCAT_HOME}.zip https://downloads.apache.org/tomcat/tomcat-9/v9.0.44/bin/apache-tomcat-9.0.44.zip; \
    wget -O rdf4j-workbench.war ${MAVEN_REPO_URL}org/eclipse/rdf4j/rdf4j-http-workbench/${RDF4J_VERSION}/rdf4j-http-workbench-${RDF4J_VERSION}.war; \
    wget -O rdf4j-server.war ${MAVEN_REPO_URL}org/eclipse/rdf4j/rdf4j-http-server/${RDF4J_VERSION}/rdf4j-http-server-${RDF4J_VERSION}.war;'

COPY resources/.accumulo_rc.sh /root/.accumulo_rc.sh
COPY resources/zookeeper/zoo.cfg ${ZOOKEEPER_TRUE_HOME}/conf/zoo.cfg

ENV ZOOKEEPERS="rya"
RUN /bin/bash -c 'mkdir --parents ${RYA_INDEXING} ${RYA_VAGRANT} ${TOMCAT_HOME} ${ZOO_DATA_DIR} ${ZOO_LOG_DIR}; \
    bsdtar -xvf ${RYA_INDEXING}.zip -C ${RYA_INDEXING}; \
    bsdtar -xvf ${RYA_VAGRANT}.jar -C ${RYA_VAGRANT}; \
    bsdtar --strip-components=1 -xvf ${TOMCAT_HOME}.zip -C ${TOMCAT_HOME}; \
    sudo -u tomcat mkdir --parents ${TOMCAT_HOME}/server/logs; \
    sudo -u tomcat mkdir --parents ${TOMCAT_HOME}/.RDF4J/server/logs; \
    cp rdf4j-workbench.war ${WORKBENCH}; \
    cp rdf4j-server.war ${RDF4J_WAR}; \
    chmod 700 ${TOMCAT_HOME}/bin/*; \
    touch ${ZOO_LOG_DIR}/zookeeper.out; \
    chmod -R a+wX  ${ZOO_LOG_DIR} ${ZOO_DATA_DIR}; \
    envsubst < ${ZOOKEEPER_TRUE_HOME}/conf/zoo.cfg > ${ZOOKEEPER_TRUE_HOME}/conf/zoo.cfg.new; \
    mv -f ${ZOOKEEPER_TRUE_HOME}/conf/zoo.cfg.new ${ZOOKEEPER_TRUE_HOME}/conf/zoo.cfg'


RUN /bin/bash -c 'cat /root/.accumulo_rc.sh > /root/.bashrc.new; \
    cat /root/.bashrc >> /root/.bashrc.new; \
    mv -f /root/.bashrc.new /root/.bashrc; \
    cat /root/.accumulo_rc.sh > /root/.bash_profile.new; \
    cat /root/.bash_profile >> /root/.bash_profile.new; \
    mv -f /root/.bash_profile.new /root/.bash_profile;'


RUN /bin/bash -c 'cp ${ACCUMULO_HOME}/conf/examples/1GB/standalone/* ${ACCUMULO_HOME}/conf/; \
rm --force ${ACCUMULO_HOME}/conf/accumulo-site.xml;'

COPY resources/accumulo/conf/accumulo-site.xml ${ACCUMULO_HOME}/conf/accumulo-site.xml

RUN /bin/bash -c 'mkdir --parents /data; \
    chown root:root /data; \
    mkdir --parents /data/accumulo/lib/ext; \
    chmod -R a+rwX ${ACCUMULO_HOME}/logs/'

COPY resources/entrypoint.sh entrypoint.sh

RUN /bin/bash -c 'chmod a+rwX ./entrypoint.sh'

EXPOSE 8080 2181

CMD ["./entrypoint.sh"]