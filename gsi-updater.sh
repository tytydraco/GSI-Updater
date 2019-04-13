#!/system/bin/sh

# Tune these according to your preferences
test_mode=true

dt_branch="android-9.0"
dt_user="phhusson"
dt_fork="device_phh_treble"
dt_raw="https://raw.githubusercontent.com/$dt_user/$dt_fork/$dt_branch"

hw_overlay_branch="master"
hw_overlay_user="phhusson"
hw_overlay_fork="vendor_hardware_overlay"
hw_overlay_raw="https://raw.githubusercontent.com/$hw_overlay_user/$hw_overlay_fork/$hw_overlay_branch"

gapps="gapps"	# Optional: gapps, gapps-go

if [ "$test_mode" = "true" ]; then
	system="./system"
else
	system="/system"
fi

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

update_from_tree() {
	[ -z "$1" ] && return

	while read -r line; do
		lh="$(echo "$line" | sed 's/:.*//')"
		rh="$(echo "$line" | sed 's/.*://')"
		echo $lh \> $system/$rh
		mkdir -p "$(dirname $system/$rh)"
		wget -q --no-check-certificate -O- $current_raw/$lh > $system/$rh
	done <<< "$1"
}

mount -o rw,remount /system

current_raw="$dt_raw"
update_from_tree "$(get_dt_from_tree "base.mk")"
[ ! -z "$gapps" ] && update_from_tree "$(get_dt_from_tree $gapps.mk)"

current_raw="$hw_overlay_raw"
update_from_tree "$(get_hw_overlay_from_tree "overlay.mk")"

mount -o ro,remount /system

/system/bin/rw-system.sh
