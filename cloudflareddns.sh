#!/bin/bash
set -e;

ip6Addr=$(ip -6 addr show eth0 | grep -oP "([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}" -m 1)

username="$1"
password="$2"
hostname="$3"
# ipAddr="$4"

res=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${username}/dns_records?type=AAAA&name=${hostname}" \
  -H "Authorization: Bearer ${password}")

if [[ $(echo "$res" | jq -r ".success") != "true" ]]; then
  echo "badauth";
  exit 1;
fi

recordId=$(echo "$res" | jq -r ".result[0].id")
recordIp=$(echo "$res" | jq -r ".result[0].content")

if [[ $recordId = "null" ]]; then
  echo "nohost";
  exit 1;
fi
if [[ $recordIp = "$ip6Addr" ]]; then
  echo "nochg";
  exit 0;
fi

res=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${username}/dns_records/${recordId}" \
  -H "Authorization: Bearer ${password}"\
  -d "{\"content\":\"${ip6Addr}\"}")

if [[ $(echo "$res" | jq -r ".success") = "true" ]]; then
  echo "good";
else
  echo "badparam";
  exit 1;
fi
