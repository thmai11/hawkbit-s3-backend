This container contains:
- Hawkbit update server, https://github.com/eclipse/hawkbit Tag: 0.3.0M6

- Hawkbit S3 extension, https://github.com/eclipse/hawkbit-extensions SHA1: 51f880d77ccc32baac0233751a56107c11523a6b

- MariaDB Connector, https://downloads.mariadb.com/Connectors/java/connector-java-2.4.1/mariadb-java-client-2.4.1.jar Version: 2.4.1

See database support: https://github.com/eclipse/hawkbit#runtime-dependencies-and-support
(Ignore the warning of FLYWAY that the connector mariaDB do not work with mysql 5.7 See: https://github.com/flyway/flyway/issues/2099 )

Compiled on maven:3.6.2-jdk-8 
Running on openjdk:8u201-jre-alpine

Run Example: 
```
docker run -d -p 8080:8080 -v "$(pwd)/application.properties:/opt/hawkbit/application.properties" "${image}" \
     -e SPRING_DATASOURCE_URL=jdbc:mysql://$HOST:$PORT/hawkbit
     -e SPRING_DATASOURCE_USERNAME=$USER \
     -e SPRING_DATASOURCE_PASSWORD=$PASSWORD \
       "java -jar hawkbit-update-server.jar \
       -Dspring.config.additional-location=application.properties \
       -Daws.accessKeyId=$ACCESSKEY \
       -Daws.secretKey=$SECRET_KEY \
        $ANY_JVM_PROPERTY "
```
Example: 
```
 "java -jar /opt/hawkbit/hawkbit-update-server.jar --spring.profiles.active=mysql -Xms768m -Xmx768m -XX:MaxMetaspaceSize=250m -XX:MetaspaceSize=250m -Xss300K -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+UseCompressedOops -XX:+HeapDumpOnOutOfMemoryError -Dspring.config.additional-location=application.properties -Daws.accessKeyId=${ACCESS_KEY} -Daws.secretKey=${SECRET_KEY}"
```

application.properties MUST contain the following key (i.e. 'us-east-1'): 
```
      aws.region=$AWS_REGION
```
Other environment variables required if using the DMF API (rabbitMQ):
```
      -e SPRING_RABBITMQ_HOST=rabbitmq
      -e SPRING_RABBITMQ_USERNAME=guest
      -e SPRING_RABBITMQ_PASSWORD=guest
```
To disable the DMF API add the following to application.properties:
```
hawkbit.dmf.rabbitmq.enabled=false
```

Properties needed in application.properties for using the s3 backend:
```
##############
# s3 Backend
##############
org.eclipse.hawkbit.artifact.repository.s3.enabled=true
aws.region=us-east-1
org.eclipse.hawkbit.repository.s3.bucketName=$YOUR_BUCKET_NAME
```
To serve directly the link to s3 to target you can modify those properties as well:
```
##############
# Serve directly the s3 bucket
##############
hawkbit.artifact.url.protocols.download-http.rel=http
hawkbit.artifact.url.protocols.download-http.protocol=http
hawkbit.artifact.url.protocols.download-http.port=80
hawkbit.artifact.url.protocols.download-http.hostname=$YOU_BUCKET_NAME.amazonaws.com
hawkbit.artifact.url.protocols.download-http.supports=DDI
hawkbit.artifact.url.protocols.download-http.ref={protocol}://{hostname}:{port}/{tenant}/{artifactSHA1}
```
