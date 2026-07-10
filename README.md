# MyGolfGPS

Golf GPS for Apple Watch — **course select → hole 1–18 → yards to green**.

US courses only. Free OpenStreetMap data. No subscription.

## Status: MVP scaffolding

| Component | Status |
|-----------|--------|
| [MVP design](docs/MVP.md) | ✅ |
| [Architecture decision](docs/DECISIONS.md) | ✅ New app (not GoBirdie fork) |
| [Vercel API](web/) | ✅ Course search + download |
| [Swift Core](apple/MyGolfGPSCore/) | ✅ Models, distance, API client |
| [iOS + Watch apps](apple/) | ✅ Source ready — needs Xcode project |
| TestFlight | 🔜 |

## Quick start

### Web API (Vercel)

```bash
cd web
npm install
npm run dev
# http://localhost:3000
```

```bash
# Search near San Francisco
curl "http://localhost:3000/api/courses/search?lat=37.77&lon=-122.42&q=torrey"

# Download course (use osmType + osmId from search results)
curl "http://localhost:3000/api/courses/way/123456?name=Torrey+Pines"
```

### Apple apps

See [apple/README.md](apple/README.md) for Xcode setup.

### Deploy to Vercel

1. Vercel project: [vercel.com/digitreegits-projects/mygolfgps](https://vercel.com/digitreegits-projects/mygolfgps)
2. **Settings → General → Root Directory → `web`** (필수)
3. Framework Preset: **Next.js** (자동 감지)
4. Git push 후 자동 배포, 또는 Deployments → Redeploy

> Root Directory가 `.`(루트)이면 빌드 실패 → `404 NOT_FOUND` 발생

## Architecture

```
Vercel API (OSM proxy + cache)
       │
       ▼
  iPhone app ──WatchConnectivity──▶ Watch app
  (course search)                    (GPS + yards)
```

## Cost

- Apple Developer: **$99/year** (required)
- Vercel Hobby: free
- OSM data: free (ODbL attribution required)

## License

MIT — OSM data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors (ODbL).
