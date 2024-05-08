export CATALINA_OPTS="$CATALINA_OPTS -server -Xmx2g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m"
export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.trustStore=/usr/local/tomcat/cert/truststore -Djavax.net.ssl.trustStorePassword=password -Djavax.net.ssl.trustStoreType=jks"
