# PR 자동 리뷰 사용

PR-Agent 0.49.0을 GitHub Actions에서 실행한다. iOS 앱의 빌드·배포와 별개다.

## 모델 인증 등록

1. 저장소 Settings → Secrets and variables → Actions에서 `OPENAI_KEY`라는 Repository secret을 추가한다.
2. 기본 모델은 PR-Agent 기본값과 같은 `gpt-6.1-sol`이다. 다른 OpenAI 모델을 사용하려면 Repository variable `PR_AGENT_MODEL`을 지정한다. 모델 접근 권한과 API 사용 요금을 확인한다.
3. 이 설정을 main에 반영한다. 이후 같은 저장소의 일반 PR 생성·재오픈·커밋 추가 때 리뷰한다. Draft PR은 자동 실행하지 않는다.
4. 키 등록 후 이 설정 PR을 Ready for review로 바꾸면 첫 리뷰를 실행할 수 있다. API 키가 없으면 명시적인 실패로 끝난다.

키는 소스나 PR 본문에 적지 않는다. GitHub가 생성하는 `GITHUB_TOKEN`은 워크플로가 PR을 읽고 리뷰를 게시하는 데 사용한다. 모델 API 인증과는 역할이 다르다.

## 리뷰 실행

- 같은 저장소의 일반 PR: 생성과 새 커밋에 자동 실행한다.
- main에 워크플로가 반영된 뒤: 저장소 OWNER·MEMBER·COLLABORATOR가 PR에 `/review`를 남겨 다시 실행할 수 있다.
- 외부 fork의 PR은 자동 리뷰하지 않는다. 수동 `/review`는 위 권한을 가진 작성자만 실행할 수 있다.
- PR 본문 자동 작성과 자동 코드 수정은 기본 자동 동작에 포함하지 않는다.

워크플로는 Python 3.12와 PR-Agent 0.49.0을 사용하고, setup-python Action은 커밋 SHA로 고정한다. PR 코드를 checkout하거나 실행하지 않는다. `.pr_agent.toml`은 초기 설정 PR에서 같은 저장소의 해당 브랜치를 읽고, 댓글 실행에서는 기본 브랜치를 읽는다.

## 사람이 확인할 내용

리뷰에서 지적한 조건을 재현하고, 실제 문제인지 판단한 뒤 수정한다. AI 리뷰는 Swift 컴파일, XCTest, 실제 화면 동작 확인을 대신하지 않는다. 실행하지 않은 검증을 PR 본문에 완료로 표시하지 않는다.

PR 본문에는 문제, 변경 이유, 실제 검증 결과와 검토할 부분을 적는다. 긴 전후 학습 설명은 별도 문서로 연결한다.

## 환경과 브랜치 관리

개발·학습용 Run은 Debug를 사용한다. 현재 북메이트의 Debug API 환경은 local이다. 서버가 없다면 API 기능은 동작하지 않으므로, 학습 기능은 메모리 저장소 또는 전용 테스트 저장소로 실행한다. Release의 production은 실제 출시용으로 유지한다.

Run의 Debug 전환만으로 Firebase·카카오·푸시·Keychain·UserDefaults까지 격리되는 것은 아니다. 학습용 진입점과 별도 Bundle ID·저장소를 함께 설계한다. 이 PR은 실행 환경을 변경하지 않는다.

변경 목적별로 main에서 새 브랜치를 만든다.

- `codex/setup-pr-agent`: 리뷰 설정과 PR 템플릿
- `chore/learning-environment`: 학습 실행 환경 분리
- `refactor/recent-search-history`: 최근 검색어 책임 분리

환경 분리 설정과 학습 코드는 커밋한다. API 키와 개인 실행 데이터는 커밋하지 않는다. 커밋은 변경 기록, push는 GitHub 전송, merge는 기준 코드 반영, App Store 배포는 별도 작업이다. 현재 저장소의 배포 자동화가 추가된다면 해당 트리거도 확인한다.

단순 실험은 브랜치에 커밋해 기록할 수 있고 main에 병합할 필요는 없다. 환경 분리가 main에 반영되면 새 리팩토링 브랜치는 그 main에서 시작한다. 두 기능을 한꺼번에 담는 장기 브랜치는 피한다.
