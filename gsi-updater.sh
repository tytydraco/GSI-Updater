#!/system/bin/sh

# Tune these according to your preferences
dt_branch="android-9.0"
dt_user="phhusson"
dt_fork="device_phh_treble"
dt_raw="https://raw.githubusercontent.com/$dt_user/$dt_fork/$dt_branch"

hw_overlay_branch="master"
hw_overlay_user="phhusson"
hw_overlay_fork="vendor_hardware_overlay"
hw_overlay_raw="https://raw.githubusercontent.com/$hw_overlay_user/$hw_overlay_fork/$hw_overlay_branch"

gapps="gapps"	# Optional: gapps, gapps-go

# Setting this to "/" will actually write to the system.
# Setting this to "./" will write to a local directory
p="/"

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
		echo $lh \> $p$rh
		mkdir -p "$(dirname $p$rh)"
		wget -q --no-check-certificate -O- $current_raw/$lh > $p$rh
	done <<< "$1"
}

echo "Pulling from these parameters:"
echo "DT USER: $dt_user"
echo "DT FORK: $dt_fork"
echo "DT BRANCH: $dt_branch"
echo "HW OVERLAY USER: $hw_overlay_user"
echo "HW OVERLAY FORK: $hw_overlay_fork"
echo "HW OVERLAY BRANCH: $hw_overlay_branch"
echo "GAPPS: $gapps"

echo "Mounting /system as rw..."
mount -o rw,remount /system

current_raw="$dt_raw"
update_from_tree "$(get_dt_from_tree "base.mk")"
[ ! -z "$gapps" ] && update_from_tree "$(get_dt_from_tree $gapps.mk)"

current_raw="$hw_overlay_raw"
update_from_tree "$(get_hw_overlay_from_tree "overlay.mk")"

echo "Mounting /system as ro..."
mount -o ro,remount /system

echo "Refreshing rw-system.sh..."
/system/bin/rw-system.sh
