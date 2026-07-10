# Apple 앱 (iOS + watchOS)

Xcode에서 iOS + Watch 앱 타겟을 만드는 방법입니다.

## 요구사항

- Xcode 16+
- iOS 17+ / watchOS 10+
- Apple Developer 계정 ($99/년)

## 1. Xcode 프로젝트 생성

1. **File → New → Project → iOS App**
2. Product Name: `MyGolfGPS`
3. Interface: SwiftUI, Language: Swift
4. **File → New → Target → watchOS → Watch App**
5. Product Name: `MyGolfGPSWatch`

## 2. MyGolfGPSCore 패키지 추가

1. **File → Add Package Dependencies → Add Local…**
2. `apple/MyGolfGPSCore` 폴더 선택
3. iOS 타겟과 Watch 타겟 모두에 `MyGolfGPSCore` 링크

## 3. 소스 파일 복사

Xcode가 만든 기본 `ContentView.swift`, `*App.swift` 를 삭제하고 이 폴더의 파일을 타겟에 추가:

| 파일 | 타겟 |
|------|------|
| `MyGolfGPS/MyGolfGPSApp.swift` | iOS |
| `MyGolfGPS/PhoneSession.swift` | iOS |
| `MyGolfGPS/ContentView.swift` | iOS |
| `MyGolfGPSWatch/MyGolfGPSWatchApp.swift` | Watch |
| `MyGolfGPSWatch/WatchSession.swift` | Watch |
| `MyGolfGPSWatch/WatchContentView.swift` | Watch |

## 4. Capabilities

### iOS 타겟
- **Location When In Use** — `NSLocationWhenInUseUsageDescription` in Info.plist

### Watch 타겟
- **Location** — `NSLocationWhenInUseUsageDescription`
- **HealthKit** — Workout (golf) for background GPS
- **Background Modes** — Workout processing (if available)

### Both
- WatchConnectivity는 별도 entitlement 불필요 (같은 앱 그룹)

## 5. API URL

`PhoneSession.swift` 에서:
- **Debug**: `http://localhost:3000` (로컬 `npm run dev`)
- **Release**: `https://mygolfgps.vercel.app` (Vercel 배포 후 도메인 확인)

## 6. 실행

1. iPhone 시뮬레이터 + Watch 시뮬레이터 페어링
2. iOS 앱 실행 → 코스 검색 → 다운로드 → Start on Watch
3. Watch 앱에서 Start Round → 거리 확인

> 시뮬레이터에서는 GPS가 부정확합니다. 실기기 + 실제 코스에서 테스트하세요.

## 7. 테스트 코스

OSM 데이터가 풍부한 미국 코스 예시:
- Torrey Pines Golf Course (San Diego)
- Bethpage State Park Black Course (NY)
- Chambers Bay (WA)

검색 API로 `mappedHoleCount` 가 14 이상인 코스를 선택하세요.
