# GoBirdie 포크 vs 새로 만들기

## 결론: **새로 만든다** (GoBirdie는 참고만)

| 기준 | GoBirdie 포크 | MyGolfGPS 신규 |
|------|---------------|----------------|
| MVP까지 시간 | 느림 (기능 제거/refactor) | 빠름 (필요한 것만) |
| 코드 복잡도 | 높음 (~150 파일) | 낮음 (~20 파일 목표) |
| Watch 독립성 | iPhone이 좌표 스트리밍 | Watch GPS 직접 사용 |
| OSM 파싱 | 이미 있음 ✅ | Vercel TS + Swift Core로 이식 |
| 라이선스 | MIT — 포크 가능 | 자유 |
| 요구 OS | iOS 18 / watchOS 11 / Xcode 26 | iOS 17 / watchOS 10 (완화 가능) |

## GoBirdie에서 가져올 것 (코드 복사 X, 패턴만)

1. **Overpass 쿼리 구조** — bbox 검색, `golf=hole` + `golf=green` 매칭
2. **HKWorkoutSession** — Watch 백그라운드 GPS
3. **Digital Crown 홀 네비게이션** — `WatchRoundView` UX 패턴
4. **DistanceEngine** — front/pin/back 계산 (MVP는 pin만)

## GoBirdie에서 버릴 것

- 샷 트래킹, 클럽 피커, 퍼트 입력
- GolfCourseAPI 연동 (par/yardage — MVP 불필요)
- MapLibre 지도, GeoJSON 빌더
- MultipeerConnectivity 데스크톱 동기화
- 토너먼트, 인사이트, 스코어카드
- 홀 자동 감지 (tee proximity alert)
- iPhone → Watch 좌표 스트리밍 (Watch가 직접 GPS)

## 아키텍처 비교

### GoBirdie
```
iPhone (OSM 다운로드, GPS, 지도)
    │ WatchConnectivity
    ▼
Watch (거리 표시, 샷/스코어)
```

### MyGolfGPS MVP
```
Vercel API (OSM 프록시 + 캐시)
    │
    ▼
iPhone (코스 검색/다운로드)
    │ WatchConnectivity (코스 JSON만)
    ▼
Watch (GPS + 거리 + 홀 변경)
```

Vercel을 넣은 이유:
- Overpass 직접 호출은 모바일에서 느리고 429 빈번
- 서버 캐시로 같은 코스 재요청 즉시 응답
- 이미 Vercel 프로젝트 연결됨

## 리포 구조

```
mygolfgps/
├── docs/           # 설계 문서
├── web/            # Next.js → Vercel
├── apple/
│   ├── MyGolfGPSCore/   # Swift Package (모델, 거리, API 클라이언트)
│   ├── MyGolfGPS/       # iOS 앱 소스
│   └── MyGolfGPSWatch/  # watchOS 앱 소스
└── README.md
```

## 다음 단계

1. `web/` 배포 → API URL 확정
2. Xcode에서 iOS + Watch 타겟 생성 (`apple/README.md` 참고)
3. 실제 코스 1곳으로 E2E 테스트
4. TestFlight
