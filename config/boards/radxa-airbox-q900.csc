# Qualcomm SA8775P
declare -g BOARD_NAME="Radxa Airbox Q900"
declare -g BOARD_VENDOR="radxa"
declare -g BOARD_MAINTAINER="HeyMeco"
declare -g BOARDFAMILY="sa8775p"
declare -g KERNEL_TARGET="current"
declare -g BOOTCONFIG="none"
declare -g IMAGE_PARTITION_TABLE="gpt"

declare -g BOARD_FIRMWARE_INSTALL="-full"

declare -g BOOT_FDT_FILE="qcom/lemans-radxa-airbox-q900.dtb"

enable_extension "grub-with-dtb"
