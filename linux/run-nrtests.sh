#! /bin/bash
#
#  run-nrtest.sh - Runs numerical regression test
#
#  Date Created: 11/15/2017
#
#  Author:       Michael E. Tryby
#                US EPA - ORD/NRMRL
#                
#                Caleb A. Buahin
#                Xylem Inc.
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
#    1 - (SUT_BUILD_ID) - optional argument

# check that env variables are set
REQUIRED_VARS=('PROJECT' 'BUILD_HOME' 'TEST_HOME' 'PLATFORM' 'REF_BUILD_ID')
for i in ${REQUIRED_VARS[@]}
do
    if [[ -z "${i}" ]]; then
      echo "ERROR: $i must be defined"; exit 1; 
    fi
done

# determine project root directory
SCRIPT_HOME=$(cd `dirname $0` && pwd)
cd ${SCRIPT_HOME}
cd ./../../
PROJ_DIR=${PWD}


# change current directory to test suite
cd ${PROJ_DIR}/${TEST_HOME}

# process optional arguments
if [ ! -z "$1" ]; then
    SUT_BUILD_ID=$1
else
    SUT_BUILD_ID="local"
fi

# check if app config file exists
if [[ ! -f "./apps/${PROJECT}-${SUT_BUILD_ID}.json" ]]
then
    mkdir -p "apps"
    ${SCRIPT_HOME}/app-config.sh "${PROJ_DIR}/${BUILD_HOME}/bin" \
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
eval ${NRTEST_COMMAND}



# perform nrtest compare
echo "INFO: Comparing SUT artifacts to REF ${REF_BUILD_ID}"
NRTEST_COMMAND="${NRTEST_COMPARE_CMD} ${TEST_OUTPUT_PATH} ${REF_OUTPUT_PATH} --rtol ${RTOL_VALUE} --atol ${ATOL_VALUE}"
eval ${NRTEST_COMMAND}

# Stage artifacts for upload
cd ./benchmark

if [ $? -eq 0 ]
then
    echo "INFO: nrtest compare exited successfully"
    mv receipt.json ${PROJ_DIR}/upload/receipt.json
else
    echo ERROR: nrtest exited with errors
    tar -zcvf benchmark-${PLATFORM}.tar.gz ./${PROJECT}-${SUT_BUILD_ID}
    mv benchmark-${PLATFORM}.tar.gz ${PROJ_DIR}/upload/benchmark-${PLATFORM}.tar.gz
fi

# return user to current dir
cd ${PROJ_DIR}

exit $?