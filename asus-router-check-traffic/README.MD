#  Router Traffic Monitor with Alerting (Windows PowerShell)

This project allows monitoring your router’s daily internet traffic and sends alert notifications if usage exceeds a defined threshold. It runs hourly using Windows Task Scheduler.

##  Features

- Retrieves traffic statistics from your router's web interface (via HTTP Basic Auth)
- Calculates daily usage based on 00:00 baseline
- Sends hourly usage data to **Webhook 1**
- Sends alert to **Webhook 2** if daily usage exceeds threshold
- Secrets and tokens are stored in a separate `secrets.json` file
- Auto-registers Task Scheduler job to run hourly

##  Project Structure

```
.
├── check_router_traffic.ps1    # Main PowerShell script
├── secrets.json                # Contains credentials and tokens
└── register_task.ps1           # Registers a scheduled task to run the main script hourly
```

##  Setup Instructions

### 1. Clone or copy the files

Save the scripts in a folder, for example:  
`C:\Scripts\`

### 2. Fill in `secrets.json`

```json
{
  "routerUrl": "http://192.168.1.1",
  "routerUsername": "admin",
  "routerPassword": "your_password",
  "webhook1": "https://your-webhook-1.url/token_here",
  "webhook2": "https://your-webhook-2.url/another_token",
  "trafficThresholdGB": 100,
  "checkIntervalMinutes": 60
}
```

- `routerUrl` — your router admin panel URL  
- `trafficThresholdGB` — daily usage threshold in GB  
- `checkIntervalMinutes` — how often the script runs (typically 60)  
- `webhook1`, `webhook2` — your endpoints for status updates and alerts  

### 3. Set correct script path in `register_task.ps1`

Edit this line:

```powershell
$scriptPath = "C:\Scripts\check_router_traffic.ps1"
```

### 4. Run task registration (as Administrator)

Open PowerShell as Administrator and run:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\register_task.ps1
```

This creates a scheduled task named `CheckRouterTrafficHourly` that runs hourly.

##  Notes

- Script uses **Basic Auth** — ensure HTTPS or local-only router access.
- Traffic stats are reset daily at midnight.
- Task Scheduler will run under the current user; make sure they have PowerShell rights.

##  Testing

You can run the script manually to verify:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\check_router_traffic.ps1
```

It will print output and send webhook notifications (if thresholds are crossed).
