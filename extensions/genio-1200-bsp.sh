#
# SPDX-License-Identifier: GPL-2.0
# Armbian build framework extension
#
# Adds Mediatek Genio BSP support with Mali GPU drivers
#

function extension_prepare_config__genio() {
	# Only apply for jammy
	[[ "${RELEASE}" != "jammy" ]] && return 0

	# Deny on minimal CLI images
	if [[ "${BUILD_MINIMAL}" == "yes" ]]; then
		display_alert "Extension: ${EXTENSION}" "skip installation in minimal images" "warn"
		return 0
	fi

	# Add image suffix to indicate Genio BSP support
	EXTRA_IMAGE_SUFFIXES+=("-genio-bsp")
}

function post_install_kernel_debs__genio() {
	# Only apply for jammy
	[[ "${RELEASE}" != "jammy" ]] && return 0

	# Packages that are going to be installed, always, both for cli and desktop
	declare -a pkgs=("mediatek-apusys-firmware-genio1200" "mediatek-vpud-genio1200")

	# Add Mediatek Genio PPA
	display_alert "Adding Mediatek Genio Public PPA" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard add-apt-repository ppa:mediatek-genio/genio-public --yes --no-update

	# Pin Mediatek Genio PPA
	display_alert "Pinning Mediatek Genio Public PPA" "${EXTENSION}" "info"
	cat <<- EOF > "${SDCARD}"/etc/apt/preferences.d/mediatek-genio-public-pin
		Package: *
		Pin: release o=LP-PPA-mediatek-genio-genio-public
		Pin-Priority: 1001
	EOF

	# Add Canonical HW enablement Repository
	display_alert "Adding Canonical HW enablement Repository" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard add-apt-repository -s "deb http://oem.archive.canonical.com/ jammy-baoshan public" --yes --no-update
	# Add Canonical HW enablement Repository key
	do_with_retries 3 chroot_sdcard apt-key adv --recv-keys --keyserver keyserver.ubuntu.com F9FDA6BED73CDC22
	#Pin libmali-mtk-8195
	display_alert "Pinning Canonical HW enablement Repository" "${EXTENSION}" "info"
	cat <<- EOF > "${SDCARD}"/etc/apt/preferences.d/oem-archive-jammy-baoshan-pin
		Package: libmali-mtk-8195
		Pin: release o=oem.archive.canonical.com
		Pin-Priority: 1001
	EOF

	display_alert "Updating sources list, after adding all PPAs" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Installing Genio BSP packages" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install "libmali-mtk-8195"
	do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"

	display_alert "Upgrading all packages" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get -o Dpkg::Options::="--force-confold" --allow-downgrades dist-upgrade

	return 0
}
