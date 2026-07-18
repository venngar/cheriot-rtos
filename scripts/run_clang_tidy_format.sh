#!/usr/bin/env bash

SCRIPT_DIRECTORY="$(dirname "$(realpath "$0")")"
. ${SCRIPT_DIRECTORY}/includes/helper_find_llvm_install.sh

set -eo pipefail
if [ ! -d sdk ] ; then
	echo Please run this script from the root of the cheriot-rtos repository.
	exit 1
fi
CHERIOT_CLANG_TIDY_PATH=$(find_tool_required clang-tidy)
CHERIOT_CLANG_FORMAT_PATH=$(find_tool_required clang-format)

if [ -n "$1" ] ; then
	CHERIOT_CLANG_TIDY_PATH=$1/clang-tidy
	CHERIOT_CLANG_FORMAT_PATH=$1/clang-format
fi
if [ ! -x ${CHERIOT_CLANG_TIDY_PATH} ] ; then
	echo Usage: $0 path/to/cheriot/tools/bin
	echo clang-tidy not found at ${CHERIOT_CLANG_TIDY_PATH}
	exit 1
fi
if [ ! -x ${CHERIOT_CLANG_FORMAT_PATH} ] ; then
	echo Usage: $0 path/to/cheriot/tools/bin
	echo clang-format not found at ${CHERIOT_CLANG_FORMAT_PATH}
	exit 1
fi

PARALLEL_JOBS=$(nproc || sysctl -n kern.smp.cpus 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)
DIRECTORIES="sdk tests examples tests.extra benchmarks"
# Standard headers should be included once we move to a clang-tidy that
# supports NOLINTBEGIN to disable specific checks over a whole file.
# In particular, modernize-redundant-void-arg should be disabled in any header
# file that's included from C.
#
# FreeRTOS-Compat headers follow FreeRTOS naming conventions and should be
# excluded for now.  Eventually they should be included for everything except
# the identifier naming checks.
HEADERS=$(find ${DIRECTORIES} -name '*.h' -or -name '*.hh' | grep -v -f scripts/run_clang_tidy_format.exempt_headers)
SOURCES=$(find ${DIRECTORIES} -name '*.cc' | grep -v -f scripts/run_clang_tidy_format.exempt_sources)

echo Headers: ${HEADERS}
echo Sources: ${SOURCES}

${CHERIOT_CLANG_FORMAT_PATH} -i ${HEADERS} ${SOURCES}
if ! git diff --exit-code ${HEADERS} ${SOURCES} ; then
	echo clang-format applied changes
	exit 1
fi

rm -f tidy.fail-*
# sh syntax is -c "string" [name [args ...]], so "tidy" here is the name and not included in "$@"
echo ${HEADERS} ${SOURCES} | xargs -P${PARALLEL_JOBS} -n1 sh -c "${CHERIOT_CLANG_TIDY_PATH} --extra-arg=-DCLANG_TIDY -export-fixes=\$(mktemp -p. tidy.fail-XXXX) \$@" tidy
if [ $(find . -maxdepth 1 -name 'tidy.fail-*' -size +0 | wc -l) -gt 0 ] ; then
	# clang-tidy put non-empty output in one of the tidy-*.fail files
	cat tidy.fail-*
	exit 1
fi