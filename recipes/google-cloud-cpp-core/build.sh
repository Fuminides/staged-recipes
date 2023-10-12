#!/bin/bash

set -euo pipefail

export OPENSSL_ROOT_DIR=$PREFIX

if [[ "${target_platform}" == osx-* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): Building __common__ features..."
cmake ${CMAKE_ARGS} \
    -GNinja -S . -B build_common \
    -DGOOGLE_CLOUD_CPP_ENABLE=__common__ \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DOPENSSL_ROOT_DIR=$PREFIX \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc \
    -DGOOGLE_CLOUD_CPP_GRPC_PLUGIN_EXECUTABLE=$BUILD_PREFIX/bin/grpc_cpp_plugin \
    -DGOOGLE_CLOUD_CPP_ENABLE_WERROR=OFF

cmake --build build_common
cmake --install build_common --prefix stage
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): DONE - Building __common__ features"

### This loop would go in the google-cloud-cpp-core-feedstock
### Other feedstocks may have similar loops, for example:
### feedstock name        | list
### google-cloud-cpp-core | __common__ bigtable oauth2
###                       | (iam pubsub policytroubleshooter) spanner storage
### google-cloud-cpp-ai   | aiplatform automl dialogflow_es dialogflow_cx dlp
###                       | (contentwarehouse documentai) speech texttospeech
###                       | timeseriesinsights translate videointelligence 
###                       | vision
### google-cloud-cpp      | __ga_features__,-{all the other items} 
for feature in oauth2 bigtable spanner storage; do
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): Building ${feature}"
  cmake ${CMAKE_ARGS} \
      -GNinja -S . -B build_${feature} \
      -DGOOGLE_CLOUD_CPP_ENABLE=${feature} \
      -DGOOGLE_CLOUD_CPP_USE_INSTALLED_COMMON=ON \
      -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH};${PWD}/stage" \
      -DBUILD_TESTING=OFF \
      -DBUILD_SHARED_LIBS=ON \
      -DOPENSSL_ROOT_DIR=$PREFIX \
      -DCMAKE_BUILD_TYPE=release \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc \
      -DGOOGLE_CLOUD_CPP_GRPC_PLUGIN_EXECUTABLE=$BUILD_PREFIX/bin/grpc_cpp_plugin \
      -DGOOGLE_CLOUD_CPP_ENABLE_WERROR=OFF
  cmake --build build_${feature}
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): DONE - Building ${feature}"
done

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): Building pubsub"
cmake ${CMAKE_ARGS} \
    -GNinja -S . -B build_pubsub \
    -DGOOGLE_CLOUD_CPP_ENABLE=pubsub,iam,policytroubleshooter \
    -DGOOGLE_CLOUD_CPP_USE_INSTALLED_COMMON=ON \
    -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH};${PWD}/stage" \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DOPENSSL_ROOT_DIR=$PREFIX \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc \
    -DGOOGLE_CLOUD_CPP_GRPC_PLUGIN_EXECUTABLE=$BUILD_PREFIX/bin/grpc_cpp_plugin \
    -DGOOGLE_CLOUD_CPP_ENABLE_WERROR=OFF
cmake --build build_pubsub
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ'): DONE - Building pubsub"
