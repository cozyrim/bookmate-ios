# 토큰 만료와 동시 요청 처리

## 문제와 판단

기존 공통 클라이언트는 401 응답을 인증 오류로 전달. access token이 만료된 경우에도 바로 로그인 만료 흐름으로 넘어가는 구조.

갱신 가능한 만료는 refresh token으로 복구하도록 변경. 책·단어 등 여러 요청이 동시에 401을 받을 수 있어, 각 서비스가 따로 갱신하면 같은 refresh token을 중복 사용할 가능성. 요청 간 공유 상태를 한곳에서 관리하는 `actor` 선택.

## 처리 순서

1. `APIClient.data(for:)`에서 요청 실행. 401 응답이면서 Bearer 토큰이 있는 경우에만 갱신 시도.
2. `TokenRefreshCoordinator`가 실패한 토큰과 Keychain의 현재 토큰 비교. 다른 요청이 이미 토큰을 교체했다면 현재 토큰 반환.
3. 진행 중인 `refreshTask`가 있으면 같은 결과 대기. 없으면 `/api/auth/refresh` 요청을 수행하는 `Task` 생성.
4. 성공 응답의 refresh token을 먼저, access token을 다음으로 Keychain에 저장.
5. 원래 요청의 Authorization 헤더를 교체해 한 번 재시도. 재시도는 `URLSession`을 직접 호출해 갱신 루프 방지.
6. 갱신 성공·실패 모두 `refreshTask`를 비워 다음 요청이 완료된 작업을 계속 참조하지 않도록 처리.

`actor`만으로 네트워크 대기 중 중복 실행이 막히는 것은 아님. `await` 중 다른 호출이 들어올 수 있으므로, 진행 중인 `Task`를 저장하고 공유하는 처리가 함께 필요.

## 오류 처리 기준

| 상황 | 처리 |
| --- | --- |
| Authorization 헤더 없는 요청 | 갱신 없이 최초 응답 반환 |
| refresh token 없음·갱신 응답 4xx | 인증 오류 전달 |
| 갱신 응답 5xx·네트워크 오류 | 서버·네트워크 오류 전달 |
| 갱신 응답 형식 오류 | `invalidResponse` 전달 |
| 재시도 후 다시 401 | 추가 갱신 없이 각 서비스의 응답 검증으로 전달 |

토큰은 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` 조건으로 Keychain에 저장. 갱신 응답 두 값을 저장할 때 앱이 중단되는 상황을 고려해 refresh token부터 기록. 두 번의 Keychain 쓰기가 원자적 트랜잭션인 것은 아니며, 현재 저장 실패는 로그로만 처리.

## 확인할 시나리오와 보완점

아래는 검증 계획이며 자동화 테스트 통과 기록은 아님.

- 동일한 만료 토큰으로 여러 요청 실행 → 갱신 한 번을 공유하고 각 요청은 한 번씩 재시도.
- 앞선 요청이 토큰을 교체한 뒤 늦은 401 도착 → 추가 갱신 없이 새 토큰 사용.
- 갱신 실패 후 다시 요청 → 실패한 `Task`가 남아 있지 않은지 확인.
- 갱신 중 로그아웃·계정 전환 → 이전 세션의 응답이 토큰을 다시 저장하지 않는지 확인. 현재 세션 식별·갱신 취소 처리는 보완 필요.
- Keychain 저장 실패 → 메모리의 갱신 결과와 저장된 토큰 불일치 처리 보완.

현재 XCTest 타깃은 템플릿 수준. `URLSession`과 토큰 저장소를 주입할 수 있도록 정리한 뒤 동시 401과 세션 전환 회귀 테스트 추가 필요.

관련 코드: [APIClient.swift](../BookMate/Services/APIClient.swift), [TokenRefreshCoordinator.swift](../BookMate/Services/TokenRefreshCoordinator.swift), [AuthTokenStore.swift](../BookMate/Services/AuthTokenStore.swift).

[README로 돌아가기](../README.md)
