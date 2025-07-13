# Setup 

Download love2d from https://love2d.org/
```bash
export PATH="$PATH:/Applications/love.app/Contents/MacOS"
```

# Build

Setup love.js
```bash
npm i love.js
```

Build
```bash
./build.sh
```

# Local Testing

Loading error in the browser: `both async and sync fetching of the wasm failed`
Solution:
Browsers block WASM loading when you open index.html directly using file:// — that’s why the fetch fails.

Testing in the browser:
```bash
./run_web.sh
```

Run locally:
```bash
love .
```

# Deploy

Install `butler` via the [Itch.io app](https://itch.io/app). The Itch.io app will automatically keep it updated.

```bash
./release.sh
```
