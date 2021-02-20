#!/bin/bash

directory="$(dirname $(realpath $0))"
source $directory/config.sh
tele_url="$api_url/bot$token"
last_id=0

send() {
	curl -s "$tele_url/sendMessage" \
		--data-urlencode "chat_id=$1" \
		--data-urlencode "reply_to_message_id=$2" \
		--data-urlencode "text=$3"
}

message_id() {
	echo "$updates" | jq ".result[$i].message.message_id"
}

user_id() {
	from_user_id="$(echo "$updates" | jq ".result[$i].message.from.id")"
}

reply_id() {
	reply_id="$(echo "$updates" | jq ".result[$i].message.reply_to_message.message_id")"
}

reply_text() {
	reply_text="$(echo "$updates" | jq ".result[$i].message.reply_to_message.text")"
	if [[ $reply_text == 'null' ]]; then
		reply_text="$(echo "$updates" | jq ".result[$i].message.reply_to_message.caption")"
	fi
	reply_text="$(echo "$reply_text" | sed --sandbox 's#\\"#"#g;s#\\\\#\\#g;s/^"//;s/"$//')"
}


while true; do
	ping -c1 $(echo "$tele_url" | cut -d '/' -f 3) 2>&1 > /dev/null && {
		updates=$(curl -s "$tele_url/getUpdates" \
			--data-urlencode "offset=$(( $last_id + 1 ))" \
			--data-urlencode "timeout=60")
		updates_count=$(echo "$updates" | jq -r ".result | length")
		last_id=$(echo "$updates" | jq -r ".result[$(( "$updates_count" - 1 ))].update_id")
		for ((i=0; i<"$updates_count"; i++)); do
			(
			date +%F-%T >> $directory/shell.log
			echo "$updates" | jq ".result[$i]" >> $directory/shell.log
			chat_id="$(echo "$updates" | jq ".result[$i].message.chat.id")"
			message_text="$(echo "$updates" | jq ".result[$i].message.text")"
			if [[ $message_text == 'null' ]]; then
				message_text="$(echo "$updates" | jq ".result[$i].message.caption")"
			fi
			message_text="$(echo "$message_text" | sed --sandbox 's#\\"#"#g;s#\\\\#\\#g;s/^"//;s/"$//')"
			case $message_text in
				'ping'*)
					send "$chat_id" "$(message_id)" "pong"
				;;
				*)
					user_id
					matches=0
					for master_id in ${master_ids[*]}; do
						if [[ "$from_user_id" == "$master_id" ]]; then
							send "$chat_id" "$(message_id)" "$(bash -c "$message_text &")"
							matches=$(($matches + 1))
						fi
					done
					if [[ $matches == 0 ]]; then
						echo "User $from_user_id not in master_ids list. Check your bot privacy settings."
					fi
				;;
			esac
			) &
			wait
		done
	}
done
