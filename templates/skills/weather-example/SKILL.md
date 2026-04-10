---
name: weather
description: |
  Weather forecasts and current conditions for any location.
  Triggers: "weather", "weer", "temperature", "temperatuur", "forecast", "rain", "regen", "wind", "how cold", "hoe warm".
user-invocable: true
---

# Weather Skill

## Role Activation

When this skill loads, IMMEDIATELY:

1. Determine the location (ask if not clear from context)
2. Fetch current weather using the script or curl
3. Present a concise summary: temperature, conditions, wind

## Credentials & Auth

**No API key needed.** Open-Meteo is free, open-source, and requires no registration.

- **Base URL:** `https://api.open-meteo.com/v1/forecast`
- **Rate limit:** 10,000 requests/day (more than enough)
- **No headers required**

## HTTP Method

Use **ALWAYS `curl` via Bash** for all API calls.
Use NEVER Python `urllib`, `requests`, or WebFetch.

## Request Templates

### Current weather for a location

```bash
curl -sf "https://api.open-meteo.com/v1/forecast?latitude=52.37&longitude=4.89&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m&timezone=auto"
```

### Multi-day forecast (7 days)

```bash
curl -sf "https://api.open-meteo.com/v1/forecast?latitude=52.37&longitude=4.89&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum&timezone=auto"
```

### Hourly forecast (next 24h)

```bash
curl -sf "https://api.open-meteo.com/v1/forecast?latitude=52.37&longitude=4.89&hourly=temperature_2m,precipitation_probability,weather_code&forecast_hours=24&timezone=auto"
```

### Using the helper script

```bash
bash skills/weather-example/scripts/weather.sh 52.37 4.89
bash skills/weather-example/scripts/weather.sh 52.37 4.89 forecast
```

## Inline Knowledge (needed every call)

### Location Coordinates

Common locations (extend this list for your users):

| Location | Latitude | Longitude |
|----------|----------|-----------|
| Amsterdam | 52.37 | 4.89 |
| Rotterdam | 51.92 | 4.48 |
| Utrecht | 52.09 | 5.12 |
| Den Haag | 52.08 | 4.31 |
| London | 51.51 | -0.13 |
| New York | 40.71 | -74.01 |
| Paris | 48.86 | 2.35 |

**If the user says a city not in this list:** use your general knowledge of coordinates, or ask them.

### Weather Codes (WMO)

| Code | Meaning | Emoji |
|------|---------|-------|
| 0 | Clear sky | ☀️ |
| 1-3 | Partly cloudy | ⛅ |
| 45, 48 | Fog | 🌫️ |
| 51-55 | Drizzle | 🌦️ |
| 61-65 | Rain | 🌧️ |
| 66-67 | Freezing rain | 🌧️❄️ |
| 71-75 | Snowfall | 🌨️ |
| 77 | Snow grains | 🌨️ |
| 80-82 | Rain showers | 🌧️ |
| 85-86 | Snow showers | 🌨️ |
| 95 | Thunderstorm | ⛈️ |
| 96, 99 | Thunderstorm with hail | ⛈️🧊 |

### Response Format

Present weather concisely. Example:

> **Amsterdam** — 18°C (voelt als 16°C), ⛅ licht bewolkt, wind 12 km/h, luchtvochtigheid 65%

For forecasts, use a compact table:

> | Dag | Min | Max | Weer | Neerslag |
> |-----|-----|-----|------|----------|
> | Ma  | 12° | 19° | ⛅   | 0 mm     |
> | Di  | 10° | 16° | 🌧️  | 8 mm     |

## Error Handling

| Error | Meaning | Action |
|-------|---------|--------|
| curl exit code != 0 | Network error or API unreachable | Tell user the weather service is temporarily unavailable |
| `"error": true` in response | Invalid parameters | Check latitude/longitude are valid numbers |
| Empty `current` object | Parameters not recognized | Verify parameter names match API docs |
| Timeout (>10s) | API slow | Retry once with `--max-time 10`, then report |

## Common Tasks

| Task | Action |
|------|--------|
| Current weather | `curl` with `current=temperature_2m,weather_code,wind_speed_10m` |
| Will it rain today? | `curl` with `hourly=precipitation_probability&forecast_hours=24` |
| Weekly forecast | `curl` with `daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum` |
| Specific hour | `curl` with `hourly=temperature_2m&forecast_hours=48`, find the right slot |

## Safety Rules

- No credentials to protect — this API is fully public
- Don't spam the API — one call per user question is enough
- Cache-friendly: weather doesn't change every second, no need to re-fetch within the same conversation turn

## Escalation

This skill rarely needs escalation. If the API returns unexpected data:

```
Weather API returned unexpected data:
- Request: [the URL you called]
- Response: [first 200 chars of response]
- Expected: JSON with "current" or "daily" object
```
