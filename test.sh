curl -s "$(terraform output -raw public_url)/queue" -X POST | jq
