#!/usr/bin/env bash
set -euo pipefail

# Weather skill script — fetches current weather or 7-day forecast from Open-Meteo
# Usage: weather.sh <latitude> <longitude> [forecast]
# No API key needed. Free and open-source.

BASE_URL="https://api.open-meteo.com/v1/forecast"

# --- Input validation ---
if [[ $# -lt 2 ]]; then
  echo "Usage: weather.sh <latitude> <longitude> [forecast]" >&2
  echo "  weather.sh 52.37 4.89           # current weather in Amsterdam" >&2
  echo "  weather.sh 52.37 4.89 forecast  # 7-day forecast" >&2
  exit 1
fi

LAT="$1"
LON="$2"
MODE="${3:-current}"

# --- Fetch weather ---
case "$MODE" in
  current)
    RESPONSE=$(curl -sf --max-time 10 \
      "${BASE_URL}?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m&timezone=auto")
    ;;
  forecast)
    RESPONSE=$(curl -sf --max-time 10 \
      "${BASE_URL}?latitude=${LAT}&longitude=${LON}&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum&timezone=auto")
    ;;
  *)
    echo "Unknown mode: $MODE (use 'current' or 'forecast')" >&2
    exit 1
    ;;
esac

# --- Parse and format output with Python (available in container) ---
python3 -c "
import json, sys

data = json.loads(sys.argv[1])
mode = sys.argv[2]

# WMO weather codes to descriptions
WMO = {
    0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
    45: 'Fog', 48: 'Rime fog',
    51: 'Light drizzle', 53: 'Drizzle', 55: 'Heavy drizzle',
    61: 'Light rain', 63: 'Rain', 65: 'Heavy rain',
    66: 'Light freezing rain', 67: 'Heavy freezing rain',
    71: 'Light snow', 73: 'Snow', 75: 'Heavy snow', 77: 'Snow grains',
    80: 'Light showers', 81: 'Showers', 82: 'Heavy showers',
    85: 'Light snow showers', 86: 'Heavy snow showers',
    95: 'Thunderstorm', 96: 'Thunderstorm with hail', 99: 'Severe thunderstorm'
}

if mode == 'current':
    c = data['current']
    code = c.get('weather_code', -1)
    desc = WMO.get(code, f'Unknown ({code})')
    print(f\"Temperature: {c['temperature_2m']}°C (feels like {c['apparent_temperature']}°C)\")
    print(f\"Conditions:  {desc}\")
    print(f\"Wind:        {c['wind_speed_10m']} km/h\")
    print(f\"Humidity:    {c['relative_humidity_2m']}%\")
    print(f\"Timezone:    {data.get('timezone', 'unknown')}\")

elif mode == 'forecast':
    d = data['daily']
    dates = d['time']
    print(f\"{'Date':<12} {'Min':>5} {'Max':>5}  {'Precip':>7}  Conditions\")
    print('-' * 55)
    for i, date in enumerate(dates):
        code = d['weather_code'][i]
        desc = WMO.get(code, f'Unknown ({code})')
        lo = d['temperature_2m_min'][i]
        hi = d['temperature_2m_max'][i]
        rain = d['precipitation_sum'][i]
        print(f\"{date:<12} {lo:>4.0f}° {hi:>4.0f}°  {rain:>5.1f} mm  {desc}\")
" "$RESPONSE" "$MODE"
