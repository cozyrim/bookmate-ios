# 개발 환경 설정

## 필요한 환경

- iOS 26.2 이상 SDK를 지원하는 Xcode. 프로젝트의 Swift 언어 모드는 5.0.
- Swift Package Manager 의존성 다운로드를 위한 네트워크 연결.
- 본인 개발용 Firebase 프로젝트, 카카오 앱, 표준국어대사전·알라딘 API 키.
- BookMate API와 호환되는 개발 서버. 이 저장소에 서버 구현은 포함하지 않음.

## 설정 순서

1. 저장소 루트에서 로컬 설정 파일 생성.

   ```sh
   mkdir -p .local
   cp Config/Secrets.example.xcconfig .local/Secrets.xcconfig
   ```

2. `.local/Secrets.xcconfig`에 본인 개발 환경의 값 입력.

   | 설정 | 용도 |
   | --- | --- |
   | `KAKAO_NATIVE_APP_KEY` | 카카오 SDK 초기화·로그인 |
   | `KAKAO_REST_API_KEY` | 카카오 도서 검색 |
   | `STDICT_API_KEY` | 표준국어대사전 검색 |
   | `ALADIN_TTB_KEY` | 도서 상세·쪽수 조회 |
   | `BOOKMATE_API_ENVIRONMENT` | `local`, `staging`, `production` 중 선택. 개발 기본값은 `local` |

3. Firebase 콘솔에서 본인 iOS 앱의 `GoogleService-Info.plist`를 내려받아 **저장소 루트**에 배치. Xcode 프로젝트에 리소스 참조가 이미 있으므로 중복 추가 불필요.
4. `BookMate.xcodeproj`를 열고 패키지 해석 완료 대기. 앱 타깃의 Bundle Identifier와 서명 팀을 본인 환경에 맞게 변경. Firebase 앱 등록값과 카카오 iOS 플랫폼 설정도 같은 Bundle Identifier로 맞춤.
5. `BookMate` 스킴으로 실행. 공유 스킴의 Run 기본값은 `Release`이므로 디버깅 시 Edit Scheme → Run → Build Configuration을 `Debug`로 변경.

Firebase 구성과 카카오 Native App Key는 앱 초기화에 필요. 빈 예시 파일만 복사한 상태는 실행 가능한 설정이 아님.

## 서버와 알림

- `local` 서버 주소는 시뮬레이터에서 `127.0.0.1:8080`. 실기기는 [APIEnvironment.swift](../BookMate/Services/APIEnvironment.swift)의 `physicalDeviceHost`를 본인 개발 서버 주소로 변경.
- `staging`·`production`은 코드에 지정된 BookMate 서버를 사용. 별도 서버를 쓸 경우 `APIEnvironment` 수정 필요.
- 로컬 주소는 HTTP로 구성. 연결 실패 시 서버 실행·네트워크·ATS 설정 확인. 배포 설정에 전역 HTTP 허용을 추가하지 않고 개발 환경에 필요한 범위만 설정.
- 원격 알림 검증에는 Apple Push Notifications 설정, Firebase의 APNs 연동, 서버의 기기 토큰 등록·푸시 발송 설정 필요.

## 설정 파일 관리

- `.local/Secrets.xcconfig`와 실제 `GoogleService-Info.plist`는 Git에서 제외. 공개 저장소에는 값이 비어 있는 설정 예시만 포함.
- Firebase 클라이언트 구성은 비밀 자격 증명이 아님. 다만 API 키 사용 범위 제한과 사용 중인 Firebase 서비스의 접근 제어는 별도로 필요. [Firebase 공식 안내](https://firebase.google.com/docs/projects/api-keys)
- `.xcconfig`로 주입한 값도 빌드 결과의 Info.plist에 포함. 배포 앱에서 비밀 유지가 필요한 API 키는 서버에서 관리해야 함.

[README로 돌아가기](../README.md)

## 운영 Firebase 설정 확인 — 2026-09-25

- iOS API 키의 앱 제한을 실제 Bundle Identifier로 설정. 기존 API 허용 목록과 키 값 유지.
- 앱 구성의 키로 Firebase Installations 요청 검증: 올바른 앱 식별자 200, 다른 식별자 403. 검증용 설치 등록은 즉시 삭제, 실제 사용자 설치 정보 조회 없음.
- 앱 식별자 제한은 사용 범위를 줄이는 설정. 헤더 위조까지 막는 앱 인증이나 서버의 사용자·소유권 검사를 대신하지 않음.
- 서버의 Firebase 계정은 FCM API 관리자 역할로 축소. 실제 알림을 보내지 않는 검증 모드 성공. 기기에서의 푸시 수신은 별도 확인 필요.

[서버 운영 보안 적용 내역](https://github.com/cozyrim/bookmate-server/blob/main/docs/auth-and-access.md)
