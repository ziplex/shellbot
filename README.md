# shellbot

Simple Telegram bot that execute commands received from chat in shell
You can just control your server without SSH access 
Support many master ID's, you can provide access for other

Requirements: bash, curl, jq

How to use:
1. Clone git repository
2. Insert bot token and your Telegram ID to config.sh
3. a) Run "shellbotd.sh &" in tmux/screen

	   or

   b) Run "./install.sh" for create, enable and start systemd unit (better way)

For checking connection send 'ping' in the chat