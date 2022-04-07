#!/usr/bin/env zsh
#
#
#  make.sh - Builds swmm/epanet executable
#
#  Date Created: 06/29/2020
#       Updated: 08/21/2020
#
#  Authors:      See AUTHORS
#
#  Environment Variables:
#    PROJECT
#
#  Optional Arguments:
#    -g ("GENERATOR") defaults to "Ninja"
#    -t builds and runs unit tests (requires Boost)


setopt extendedglob

export BUILD_HOME="build"

# determine project directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}
cd ./../../
PROJECT_DIR=${PWD}


# determine project
if [[ ! -v PROJECT ]]
then
[[ $( basename $PROJECT_DIR ) = ((#i)'STO'*|(#i)'SWM'*) ]] && { export PROJECT="swmm" }
[[ $( basename $PROJECT_DIR ) = ((#i)'WAT'*|(#i)'EPA'*) ]] && { export PROJECT="epanet" }
fi
# check that PROJECT is defined
[[ ! -v PROJECT ]] && { echo "ERROR: PROJECT must be defined"; return 1 }


# prepare for artifact upload
if [ ! -d upload ]; then
    mkdir upload
fi

echo INFO: Building ${PROJECT}  ...

GENERATOR="Xcode"
TESTING=0
BUILD_SHARED_LIBS=ON

POSITIONAL=()

while [[ $# -gt 0 ]]
do
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

if [ ${TESTING} -eq 1 ];
then
    echo "Building debug"
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=ON -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS="${BUILD_SHARED_LIBS}" .. \
    && cmake --build ./${BUILD_HOME}  --config Debug \
    && cmake -E chdir ./${BUILD_HOME}  ctest -C Debug --output-on-failure
    RESULT=$?
else
    echo "Building release"
    cmake -E chdir ./${BUILD_HOME} cmake -G "${GENERATOR}" -DBUILD_TESTS=OFF -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS="${BUILD_SHARED_LIBS}" .. \
    && cmake --build ./${BUILD_HOME} --config Release --target package
    RESULT=$?
    cp ./${BUILD_HOME}/*.tar.gz ./upload >&1
fi

export PLATFORM="darwin"

#GitHub Actions
echo "PLATFORM=$PLATFORM" >> $GITHUB_ENV

# return user to current dir
cd ${CUR_DIR}


return $RESULT
