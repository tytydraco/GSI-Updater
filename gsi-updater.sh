#!/system/bin/sh

# Tune these according to your preferences
branch="android-9.0"
user="tytydraco"
fork="device_phh_treble"
raw="https://raw.githubusercontent.com/$user/$fork/$branch"
gapps="gapps"	# Optional: gapps, gapps-go

# Setting this to "/" will actually write to the system.
# Setting this to "./" will write to a local directory
p="/"

get_from_tree() {
	echo "$(wget -q --no-check-certificate -O- $raw/$1 \
		| grep -o 'device/phh/treble/.*:system.*' | sed 's/device\/phh\/treble\///' \
		| sed 's/\\//')"
}

update_from_tree() {
	in=$(get_from_tree "$1")
	[ -z "$in" ] && return

	while read -r line; do
		lh="$(echo "$line" | sed 's/:.*//')"
		rh="$(echo "$line" | sed 's/.*://')"
		echo $lh \> $p$rh
		mkdir -p "$(dirname $rh)"
		wget -q --no-check-certificate -O- $raw/$lh > $p$rh
	done <<< "$in"
}

echo "Pulling from these parameters:"
echo "USER: $user"
echo "FORK: $fork"
echo "BRANCH: $branch"
echo "GAPPS: $gapps"

echo "Mounting /system as rw..."
mount -o rw,remount /system

update_from_tree "base.mk"
[ ! -z "$gapps" ] && update_from_tree "$gapps.mk"

echo "Mounting /system as ro..."
mount -o ro,remount /system

echo "Refreshing rw-system.sh..."
./system/bin/rw-system.sh
