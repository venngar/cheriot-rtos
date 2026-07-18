# Constant: location of the custom tool binaries in the dev container
# DEV_CONTAINER_BIN="/cheriot-tools/bin/"

# Finds location of a given LLVM tool on the system.
#
# Argument 1: name of the LLVM tool to find (e.g.,
#             `llvm-objdump`, `llvm-objcopy`)
find_tool() {
	TOOL_NAME=$1
	if ! type ${TOOL_NAME} >/dev/null 2>&1 ; then
		FROM_DEV_CONTAINER="${CHERIOT_TOOLS_PATH}/${TOOL_NAME}"
		if [ -x "${FROM_DEV_CONTAINER}" ] ; then
			TOOL_NAME=${FROM_DEV_CONTAINER}
		else
			if [ -n "${CHERIOT_TOOLS_PATH}" ] ; then
				WITH_TOOLS_PATH_SET="${CHERIOT_TOOLS_PATH}/${TOOL_NAME}"
				if [ -x "${WITH_TOOLS_PATH_SET}" ] ; then
					TOOL_NAME=${WITH_TOOLS_PATH_SET}
				else 
					TOOL_NAME=${CHERIOT_TOOLS_PATH}
				fi
			fi
		fi
	fi
	echo "${TOOL_NAME}"
}

# Wrapper for `find_llvm_tool` that does `exit 1` with an error message if the
# tool cannot be found.
#
# Arguments are the same as `find_llvm_tool`.

find_tool_required() {
	TOOL_PATH=$(find_tool $1)

	if ! command -v ${TOOL_PATH} >/dev/null 2>&1 ; then
		echo WARNING: Unable to locate $1, environment variable is set to CHERIOT_TOOLS_PATH. >&2
	fi

	echo "${TOOL_PATH}"
}
