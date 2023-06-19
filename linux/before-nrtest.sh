#! /bin/bash
#
#  before-test.sh - Prepares Travis CI worker to run swmm regression tests
#
#  Date Created: 04/05/2018
#
#  Authors:      See AUTHORS
#
#  Dependencies:
#    curl
#    tar
#
#  Environment Variables:
#    PROJECT
#    BUILD_HOME - relative path
#    PLATFORM
#    NRTESTS_URL
#
#  Arguments:
#    1 - (RELEASE_TAG)  - Release tag
#
#  Note:
#    Tests and benchmark files are stored in the swmm-example-networks repo.
#    This script retreives them using a stable URL associated with a release on
#    GitHub and stages the files for nrtest to run. The script assumes that
#    before-test.sh and app-config.sh are located together in the same folder.


export TEST_HOME="nrtests"


echo INFO: Staging files for regression testing

# check that env variables are set
REQUIRED_VARS=("PROJECT" "BUILD_HOME" "PLATFORM")
for i in ${REQUIRED_VARS[@]}; do
    if [ -z ${!i} ]; then
      echo "ERROR: $i must be defined"; exit 1;
    fi
done
echo "CHECK: all required variables are set"


# determine project directories
CURRENT_DIR=${PWD}
SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd ${SCRIPT_HOME}
cd ../../
PROJECT_DIR=${PWD}


# create a clean directory for staging regression tests
if [ -d ${TEST_HOME} ]; then
  rm -rf ${TEST_HOME}
fi

mkdir ${TEST_HOME}
cd ${TEST_HOME}
mkdir benchmark


# use the shell var NRTEST_URL or if not set revert to default provided
NRTESTS_URL=${NRTESTS_URL:="https://github.com/pyswmm/${PROJECT}-nrtestsuite"}
echo CHECK: using NRTESTS_URL = ${NRTESTS_URL}


# use passed arg else determine latest when available
if [ -n "$1" ]; then
    RELEASE_TAG=$1
else
    RELEASE_TAG=$( basename $( curl -Ls -o /dev/null -w %{url_effective} "${NRTESTS_URL}/releases/latest" ) )
fi

# perform release tag check
if [ -z ${RELEASE_TAG} ]; then
    echo "ERROR: relase tag must be defined" ; exit 1
fi
echo CHECK: using RELEASE_TAG = ${RELEASE_TAG}


# build URLs for test and benchmark files
TESTFILES_URL="${NRTESTS_URL}/archive/${RELEASE_TAG}.tar.gz"
BENCHFILES_URL="${NRTESTS_URL}/releases/download/${RELEASE_TAG}/benchmark-${PLATFORM}.tar.gz"

# retrieve swmm-examples for regression testing tar.gz
echo CHECK: using TESTFILES_URL = ${TESTFILES_URL}
curl -fsSL -o nrtestfiles.tar.gz ${TESTFILES_URL}
if [ $? -ne 0 ]; then
    exit 1;
fi

# retrieve swmm benchmark results
echo CHECK: using BENCHFILES_URL = ${BENCHFILES_URL}
curl -fsSL -o benchmark.tar.gz ${BENCHFILES_URL}
if [ $? -ne 0 ]; then
    exit 1;
fi


# extract tests and benchmarks
if [ -f nrtestfiles.tar.gz ]; then
    tar xzf nrtestfiles.tar.gz
else
    echo "ERROR: file nrtestfiles.tar.gz does not exist"; exit 1
fi

# create benchmark dir and extract benchmarks
if [ -f benchmark.tar.gz ]; then
    tar xzf benchmark.tar.gz -C benchmark
else
    echo "ERROR: file benchmark.tar.gz does not exist"; exit 1
fi


# set up link to tests
ln -s ${PROJECT}-nrtestsuite-${RELEASE_TAG:1}/public tests


# determine ref_build_id
MANIFEST_FILE=$( find . -name manifest.json )
while read line; do
  if [[ $line == *"${PLATFORM} "* ]]; then
    REF_BUILD_ID=${line#*"${PLATFORM} "}
    REF_BUILD_ID=${REF_BUILD_ID//"\","/""}
  fi
done < $MANIFEST_FILE


if [ -z "${REF_BUILD_ID}" ]; then
    echo "ERROR: REF_BUILD_ID could not be determined" ; exit 1
fi
echo "CHECK: using REF_BUILD_ID = $REF_BUILD_ID"


export REF_BUILD_ID=$REF_BUILD_ID

# GitHub Actions
echo "REF_BUILD_ID=$REF_BUILD_ID" >> $GITHUB_ENV


# return user to current dir
cd ${CURRENT_DIR}
