#!/bin/bash

# Version
MARIADB_DRIVER_VERSION="2.4.1"
HAWKBIT_TAG="0.3.0M6"
HAWKBIT_POM_VERSION="0.3.0-SNAPSHOT"
DOCKER_TAG_VERSION="0.3.0M6"
HAWKBIT_EXTENSION_VERSION="51f880d77ccc32baac0233751a56107c11523a6b"

# Image name
H2_NAME="hawkbit_s3_h2"
MYSQL_NAME="hawkbit_s3_mysql"

parse_argument() {
  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"

    case ${key} in
    --user | -u)
      user=${2}
      shift
      shift
      ;;
    -h | --help)
      display_usage && exit 0
      shift
      ;;
    *) # unknown option
      POSITIONAL+=("$1")
      shift
      ;;
    esac
  done
  set -- "${POSITIONAL[@]}"
}

display_usage() {
  echo "Option: --user|-u user to tag with"
}

main() {
  parse_argument "${@}"
  if [[ -z ${user} ]];then
    echo "Specify user to tag the resulting image. Option -u|--user"
    exit 1
  fi

  echo "Building docker file"
  docker build . --build-arg MARIADB_DRIVER_VERSION="${MARIADB_DRIVER_VERSION}" \
                --build-arg HAWKBIT_TAG="${HAWKBIT_TAG}" \
                --build-arg HAWKBIT_POM_VERSION="${HAWKBIT_POM_VERSION}" \
                --build-arg HAWKBIT_EXTENSION_VERSION="${HAWKBIT_EXTENSION_VERSION}"

  echo "Tagging"
  docker build --build-arg MARIADB_DRIVER_VERSION="${MARIADB_DRIVER_VERSION}" \
                --build-arg HAWKBIT_TAG="${HAWKBIT_TAG}" \
                --build-arg HAWKBIT_POM_VERSION="${HAWKBIT_POM_VERSION}" \
                --build-arg HAWKBIT_EXTENSION_VERSION="${HAWKBIT_EXTENSION_VERSION}" \
                --target hawkbit_h2 -t "${user}/${H2_NAME}:${DOCKER_TAG_VERSION}" .

  docker build --build-arg MARIADB_DRIVER_VERSION="${MARIADB_DRIVER_VERSION}" \
                --build-arg HAWKBIT_TAG="${HAWKBIT_TAG}" \
                --build-arg HAWKBIT_POM_VERSION="${HAWKBIT_POM_VERSION}" \
                --build-arg HAWKBIT_EXTENSION_VERSION="${HAWKBIT_EXTENSION_VERSION}" \
                --target hawkbit_mysql -t "${user}/${MYSQL_NAME}:${DOCKER_TAG_VERSION}" .

  echo "Done building"
}

main "${@}"
