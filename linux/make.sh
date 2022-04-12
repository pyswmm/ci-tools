#!/bin/bash

#
#  make.sh - Builds swmm executable
#
#  Date Created: 06/29/2020
#  Date Modified: 07/06/2020
#
#  Authors:      See AUTHORS
#
#  Environment Variables:
#    PROJECT name for project
#
#  Optional Arguments:
#    -g ("GENERATOR") defaults to "Ninja"
#    -t builds and runs unit tests (requires Boost)

shopt -s nocasematch

export BUILD_HOME="build"


# determine project directories
CURRENT_DIR=${PWD}
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${SCRIPT_HOME}
cd ../../
PROJECT_DIR=${PWD}


# determine project
if [ -z "${PROJECT}" ]; then
    if [[ $( basename $PROJECT_DIR ) == "STO"* || "SWM"* ]]; then
         export PROJECT="swmm"
    elif [[ $( basename $PROJECT_DIR ) == "WAT"* || "EPA"* ]]; then
        export PROJECT="epanet"
    fi
fi


# check that PROJECT is defined
if [ -z "${PROJECT}" ]; then
    echo "ERROR: PROJECT must be defined"
    exit 1
fi


# prepare for artifact upload
if [ ! -d upload ]; then
    mkdir upload
fi

echo INFO: Building ${PROJECT}  ...

GENERATOR="Unix Makefiles"
TESTING=0
BUILD_SHARED_LIBS=ON

POSITIONAL=()

while [ $# -gt 0 ]; do
key="$1"
case $key in
    -g|--gen)
    GENERATOR="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--test)
    TESTING=1
    shift # past argument
    ;;
    -s|--static)
    BUILD_SHARED_LIBS=OFF
    shift # past argument
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# perform the build
cmake -E make_directory ${BUILD_HOME}

RESULT=$?

if [ ${TESTING} -eq 1 ]; then
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS="${BUILD_SHARED_LIBS}" .. \
    && cmake --build ./${BUILD_HOME}  --config Debug \
    && cmake -E chdir ./${BUILD_HOME}  ctest -C Debug --output-on-failure
    RESULT=$?
else
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=OFF -DBUILD_SHARED_LIBS="${BUILD_SHARED_LIBS}" .. \
    && cmake --build ./${BUILD_HOME} --config Release --target package
    RESULT=$?
    cp ./${BUILD_HOME}/*.tar.gz ./upload >&1
fi

export PLATFORM="linux"

#GitHub Actions
echo "PLATFORM=$PLATFORM" >> $GITHUB_ENV

# return user to current dir
cd ${CURRENT_DIR}

exit $RESULT
