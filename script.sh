#!/bin/bash

source_url="$ZONA_API_URL"
destination_url="$TEAMS_WEBHOOK_URL"

week_days=("HETFO" "KEDD" "SZERDA" "CSUTORTOK" "PENTEK")
food_emojis=("🍔" "🍕" "🍣" "🍟" "🌭" "🍦" "🍩" "🍪" "🥐" "🥪" "🍿" "🍗" "🍜" "🍝" "🍛" "🍤" "🍱" "🍚" "🍙" "🍅" "🍉" "🍍" "🍇" "🍈" "🍊" "🍋" "🍌" "🍎" "🍏" "🍒" "🍓" "🍑" "🍐" "🍔🍟" "🍕🍺")

get_json_from_url() {
    local url="$1"
    curl -sS "$url"
}

post_json_to_endpoint() {
    local json_data="$1"
    local endpoint_url="$2"
    curl -sS -H "Content-Type: application/json" -X POST -d "$json_data" "$endpoint_url"
}

get_day_of_week_number() {
    date +"%w"
}

json_data=$(get_json_from_url "$source_url")
if [ -n "$json_data" ]; then
    echo "Fetched JSON successfully."

    day_of_week_number=$(get_day_of_week_number)
    day_of_week=${week_days[$day_of_week_number]}
    random_food_emoji=${food_emojis[$RANDOM % ${#food_emojis[@]}]}
    current_date=$(date +"%m.%d")

    text="($current_date) $day_of_week $random_food_emoji\n\n"
    for item in $(echo "$json_data" | jq -c ".[\"$day_of_week\"][]"); do
        food=$(echo "$item" | jq -r ".food")
        price=$(echo "$item" | jq -r ".price")
        text+="$(echo -e "$food - $price\n\n")"
    done

    json_data="{\"text\": \"$text\"}"

    response_data=$(post_json_to_endpoint "$json_data" "$destination_url")
    if [ -n "$response_data" ]; then
        echo "POST request successful. Response from the destination endpoint:"
        echo "$response_data"
    else
        echo "POST request failed."
    fi
else
    echo "Failed to fetch JSON from the source URL."
fi
