#!/bin/bash

directory="$(dirname $(realpath $0))"
source $directory/config.sh
last_id=0

send() {
	curl -s "$tele_url/sendMessage" \
		--data-urlencode "chat_id=$1" \
		--data-urlencode "reply_to_message_id=$2" \
		--data-urlencode "text=$3"
}

check_update() {
	updates="$(curl -s "$tele_url/getUpdates" --data-urlencode "offset=$(($last_id + 1))" --data-urlencode "timeout=5")"
	updates_count=$(echo "$updates" | jq -r ".result | length")
	last_id=$(echo "$updates" | jq -r ".result[$(( "$updates_count" - 1 ))].update_id")
}

parse_json() {
	chat_id="$(echo "$updates" | jq ".result[$i].message.chat.id")"
	message_text="$(echo "$updates" | jq ".result[$i].message.text")"
	message_id="$(echo "$updates" | jq ".result[$i].message.message_id")"
	reply_id="$(echo "$updates" | jq ".result[$i].message.reply_to_message.message_id")"
	from_id="$(echo "$updates" | jq ".result[$i].message.from.id")"
}

write_log() {
	date +%F-%T >> $directory/shell.log
	echo "$updates" | jq ".result[$i]" >> $directory/shell.log
}

bash_command() {
	matches=0
	for master_id in ${master_ids[*]}; do
		if [[ "$from_id" == "$master_id" ]]; then
			matches=$(($matches + 1))
		fi
	done
	if [[ $matches != 0 ]]; then
		send "$chat_id" "$message_id" "$(bash -c "$message_text 2>&1")"
	else
		echo "User $from_id not in master_ids list. Check your bot privacy settings."
	fi
}

while true; do
	ping -c1 $(echo "$tele_url" | cut -d '/' -f 3) 2>&1 > /dev/null && {
		check_update
		for ((i=0; i<"$updates_count"; i++)); do
			parse_json
			write_log
			if [[ $message_text == 'null' ]]; then
				echo "nothing to do"
			fi
			message_text="$(echo "$message_text" | sed --sandbox 's#\\"#"#g;s#\\\\#\\#g;s/^"//;s/"$//')"
			case $message_text in
				'ping'*)
					send "$chat_id" "$message_id" "pong"
				;;
				*)
					bash_command
				;;
			esac
		done
	}
done
