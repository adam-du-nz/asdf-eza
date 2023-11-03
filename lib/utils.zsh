#!/usr/bin/env zsh
set -euo pipefail

GH_REPO="https://github.com/eza-community/eza"
TOOL_NAME="eza"
TOOL_TEST="eza --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

download_path() {
	local version=$1
	local tmp_download_dir=$2

	echo "$tmp_download_dir/$TOOL_NAME-${version}.tar.gz"
}

download_url() {
	local install_type version architecture
	install_type=$1
	version_arg=$2
	if [[ "${version_arg}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
		version="v$2"
	else
		version="$2"
	fi

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

  case "$(uname -m | tr '[:upper:]' '[:lower:]')" in
    aarch64* | arm64) architecture="aarch64" ;;
    armv5* | armv6* | armv7*) architecture="arm" ;;
    x86_64*) architecture="x86_64" ;;
    *) fail "Unsupported architecture" ;;
  esac

	echo "$GH_REPO/releases/download/v${version}/${TOOL_NAME}_${architecture}-unknown-linux-gnu.tar.gz"

	return
}

download_version() {
	local install_type=$1
	local version=$2
	local download_path=$3
	local download_url

	download_url=$(download_url "$install_type" "$version")

	[ -f $download_path ] && rm "$download_path"

	echo "Downloading $download_url"
	curl "${curl_opts[@]}" -o "$download_path" -C - "$download_url" || fail "Could not download $download_url"
}

download_release() {
	local install_type=$1
	local version=$2
	local download_path=$3
	local tmp_download_dir
	local archive_path

	if [ "$TMPDIR" = "" ]; then
		tmp_download_dir=$(mktemp -d -t "${TOOL_NAME}_build_$version")
	else
		tmp_download_dir=$TMPDIR
	fi

	archive_path=$(download_path "$version" "$tmp_download_dir")
	download_version "$install_type" "$version" "$archive_path"

	# running this in subshell
	# we don't want to disturb current working dir
	(
		if ! type "tar" &>/dev/null; then
			echo "ERROR: tar not found"
			exit 1
		fi

		tar zxf "$archive_path" -C "$download_path" --strip-components=1 || fail "Could not extract $archive_path"
	)
}

install_version() {
	local install_type="$1"
	local download_path="$2"
	local install_path="$3"

	if [ -z "$download_path" ]; then
		#: We're on asdf 0.7.*
		download_path=$(mktemp -d -t "asdf-$TOOL_NAME-$install_type-$ASDF_INSTALL_VERSION-XXXX")
		ASDF_DOWNLOAD_PATH="$download_path"
		download_release "$ASDF_INSTALL_TYPE" "$ASDF_INSTALL_VERSION" "$ASDF_DOWNLOAD_PATH"
	fi

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi
	(
		# move the prebuilt artifact to the install path
		mv -f "$download_path"/** "$install_path"
		chmod +x "${install_path}/bin/${TOOL_NAME}"

		local tool_cmd
		# tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/bin/${TOOL_TEST}" || fail "Expected $install_path/bin/${TOOL_TEST} to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
