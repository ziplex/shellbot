#!/bin/bash

###########################################################

master_ids=()	##### insert your Telegram ID here
token=''	##### insert your token here

###########################################################

api_url='https://api.telegram.org'
tele_url="$api_url/bot$token"
response_length=512     ##### default response length is 512, can be increased
                        ##### to no more than 1024

###########################################################
