#!/system/bin/sh

# Tune these according to your preferences
gapps="gapps"	# Optional: gapps, gapps-go

# Parameters for the device tree repo
dt_branch="android-9.0"
dt_user="phhusson"
dt_fork="device_phh_treble"
dt_raw="https://raw.githubusercontent.com/$dt_user/$dt_fork/$dt_branch"

# Parameters for the hardware overlay repo
hw_overlay_branch="master"
hw_overlay_user="phhusson"
hw_overlay_fork="vendor_hardware_overlay"
hw_overlay_raw="https://raw.githubusercontent.com/$hw_overlay_user/$hw_overlay_fork/$hw_overlay_branch"

get_dt_from_tree() {
	echo "$(wget -q --no-check-certificate -O- $dt_raw/$1 \
		| grep -o 'device/phh/treble/.*:system.*' | sed 's/device\/phh\/treble\///' \
		| sed 's/\\//')"
}

get_hw_overlay_from_tree() {
	echo "$(wget -q --no-check-certificate -O- $hw_overlay_raw/$1 \
		| grep -o 'vendor/hardware_overlay/.*:system.*' | sed 's/vendor\/hardware_overlay\///' \
		| sed 's/\\//')"
}

write_files() {
	[ ! -z "$1" ] && while read -r line; do
		lh="$(echo "$line" | sed 's/:.*//')"
		rh="$(echo "$line" | sed 's/.*://')"
		echo $lh \> $system/$rh
		mkdir -p "$(dirname /$rh)"
		type=$(echo $lhs | sed 's/\/.*//')
		[ "$2" = "device" ] && current_raw=$dt_raw
		[ "$2" = "vendor" ] && current_raw=$hw_overlay_raw
		wget -q --no-check-certificate -O- $current_raw/$lh > /$rh
	done <<< "$1"
}

mount_system() {
	mount -o $1,remount /system
}

# Fetch files from the specified repos
dt_files="$(get_dt_from_tree "base.mk")"
gapps_files="$(get_dt_from_tree $gapps.mk)"
hw_overlay_files="$(get_hw_overlay_from_tree "overlay.mk")"

# Pull and write files to system
mount_system rw
write_files "$dt_files" "device"
write_files "$gapps_files" "device"
write_files "$hw_overlay_files" "vendor"
mount_system ro

# Update changes using rw-system
/system/bin/rw-system.sh
