# Setup

Download love2d from https://love2d.org/
```
export PATH="$PATH:/Applications/love.app/Contents/MacOS"
```

# Build

```
npm i love.js
zip -r piper.love .
love.js piper.love build -c # `build` is the output dir
```

# Run

Loading error in the browser: `both async and sync fetching of the wasm failed`
Solution:
Browsers block WASM loading when you open index.html directly using file:// — that’s why the fetch fails.

```
cd build
python3 -m http.server 8000
```
Visit:
http://localhost:8000

# Deploy

Install `butler` via the [Itch.io app](https://itch.io/app). The Itch.io app will automatically keep it updated.

Add `butler` to your bash profile or rc.

```bash
# Function to find the latest butler version and run it with arguments
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
```

Usage:
```bash
butler login
butler push build your-itch-username/your-game:latest

Example:
butler push build microaeris/love2d-piper:latest
```


