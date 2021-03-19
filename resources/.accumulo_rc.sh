export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export ZOOKEEPER_HOME=$ZOOKEEPER_HOME
export ZOO_LOG_DIR=$ZOO_LOG_DIR
export ACCUMULO_HOME=$ACCUMULO_HOME
export PATH=\\$PATH:$PATHADD
export HADOOP_PREFIX=$HADOOP_PREFIX
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export ACCUMULO_LOG_DIR=$ACCUMULO_LOG_DIR
export ACCUMULO_TSERVER_OPTS=$ACCUMULO_TSERVER_OPTS
export ACCUMULO_MASTER_OPTS=$ACCUMULO_MASTER_OPTS
export ACCUMULO_MONITOR_OPTS=$ACCUMULO_MONITOR_OPTS
export ACCUMULO_GC_OPTS=$ACCUMULO_GC_OPTS
export ACCUMULO_GENERAL_OPTS=$ACCUMULO_GENERAL_OPTS
export ACCUMULO_OTHER_OPTS=$ACCUMULO_OTHER_OPTS
export ACCUMULO_KILL_CMD=$ACCUMULO_KILL_CMD

### command to list the 7 correct java processes: tomcat-catalina, zookeeper, and 5 Accumulo: tracer, master, monitor, tserver, gc.
function ryaps() { ps -ef | grep java | tr ' ' '\n' | egrep '^org\.apache|^tracer|^master|^monitor|^tserver|^gc' | sed '/\.Main/ N ; s/\n/ /' ; }

# Important, file must end with empty line
