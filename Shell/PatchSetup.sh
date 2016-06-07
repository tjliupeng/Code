#!/bin/sh
SERVER_DIR=`dirname $0`
SERVER_DIR=`(cd "${SERVER_DIR}";pwd)`
SERVER_MIN_VERSION="9.40"
SCRIPT_NAME=`basename $0`
getDirectory_RET=""
SMVERSION_PATCH=""

checkPathExist()
{
    if [ ! -e "$1" ]; then
	echo "Path $1 doesn't exist."
	cd "${SERVER_DIR}"
	exit 1
    fi
}

checkDirectoryExist()
{
    if [ ! -d "$1" ]; then
	echo "Directory $1 doesn't exist."
	cd "${SERVER_DIR}"
	exit 1
    fi
}

checkFileExist()
{
    if [ ! -f "$1" ]; then
	echo "File $1 doesn't exist."
	cd "${SERVER_DIR}"
	exit 1
    fi
}

checkProcessRunning()
{
    local PROCESS_NUM=`ps -ef | grep "$1" | grep -v "grep" | wc -l`
	
    if [ "${PROCESS_NUM}" -gt 0 ]; then
	echo "$1 is still running, please stop it."
	cd "${SERVER_DIR}"
	exit 1
    fi
}

getDirectory()
{
    local READ_DIR
    read -p "$1" READ_DIR
	
    if [ -z "$READ_DIR" ]; then
	echo "$2"
	cd "${SERVER_DIR}"
	exit 1
    fi
    
    READ_DIR=${READ_DIR%/}

    checkDirectoryExist "$READ_DIR"
	
    READ_DIR=`(cd "${READ_DIR}" ; pwd)`
	
    getDirectory_RET="${READ_DIR}"
}

getSMVersion()
{
    cd "$1"

    checkFileExist "./sm"
	
    ./sm -version > ./smversion.txt

    if [ ! -e "./smversion.txt" ]; then
	echo "Failed to Service Manager Server version information."
	cd "${SERVER_DIR}"
	exit 1
    fi

    local SMVERSION=`awk '/Version:/  { print $2; }' ./smversion.txt`
    local SMPATCH=`awk '/Patch Level:/  { print $3; }' ./smversion.txt`

    if [ ! -z "${SMPATCH}" ]; then
	SMVERSION="${SMVERSION}-${SMPATCH}"
    fi

    if [ -z "${SMVERSION}" ]; then
	echo "No sm version!"
	rm -f ./smversion.txt
	cd "${SERVER_DIR}"
	exit 1
    fi

    echo "The current SM Server is ${SMVERSION}."

    rm -f ./smversion.txt

    SMVERSION_PATCH="${SMVERSION}"
}

deleteFolder()
{
    rm -fr "$1" | tee -a "$2"
    
    if [ -d "$1" ]; then
	echo ""
	echo "$3"
	cd "${SERVER_DIR}"
	exit 1
    fi
}

echo ""
echo "Hewlett Packard Enterprise Software..."
echo "echo Begin to setup Service Manager Server Patch..."
echo "Some configuration files (such as lwssofmconf.xml and udp.xml) will be overwritten by files from the patch. If you have made any changes to these files, remember to update the new versions accordingly after the patch setup process is completed."
echo ""
echo ""

checkProcessRunning "scenter"

checkProcessRunning "smserver"

getDirectory "Full path of current SM Server installation directory:" "Failed to provide the current SM Server installation directory."

SMINSTALL_DIR="${getDirectory_RET}"

if [ "${SMINSTALL_DIR}" == "${SERVER_DIR}" ]; then
    echo "Current SM Server installation directory could not be the patch setup working directory."
    cd "${SERVER_DIR}"
    exit 1
fi

test -w "${SMINSTALL_DIR}"

if [ $? -ne 0 ]; then
    echo "${SMINSTALL_DIR} is not writable."
    cd "${SERVER_DIR}"
    exit 1
fi

SMINSTALL_RUN_DIR="${SMINSTALL_DIR}/RUN"

checkDirectoryExist "${SMINSTALL_RUN_DIR}"

echo ""

getDirectory "Full path of SM Server backup directory:" "Please provide full path of SM Server backup directory."

SMBACKUP_DIR="${getDirectory_RET}"

if [[  "${SMBACKUP_DIR}" == "${SMINSTALL_DIR}"* ]]; then
    echo "The backup directory could not be the subdirectory of SM Server installation directory."
    cd "${SERVER_DIR}"
    exit 1
fi

if [[  "${SMBACKUP_DIR}" == "${SERVER_DIR}"* ]]; then
    echo "The backup directory could not be the subdirectory of patch setup working directory."
    cd "${SERVER_DIR}"
    exit 1
fi

test -w "${SMBACKUP_DIR}"

if [ $? -ne 0 ]; then
    echo "${SMBACKUP_DIR} is not writable."
    cd "${SERVER_DIR}"
    exit 1
fi

echo ""

getSMVersion "${SMINSTALL_RUN_DIR}"

if [ "${SMVERSION_PATCH}" \< "${SERVER_MIN_VERSION}" ]; then
	echo "Current SM Server is ${SMVERSION_PATCH}, can not apply ${SERVER_MIN_VERSION} patch."
	cd "${SERVER_DIR}"
	exit 1
fi

SMPATCHSETUP_LOG_FILE="${SERVER_DIR}/PatchSetup.log"

> "${SMPATCHSETUP_LOG_FILE}"

echo ""
echo "The setup process may take several minutes..."
echo ""
echo "Backing up the current SM Server to ${SMBACKUP_DIR}/${SMVERSION_PATCH}..." | tee -a "${SMPATCHSETUP_LOG_FILE}"

if [ ! -d "${SMBACKUP_DIR}/${SMVERSION_PATCH}" ]; then
    mkdir "${SMBACKUP_DIR}/${SMVERSION_PATCH}"

    if [ $? -ne 0 ]; then
	echo "Fail to create ${SMBACKUP_DIR}/${SMVERSION_PATCH}."
	cd "${SERVER_DIR}"
	exit 1
    fi
fi

set -o pipefail

cd "${SMINSTALL_DIR}"

cp -R $(ls | grep -v '^_jvm\|^_uninstall\|logs\|.log$') -v "${SMBACKUP_DIR}/${SMVERSION_PATCH}"  2>&1 | tee -a "${SMPATCHSETUP_LOG_FILE}"

if [ $? -ne 0 ]; then
    echo ""
    echo "Failed to back up SM Server. Please check the error information in the log file ${SMPATCHSETUP_LOG_FILE}."
    exit 1
fi

if [ -e "${SMBACKUP_DIR}/${SMVERSION_PATCH}/RUN/scemail.chk" ]; then
    rm -f "${SMBACKUP_DIR}/${SMVERSION_PATCH}/RUN/scemail.chk"
fi

> "${SMBACKUP_DIR}/${SMVERSION_PATCH}/SMPatchDiff"

echo ""
echo "Applying the SM Server Patch..." | tee -a "${SMPATCHSETUP_LOG_FILE}"

MSG_APPLY_ERROR="Failed to apply the SM Server upgrade. Please check the ${SMPATCHSETUP_LOG_FILE} log file for error information. This failure may prevent the SM Server from starting. Please retry the upgrade process to ensure a successful setup. "

deleteFolder "${SMINSTALL_RUN_DIR}/jre" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_APPLY_ERROR}"
deleteFolder "${SMINSTALL_RUN_DIR}/lib" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_APPLY_ERROR}"
deleteFolder "${SMINSTALL_RUN_DIR}/tomcat" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_APPLY_ERROR}"

cd "${SERVER_DIR}"

cp -R $(ls | grep -v '${SCRIPT_NAME}\|^PatchSetup.log$') -v "${SMINSTALL_DIR}"  2>&1 | tee -a "${SMPATCHSETUP_LOG_FILE}"

if [ $? -ne 0 ]; then
    echo ""
    echo "${MSG_APPLY_ERROR}"
    exit 1
fi

if [ -e "./PatchUninstall.sh" ]; then
    cp "./PatchUninstall.sh" "${SMINSTALL_DIR}/_uninstall"
fi

echo "" 

getSMVersion "${SMINSTALL_RUN_DIR}"

echo ""

echo "Finished applying the SM Server Patch." | tee -a "${SMPATCHSETUP_LOG_FILE}"

mv "${SMPATCHSETUP_LOG_FILE}" "${SMINSTALL_DIR}/"

echo ""

echo "Remember to update the configuration files if necessary. You can get the backup copy from ${SMBACKUP_DIR}/${SMVERSION_PATCH}."
