```markdown
# Browser Cache Cleaner (PowerShell)

A safe and configurable PowerShell script to detect installed browsers and clean their cache directories.

The script is designed to:

- Support **multiple browser profiles**
- Work with **Chromium-based browsers and Firefox**
- **Skip missing browsers or profiles silently**
- Never crash if something is not found
- Append logs to a single `log.txt` file

---

## Supported Browsers

- Google Chrome (all profiles)
- Google Chrome Dev
- Google Chrome Canary
- Microsoft Edge (all profiles)
- Mozilla Firefox
- Firefox Developer Edition

> Only cache directories are removed.  
> **Passwords, cookies, history, and user data are NOT touched.**

---

## Project Structure
```

browser-cache-cleaner/
│
├── clean-cache.ps1
├── browsers.json
├── log.txt
└── README.md

````

---

## Configuration (`browsers.json`)

All browser root paths are defined in `browsers.json`.

Profiles are detected automatically:
- Chromium browsers: `Default`, `Profile 1`, `Profile 2`, etc.
- Firefox: detected via `profiles.ini`

You can safely add or remove browsers from this file.

---

## How It Works

1. Reads browser definitions from `browsers.json`
2. Expands environment variables (`%LOCALAPPDATA%`, `%APPDATA%`)
3. Detects existing browsers
4. Detects all available profiles
5. Stops browser processes (if running)
6. Cleans cache directories only:
   - Chromium: `Cache`, `Code Cache`, `GPUCache`
   - Firefox: `cache2`
7. Writes all actions to `log.txt` (append mode)

Missing browsers or profiles are **skipped without errors**.

---

## Usage

Run the script from PowerShell:

```powershell
.\clean-cache.ps1
````

No administrator privileges are required.

---

## Logging

All actions are appended to `log.txt`:

```
YYYY-MM-DD HH:mm:ss [INFO] Browser detected: Google Chrome
YYYY-MM-DD HH:mm:ss [INFO] Profile detected: Profile 1
YYYY-MM-DD HH:mm:ss [INFO] Cleared: ...\Cache
```

Errors (if any) are logged but do not stop execution.

---

## Safety Notes

- Browsers are force-closed before cache cleanup
- Only cache folders are removed
- The script is safe to run multiple times
- Designed for QA, automation, and CI usage

---

## Typical Use Cases

- Clean browser cache before Playwright / E2E tests
- Resolve browser cache-related issues
- Regular maintenance on developer machines
- CI or scheduled cleanup tasks

---

## License

Use freely for personal or commercial purposes.
No warranty is provided.

```

```
