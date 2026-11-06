# 기능별 상태와 데이터 접근 구조

BookMate는 SwiftUI·Combine 기반 MVVM을 사용한다. 앱 진입점에서 의존성을 구성하고, 기능별 ViewModel이 화면 상태를 소유하며, 데이터 읽기·쓰기는 Repository 계약을 통해 실행한다.

## 구성과 책임

| 위치 | 역할 |
| --- | --- |
| `Core/Dependencies/AppDependencies` | 실제 Repository와 플랫폼 서비스를 구성하는 생성자 주입 지점 |
| `Core/Dependencies/AppContext` | 기능이 함께 사용하는 토스트·작업 오류·인증 만료 신호 |
| `Features/Library` | 책 등록·수정·삭제, 책장 순서와 등록 확인 화면 |
| `Features/Words` | 단어 기록, 아카이브 필터와 책 등록 후 단어 저장 재개 |
| `Features/Search` | 사전·도서·저장 기록 검색 상태와 최근 검색어 |
| `Features/Quotes`, `ReadingMemos`, `Reviews` | 책에 연결된 각 기록의 상태와 저장 동작 |
| `Features/Auth` | 로그인·세션 복구·프로필·탈퇴 |
| `Features/Social`, `Moderation` | 유저 검색·공개 책장·방명록·신고 요청 |
| `Features/Notifications` | 알림 목록·읽음 처리·읽지 않은 개수 |
| `Repositories` | 기능이 요구하는 데이터 접근 계약과 로컬 저장 구현 |
| `Services` | REST·외부 검색·키체인·OS 서비스의 구체 구현 |
| `ViewModel/BookMateViewModel` | 기존 화면의 호출을 각 기능으로 연결하는 앱 조정 지점 |

View의 포커스·시트 표시·NavigationPath 등 화면 안에서 쓰는 표현 상태는 View가 관리한다. 여러 데이터 상태가 함께 바뀌거나 저장·조회가 필요한 동작은 ViewModel에 둔다.

## 하나의 원본 상태

기록 배열을 공유 ViewModel과 기능 ViewModel에 각각 저장하지 않는다. 예를 들어 `quotes`의 원본은 `QuoteViewModel`에 있으며, 기존 화면에서 읽는 `BookMateViewModel.quotes`는 이 값을 전달한다. 자식의 `objectWillChange`를 전달하여 기존 SwiftUI 화면의 관찰과 Binding을 유지한다.

미니룸은 책장 기능의 `$books`만 별도로 구독한다. 관련 없는 검색·토스트 변경으로 책 목록의 관찰 범위가 넓어지지 않도록 기존의 구독 분리를 유지한다.

공개 책장과 방명록 시트는 같은 `GuestbookViewModel`을 사용한다. 낙관적 메시지·전송 중 ID·서버 응답 교체와 실패 복구도 같은 객체에서 처리한다.

## 의존성 주입

`AppDependencies`의 각 인자는 생략하면 기존 실제 구현을 사용한다. 테스트에서는 필요한 Repository만 대체한다.

```swift
let dependencies = AppDependencies(quotes: repository)
let model = BookMateViewModel(dependencies: dependencies)
```

기존 API Service가 Repository 프로토콜을 구현한다. 이름만 다른 전달 클래스를 추가하지 않고, 기존 요청·응답 매핑 코드를 재사용한다. 화면과 ViewModel은 URLSession이나 구체적인 API Service를 생성하지 않는다.

인증의 토큰 저장소·소셜 로그인·푸시 동기화, 책장의 로컬 순서 저장과 독서 알림 예약도 교체 가능한 경계로 전달한다. 시스템 권한 창, 화면 이동, 키보드와 로컬 UI 설정은 기존 플랫폼 흐름을 유지한다.

## 데이터와 동작 호환성

- 최근 검색어의 사용자·검색 종류별 키와 JSON Data 형식을 유지한다.
- 책장 순서의 `shelfBookOrder.<사용자 UUID 또는 guest>` 키와 문자열 UUID 배열을 유지한다.
- 책 등록 중복 판단과 진행률·독서 상태 정규화를 유지한다. 같은 등록 요청이 진행 중이면 Task를 공유한다.
- 사전 표제어 정리·어근 대체 검색·후보 점수와 중복 제거 규칙을 유지한다.
- 오래된 검색 응답이 새 결과를 덮거나 초기화한 결과를 되살리지 않도록 요청 식별자를 확인한다.
- 인증 헤더·refresh token 조율·재시도는 기존 APIClient와 TokenRefreshCoordinator가 담당한다.
- 화면의 배치·색상·문구·패널 애니메이션은 구조 변경 범위에서 유지한다.

## 검증 범위

XCTest는 주입한 저장소를 사용하여 성공·실패·401·저장 형식·상태 관찰·동시 등록·검색 응답 순서·방명록 복구 등을 확인한다.

UI 테스트는 명시적인 `--ui-testing` 인자를 받은 Debug 앱에서 메모리 데이터로 실행한다. 이 경로는 운영 API·실제 키체인·Firebase 초기화를 사용하지 않는다. Release 빌드에는 Debug 데이터 구현이 포함되지 않는다.

CI는 iPhone 단위·UI 테스트, 같은 빌드의 iPad UI 테스트와 Release 시뮬레이터 컴파일을 실행한다. 테스트 설정은 로컬 API 환경과 비운영 설정을 사용하며, 배포나 Crashlytics 심볼 업로드를 실행하지 않는다.

이 검증은 실제 서버의 응답 계약, 실기기 알림 권한, Apple/Kakao 로그인 및 Archive 심볼 업로드의 운영 확인을 대체하지 않는다. UI 스크린샷은 현재 화면의 기록이며 이전 버전과의 픽셀 일치 측정은 아니다.
