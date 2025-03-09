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

	# Deny on minimal CLI images
	if [[ "${BUILD_MINIMAL}" == "yes" ]]; then
		display_alert "Extension: ${EXTENSION}" "skip installation in minimal images" "warn"
		return 0
	fi

	# Packages that are going to be installed, always, both for cli and desktop
	declare -a pkgs=("oem-baoshan-genio-desktop-meta mediatek-vpud-genio1200 mediatek-apusys-firmware-genio1200")

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

	# Add MTK Mali PPA
	display_alert "Adding MTK Mali PPA" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard add-apt-repository ppa:asaly12/mtk-mali --yes --no-update

	# Pin MTK Mali PPA
	display_alert "Pinning MTK Mali PPA" "${EXTENSION}" "info"
	cat <<- EOF > "${SDCARD}"/etc/apt/preferences.d/asaly12-mtk-mali-pin
		Package: *
		Pin: release o=LP-PPA-asaly12-mtk-mali
		Pin-Priority: 1001
	EOF

	display_alert "Updating sources list, after adding all PPAs" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Pulling specific Mali package version" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard pull-ppa-debs libmali-mtk=43p0+d1985cb-0ubuntu7 ppa:asaly12/mtk-mali && sudo dpkg -i libmali-mtk_43p0*.deb

	display_alert "Installing and holding Mali package" "${EXTENSION}" "info"
	chroot_sdcard apt-mark hold libmali-mtk

	display_alert "Installing Genio BSP packages" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"

	display_alert "Upgrading all packages" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get -o Dpkg::Options::="--force-confold" --allow-downgrades dist-upgrade

	return 0
}
