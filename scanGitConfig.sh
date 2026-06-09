while read -r base_url; do
    for path in .git/config .gitignore; do
        url="${base_url}/${path}"
        echo "=== $url ==="
        response=$(curl -s -w "\n%{http_code}" "$url")
        status=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        if [[ "$status" == "403" ]]; then
            echo "403 Forbidden"
        else
            echo "$body"
        fi
        echo ""
    done
    sleep 1
done < urlsScanGitConfig.txt
