FROM maven:3.6.2-jdk-8  as builder

ARG HAWKBIT_POM_VERSION
ARG HAWKBIT_TAG
ARG HAWKBIT_EXTENSION_VERSION

RUN git clone --depth 1 --branch ${HAWKBIT_TAG} https://github.com/eclipse/hawkbit.git \
    && git clone --depth 1 https://github.com/eclipse/hawkbit-extensions.git \
    && git --git-dir hawkbit-extensions/.git checkout ${HAWKBIT_EXTENSION_VERSION} \
    && mvn -T $(nproc) -f hawkbit-extensions/pom.xml install \
    && sed -i 's/<dependencies>/<dependencies>\n<!--S3Extension-->\n<dependency>\n<groupId>org.eclipse.hawkbit<\/groupId>\n<artifactId>hawkbit-extension-artifact-repository-s3<\/artifactId>\n<version>\${project.version}<\/version>\n<\/dependency>\n<!--S3Extension-->/g' hawkbit/hawkbit-runtime/hawkbit-update-server/pom.xml  \
    && mvn -T $(nproc) -f hawkbit/pom.xml install -Daws.region=us-east-1

#####################
# Hawkbit H2 embedded
#####################
FROM openjdk:8u201-jre-alpine as hawkbit_h2

ENV HAWKBIT_HOME=/opt/hawkbit

ARG HAWKBIT_POM_VERSION
ARG MARIADB_DRIVER_VERSION

EXPOSE 8080
VOLUME "${HAWKBIT_HOME}/data"

RUN addgroup -S hawkbit && adduser -S hawkbit -G hawkbit

USER hawkbit

COPY --from=builder  /hawkbit/hawkbit-runtime/hawkbit-update-server/target/hawkbit-update-server-${HAWKBIT_POM_VERSION}.jar "${HAWKBIT_HOME}/hawkbit-update-server.jar"

WORKDIR ${HAWKBIT_HOME}
ENTRYPOINT ["java","-jar","hawkbit-update-server.jar","-Xms768m -Xmx768m -XX:MaxMetaspaceSize=250m -XX:MetaspaceSize=250m -Xss300K -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+UseCompressedOops -XX:+HeapDumpOnOutOfMemoryError"]

#####################
# Hawkbit Mariadb
#####################
FROM openjdk:8u201-jre-alpine as hawkbit_mysql

ENV HAWKBIT_HOME=/opt/hawkbit

ARG HAWKBIT_POM_VERSION
ARG MARIADB_DRIVER_VERSION

COPY KEY .

RUN set -x \
    && apk add --no-cache --virtual build-dependencies gnupg unzip libressl wget \
    && gpg --import KEY \
    && wget -O $JAVA_HOME/lib/ext/mariadb-java-client.jar --no-verbose https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_DRIVER_VERSION/mariadb-java-client-$MARIADB_DRIVER_VERSION.jar \
    && wget -O $JAVA_HOME/lib/ext/mariadb-java-client.jar.asc --no-verbose https://downloads.mariadb.com/Connectors/java/connector-java-$MARIADB_DRIVER_VERSION/mariadb-java-client-$MARIADB_DRIVER_VERSION.jar.asc \
    && gpg --verify --batch $JAVA_HOME/lib/ext/mariadb-java-client.jar.asc $JAVA_HOME/lib/ext/mariadb-java-client.jar \
    && apk del build-dependencies

EXPOSE 8080
VOLUME "${HAWKBIT_HOME}/data"

RUN addgroup -S hawkbit && adduser -S hawkbit -G hawkbit

USER hawkbit

COPY --from=builder  /hawkbit/hawkbit-runtime/hawkbit-update-server/target/hawkbit-update-server-${HAWKBIT_POM_VERSION}.jar "${HAWKBIT_HOME}/hawkbit-update-server.jar"

WORKDIR ${HAWKBIT_HOME}
ENTRYPOINT ["java","-jar","hawkbit-update-server.jar","--spring.profiles.active=mysql","-Xms768m -Xmx768m -XX:MaxMetaspaceSize=250m -XX:MetaspaceSize=250m -Xss300K -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+UseCompressedOops -XX:+HeapDumpOnOutOfMemoryError"]
