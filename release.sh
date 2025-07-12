butler() {
    local butler_dir="/Users/aeris/Library/Application Support/itch/broth/butler/versions"
    local latest_version=$(ls -1 "$butler_dir" | sort -V | tail -n 1)
    local butler_path="$butler_dir/$latest_version/butler"

    if [[ -f "$butler_path" ]]; then
        "$butler_path" "$@"
    else
        echo "Error: Butler executable not found at $butler_path"
        return 1
    fi
}

butler push build microaeris/love2d-piper:latest