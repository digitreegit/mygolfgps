# MyGolfGPS — MVP 설계

## 한 줄 요약

**미국 코스만, Apple Watch에서 코스 선택 → 홀 1~18 수동 전환 → 그린까지 야드** 를 OSM 무료 데이터로 제공한다.

## MVP 범위 (v0.1)

| 포함 | 제외 |
|------|------|
| 코스 검색 (이름 / 근처) | 홀 자동 인식 |
| OSM 그린 좌표가 있는 코스만 플레이 가능 | 샷 트래킹, 스코어카드 |
| 홀 번호 수동 변경 (탭 / Digital Crown) | 지도, 벙커/페어웨이 표시 |
| 그린 핀 거리 (야드) 실시간 | GolfCourseAPI (유료/제한) |
| iPhone 동반 앱 (App Store 필수) | 데스크톱 동기화 |
| Vercel API로 OSM 프록시 + 캐시 | 한국/글로벌 코스 |

## 사용자 플로우

```
[iPhone] 앱 설치 → 위치 권한
    ↓
[iPhone] 코스 검색 → 목록에서 선택 → 코스 데이터 다운로드
    ↓
[Watch] "Start Round" → 현재 홀 번호 + 그린까지 야드
    ↓
[Watch] Crown 돌리거나 탭으로 홀 1↔18 변경
    ↓
[Watch] GPS 업데이트마다 거리 갱신
```

## 화면 (Watch)

### 1. 대기 / 시작
- iPhone에서 라운드 시작 전: 코스 이름 표시
- "Start" 버튼

### 2. 라운드 (메인)
```
        HOLE 7
       ───────
         142
         yds
    ◀  7 / 18  ▶
```
- 큰 숫자: 그린 중심까지 야드
- 좌/우 탭 또는 Digital Crown: 홀 변경
- 상단: 홀 번호

### 3. 코스 데이터 없음
- "No green data for this hole" — OSM에 `golf=green` 없는 홀

## 화면 (iPhone)

### 1. 코스 검색
- 검색창 + "Near me" 버튼
- 결과 리스트: 이름, 거리(마일)

### 2. 코스 상세
- 18홀 그린 데이터 유무 표시 (예: 16/18 holes mapped)
- "Download & Start on Watch" 버튼

## 데이터 모델

```json
{
  "id": "osm-12345",
  "name": "Pebble Beach Golf Links",
  "location": { "lat": 36.57, "lon": -121.95 },
  "holes": [
    {
      "number": 1,
      "greenCenter": { "lat": 36.571, "lon": -121.949 },
      "hasGreen": true
    }
  ],
  "mappedHoleCount": 16,
  "totalHoles": 18
}
```

## API (Vercel)

| Endpoint | 설명 |
|----------|------|
| `GET /api/courses/search?q=&lat=&lon=` | 코스 검색 |
| `GET /api/courses/[osmType]/[osmId]` | 홀별 그린 좌표 다운로드 |

Overpass API를 서버에서 호출해 **레이트 리밋·캐시** 처리. Watch/iPhone은 Vercel API만 호출.

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| API + 랜딩 | Next.js 15 on Vercel |
| iPhone | SwiftUI, WatchConnectivity |
| Watch | SwiftUI, CoreLocation, HKWorkoutSession (백그라운드 GPS) |
| 공유 로직 | `MyGolfGPSCore` Swift Package |
| 코스 데이터 | OpenStreetMap (ODbL) |

## OSM 데이터 조건

정확히 동작하려면 코스에 다음이 있어야 함:

- `leisure=golf_course` — 코스 경계
- `golf=hole` + `ref=1..18` — 홀 라인
- `golf=green` — 그린 폴리곤 (홀 근처)

미국도 OSM 매핑 품질이 코스마다 다름. MVP에서는 **mappedHoleCount** 를 보여주고, 14홀 이상이면 플레이 가능으로 표시.

## 거리 계산

- Haversine / `CLLocation.distance(from:)` 직선 거리
- 그린 중심 = `golf=green` 폴리곤 centroid
- 단위: 야드 (미국 전용)

## Watch GPS 전략

1. **HKWorkoutSession** — 라운드 중 백그라운드 위치 업데이트 (GoBirdie와 동일 패턴)
2. Watch 자체 GPS 사용 (iPhone 스트리밍 불필요 — MVP 단순화)
3. iPhone은 코스 다운로드 + WatchConnectivity로 코스 JSON 전송

## 마일스톤

### M0 — 지금 (스캐폴딩)
- [x] 리포 구조, 문서
- [ ] Vercel API 동작
- [ ] Swift Core 패키지
- [ ] Watch/iPhone Xcode 프로젝트

### M1 — 첫 라운드 (2주)
- iPhone 코스 검색/다운로드
- Watch 거리 표시 + 홀 변경
- 실제 코스 1곳 E2E 테스트

### M2 — TestFlight (4주)
- UI 다듬기
- 오프라인 코스 캐시
- App Store 메타데이터

## 비용

| 항목 | 비용 |
|------|------|
| Apple Developer | $99/년 (필수) |
| Vercel | Hobby 무료 (API 트래픽 적으면 충분) |
| OSM / Overpass | 무료 |
| **합계** | **$99/년** |

## 리스크

1. **OSM 커버리지** — 유명 코스는 대체로 있음, 로컬 퍼블릭은 없을 수 있음
2. **Overpass 타임아웃** — Vercel 캐시 + bbox 좁히기로 완화
3. **Watch 배터리** — HKWorkoutSession 사용 시 라운드당 ~10–15% 예상
