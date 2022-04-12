#!/usr/bin/env zsh

#
#  run-nrtests.zsh - Runs numerical regression test
#
#  Date Created: 04/01/2020
#       Updated: 08/21/2020
#
#  Author:       See AUTHORS
#
#  Dependencies:
#    python -m pip install -r requirements.txt
#
#  Environment Variables:
#    PROJECT
#    BUILD_HOME - relative path
#    TEST_HOME  - relative path
#    PLATFORM
#    REF_BUILD_ID
#
#  Arguments:
#    2 - (SUT_BUILD_ID) - optional argument
#


# check that env variables are set
REQUIRED_VARS=(PROJECT BUILD_HOME TEST_HOME PLATFORM REF_BUILD_ID)
for i in ${REQUIRED_VARS}; do
    [[ ! -v ${i} ]] && { echo "ERROR: ${i} must be defined"; return 1 }
done


# determine project root directory
CUR_DIR=${PWD}
SCRIPT_HOME=${0:a:h}
cd ${SCRIPT_HOME}/../../
PROJ_DIR=${PWD}


# change current directory to test suite
cd ${TEST_HOME}


# use passed argument or generate a "unique" identifier
if [ ! -z "$1" ]; then
    SUT_BUILD_ID=$1
else
    SUT_BUILD_ID=$RANDOM
fi

# check if app config file exists
if [ ! -a "./apps/${PROJECT}-${SUT_BUILD_ID}.json" ]; then
    mkdir -p "apps"
    ${SCRIPT_HOME}/app-config.zsh "${PROJ_DIR}/${BUILD_HOME}/bin/Release" \
    ${PLATFORM} ${SUT_BUILD_ID} > "./apps/${PROJECT}-${SUT_BUILD_ID}.json"
fi

# build list of directories contaiing tests
TESTS=$( find ./tests -mindepth 1 -type d -follow | paste -sd " " - )

# build nrtest execute command
NRTEST_EXECUTE_CMD='nrtest execute'
TEST_APP_PATH="./apps/${PROJECT}-${SUT_BUILD_ID}.json"
TEST_OUTPUT_PATH="./benchmark/${PROJECT}-${SUT_BUILD_ID}"

# build nrtest compare command
NRTEST_COMPARE_CMD='nrtest compare'
REF_OUTPUT_PATH="benchmark/${PROJECT}-${REF_BUILD_ID}"
RTOL_VALUE='0.01'
ATOL_VALUE='1.E-6'


# if present clean test benchmark results
if [ -d "${TEST_OUTPUT_PATH}" ]; then
    rm -rf "${TEST_OUTPUT_PATH}"
fi

# perform nrtest execute
echo "INFO: Creating SUT ${SUT_BUILD_ID} artifacts"
NRTEST_COMMAND="${NRTEST_EXECUTE_CMD} ${TEST_APP_PATH} ${TESTS} -o ${TEST_OUTPUT_PATH}"
echo $NRTEST_COMMAND
eval ${NRTEST_COMMAND}
RESULT=$?

if [ "$RESULT" -ne 0 ]; then
    echo "WARNING: nrtest execute exited with errors"
fi

# perform nrtest compare
if [ -z "${REF_BUILD_ID}" ]; then
    echo "WARNING: no ref benchmark found comparison not performed"
    RESULT=1
else
    echo "INFO: Comparing SUT artifacts to REF ${REF_BUILD_ID}"
    NRTEST_COMMAND="${NRTEST_COMPARE_CMD} ${TEST_OUTPUT_PATH} ${REF_OUTPUT_PATH} --rtol ${RTOL_VALUE} --atol ${ATOL_VALUE}"
    eval ${NRTEST_COMMAND}
    RESULT=$?
fi

# Stage artifacts for upload
cd ./benchmark

if [ "$RESULT" -eq 0 ]; then
    echo "INFO: nrtest compare exited successfully"
    mv receipt.json ${PROJ_DIR}/upload/receipt.json
else
    echo "INFO: nrtest exited abnormally"
    tar -zcf benchmark-${PLATFORM}.tar.gz ./${PROJECT}-${SUT_BUILD_ID}
    mv benchmark-${PLATFORM}.tar.gz ${PROJ_DIR}/upload/benchmark-${PLATFORM}.tar.gz
fi

# return user to current dir
cd ${CUR_DIR}

return $RESULT
