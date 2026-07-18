#!/bin/sh

SCRIPT_DIRECTORY="$(dirname "$(realpath "$0")")"
. ${SCRIPT_DIRECTORY}/includes/helper_find_llvm_install.sh

CHERIOT_OBJCOPY_PATH=$(find_tool_required llvm-objcopy)

echo Using ${CHERIOT_OBJCOPY_PATH}...

# Create the firmware directory if it does not already exist
if [ ! -d "firmware" ]; then
	mkdir firmware
fi

# Convert the ELF file to a hex file for the simulator
${CHERIOT_OBJCOPY_PATH} -O binary $1 - | hexdump -v -e '"%08X" "\n"' > firmware/cpu0_iram.vhx
# Add a newline at the end of the vhx file
echo >> firmware/cpu0_iram.vhx

# Do the same thing for machines w/ 64-bit memories
${CHERIOT_OBJCOPY_PATH} -O binary $1 - | hexdump -v -e '1/8 "%016X" "\n"' > firmware/cpu0_iram64.vhx
echo >> firmware/cpu0_iram64.vhx
