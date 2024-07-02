function urldecode --description 'Decode URL-encoded input'
    read -l input
    string unescape --style url "$input"
end
