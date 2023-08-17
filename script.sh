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

    day_of_week_number=$(get_day_of_week_number)-1
    day_of_week=${week_days[$day_of_week_number]}
    random_food_emoji=${food_emojis[$RANDOM % ${#food_emojis[@]}]}
    current_date=$(date +"%m.%d")

    text="($current_date) $day_of_week $random_food_emoji\n\n"

    zona_data=$(echo "$json_data" | jq '.["ZONA"]')
    foods_prices=$(echo "$zona_data" | jq --arg day "$day_of_week" -r '.[$day]')

    output=""
    while IFS= read -r line; do
        output+="$line\n\n"
    done <<< "$(echo "$foods_prices" | jq -r '.[] | .food + "  -  " + (.price|tostring)')"
    text+="ZONA:\n\n"

    text+=$output

    text+="METISZ:\n\n"
    output=""
    metisz_data=$(echo "$json_data" | jq '.["METISZ"]')
    foods_prices=$(echo "$metisz_data" | jq --arg day "$day_of_week" -r '.[$day]')
    while IFS= read -r line; do
        output+="$line\n\n"
    done <<< "$(echo "$foods_prices" | jq -r '.[] | .food + "  -  " + (.price|tostring)')"
    text+=$output


    echo -e $text

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
