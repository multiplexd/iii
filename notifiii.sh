#!/usr/bin/env sh
# Ivan c00kiemon5ter V Kanakarakis (http://c00kiemon5ter.github.com)
# for noncopyright information see UNLICENSE file http://unlicense.org/ .
#
# monitor the given irc directory tree for changes - ignores server messages
# and spawns tmiii.sh or a new urxvt terminal with the chanel that had activity

i="${1:-$HOME/irc}"
h="${h:-50}"
GREP_OPTIONS=""

trap 'kill -TERM -0' EXIT

inotifywait -m --exclude "/in$" --format "%w %f" -e modify -r "$i" | \
	while read -r p f; do
		# ignore notifications files other than 'out'
		[ "$f" != "out" ] && continue

		# ignore messages from server
		nickname="$(awk '{ n=$3 } END { print n }' "$p$f")"
		nickname="${nickname#<}"
		nickname="${nickname%>}"
		case "$nickname" in -!-) continue ;; esac

		# break path down # p=/ircdir/server/channel/
		p="${p#$i}"       # p=/server/channel/
		p="${p%/*}"       # p=/server/channel
		c="${p##*/}"      # c=channel
		p="${p%/*}"       # p=/server
		s="${p##*/}"      # s=server
		# if server is empty then action is on the server view
		[ -z "$s" ] && s="$c" c=""

		opts="h="$h" i="$i" s="$s" c="$c""

		[ -f "$i/$s/nick" ] && [ -r "$i/$s/nick" ] && n=$(cat "$i/$s/nick") && opts="$opts n=$n"

		# check for a highlight list, first server specific and then channel specific
		[ -f "$i/$s/highlight" -a -r "$i/$s/highlight" ] && l="$i/$s/highlight"
		[ -f "$i/$s/$c/highlight" -a -r "$i/$s/$c/highlight" ] && l="$i/$s/$c/highlight"
		[ -n "$l" ] && opts="$opts l=$l"

		## spawn a new tmux window named <channel> in a tmux session named IRC-${server}
		env $opts tmiii.sh

		# ## spawn a new urxvt terminal with IRC-<channel> class name
		# if ! xwininfo -root -children | sed -n 's,^ \+\(0x[^ ]\+\).*("\([^"]*\)" "\([^"]*\)").*\+,"\1 \2 \3",p' | grep "${c:-$s} URxvt"
		# then env $opts urxvtc -name "IRC-${c:-$s}" -e iii.sh
		# fi
	done

