#!/bin/sh
WORKING_DIR=`dirname $0`
WORKING_DIR=`(cd "${WORKING_DIR}";pwd)`
SERVER_DIR=`(cd "${WORKING_DIR}/..";pwd)`
SCRIPT_NAME=`basename $0`
getDirectory_RET=""
SMVERSION_PATCH=""
declare -a EXISTINGVERSION
VERSIONCNT=0
SELECTED_VERSION=""
SMPATCHSETUP_LOG_FILE=""

checkPathExist()
{
    if [ ! -e "$1" ]; then
        echo "Path $1 doesn't exist."
        cd "${WORKING_DIR}"
        exit 1
    fi
}

checkDirectoryExist()
{
    if [ ! -d "$1" ]; then
        echo "Directory $1 doesn't exist."
        cd "${WORKING_DIR}"
        exit 1
    fi
}

checkFileExist()
{
    if [ ! -f "$1" ]; then
        echo "File $1 doesn't exist."
        cd "${WORKING_DIR}"
        exit 1
    fi
}

checkProcessRunning()
{
    local PROCESS_NUM=`ps -ef | grep "$1" | grep -v "grep" | wc -l`
	
    if [ "${PROCESS_NUM}" -gt 0 ]; then
        echo "$1 is still running, please stop it."
        cd "${WORKING_DIR}"
        exit 1
    fi
}

getDirectory()
{
    local READ_DIR
    read -p "$1" READ_DIR
	
    if [ -z "$READ_DIR" ]; then
        echo "$2"
        cd "${WORKING_DIR}"
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
        cd "${WORKING_DIR}"
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
        cd "${WORKING_DIR}"
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
        cd "${WORKING_DIR}"
	    exit 1
    fi
}

getExistingSMVersion()
{
    find "$1" -mindepth 1 -maxdepth 1 -type d > "./versions.txt"

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ -e "$line/SMPatchDiff" ]; then
            EXISTINGVERSION[$VERSIONCNT]="$line"
            VERSIONCNT=$(( $VERSIONCNT + 1 ))
	fi
    done < "./versions.txt"
	
    if [ ${VERSIONCNT} -eq 0 ]; then
        echo ""
        echo "No backup version in $1"
        rm -f ./versions.txt
        cd "${WORKING_DIR}"
	exit 1
    fi
    echo ""
    echo "Existing backup versions of the SM Server:"
    for index in ${!EXISTINGVERSION[*]}
    do
	PRINTED_INDEX=$(( $index+1 ))
	SELECTED_BASE=`basename ${EXISTINGVERSION[$index]}`
        printf "%2d. %s\n" ${PRINTED_INDEX} ${SELECTED_BASE}
    done
    rm -f ./versions.txt
}

getSelectedSMVersion()
{
    echo ""
    read -p "Select the version you want to restore:" SELECTED_INDEX

    if [ -z "$SELECTED_INDEX" ]; then
        echo ""
        echo "Please select the restore version."
        cd "${WORKING_DIR}"
        exit 1
    fi
	
    if ! [[ $SELECTED_INDEX =~ ^-?[0-9]+$ ]]; then
        echo ""
        echo "Invalid restore option."
        cd "${WORKING_DIR}"
        exit 1
    else
        MAXCNT=$((${VERSIONCNT}+1))
        if [[ $SELECTED_INDEX -lt 1 ||  $SELECTED_INDEX -gt $VERSIONCNT ]]; then
            echo ""
            echo "Invalid restore option. The option is out of range."
            cd "${WORKING_DIR}"
            exit 1
        fi
	SELECTED_INDEX=$(( $SELECTED_INDEX - 1 ))
        SELECTED_VERSION="${EXISTINGVERSION[$SELECTED_INDEX]}"
    fi
}

echo ""
echo "Hewlett Packard Enterprise Software..."
echo "Begin to uninstall Service Manager Server Patch..."
echo "Some configuration files (such as lwssofmconf.xml and udp.xml) will be overwritten by files from the prior patch. If you have made any changes to these files, remember to update the new versions accordingly after the patch uninstall process is completed.
echo."

echo ""

echo ""

checkProcessRunning "scenter"

checkProcessRunning "smserver"

SMINSTALL_DIR="${SERVER_DIR}"

SMINSTALL_RUN_DIR="${SMINSTALL_DIR}/RUN"

checkDirectoryExist "${SMINSTALL_RUN_DIR}"

getDirectory "Full path of SM Server backup directory:" "Please provide full path of SM Server backup directory."

SMBACKUP_DIR="${getDirectory_RET}"

if [ "${SMBACKUP_DIR}" == "${SMINSTALL_DIR}" ]; then
    echo "The backup directory could not be the same as current SM Server installation directory."
    cd "${WORKING_DIR}"
    exit 1
fi

if [[  "${SMBACKUP_DIR}" == "${SMINSTALL_DIR}"* ]]; then
    echo "The backup directory could not be the subdirectory of current SM Server installation directory."
    cd "${WORKING_DIR}"
    exit 1
fi

echo ""

getSMVersion "${SMINSTALL_RUN_DIR}"

SMPATCHSETUP_LOG_FILE="${WORKING_DIR}/PatchUninstall.log"

getExistingSMVersion "${SMBACKUP_DIR}"

getSelectedSMVersion

> ${SMPATCHSETUP_LOG_FILE}

MSG_UNINSTALL_ERROR="Failed to restore the SM server. Please check the log file ${SMPATCHSETUP_LOG_FILE} for error information. This failure may prevent the SM server from starting. Please retry the restore process to ensure a successful uninstall."

echo ""

read -p "Are you sure you want to back out the SM Server and revert to the backup of version ${SELECTED_BASE}?(Y/N)" CONFIRM
	
case $CONFIRM in
    [yY])
        echo ""
        echo "The restore process may take several minutes..."
	echo ""
        echo "Remove platform_unloads, jre, lib and tomcat." | tee -a "${SMPATCHSETUP_LOG_FILE}"
	echo ""
	deleteFolder "${SMINSTALL_RUN_DIR}/platform_unloads" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_UNINSTALL_ERROR}"
        deleteFolder "${SMINSTALL_RUN_DIR}/jre" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_UNINSTALL_ERROR}"
        deleteFolder "${SMINSTALL_RUN_DIR}/lib" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_UNINSTALL_ERROR}"
        deleteFolder "${SMINSTALL_RUN_DIR}/tomcat" "${SMPATCHSETUP_LOG_FILE}"  "${MSG_UNINSTALL_ERROR}"
		
	echo "Restoring the SM Server..." | tee -a "${SMPATCHSETUP_LOG_FILE}"
		
        set -o pipefail

        cd "${SELECTED_VERSION}"
	cp -R $(ls | grep -v '${SCRIPT_NAME}\|^PatchSetup.sh$') -v "${SMINSTALL_DIR}"  2>&1 | tee -a "${SMPATCHSETUP_LOG_FILE}"

        if [ $? -ne 0 ]; then
            echo ""
            echo "${MSG_UNINSTALL_ERROR}"
            cd "${WORKING_DIR}"
            exit 1
        fi
        
        cd "${WORKING_DIR}"
		
        getSMVersion "${SMINSTALL_RUN_DIR}"
		
        rm -f "$SMINSTALL_DIR/SMPatchDiff"
        echo ""
        echo "Finished restoring the SM Server Patch."
		
    ;;
    [nN])
        echo ""
        echo "Backout cancelled."
        cd "${WORKING_DIR}"
        exit 1
    ;;
    *)
        echo ""
        echo "Invalid backout Option. Give up the backout."
        cd "${WORKING_DIR}"
        exit 1
    ;;
esac
