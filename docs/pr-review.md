# 코드 리뷰

PR은 코드 변경의 문제, 선택 이유, 실제 검증 결과를 기록한다. 기능 구현과 함께 테스트·빌드·리뷰 자동화도 변경 범위에 따라 별도 PR로 다룬다.

## PR 작성 기준

- 제목에는 변경 대상과 결과를 적는다.
- 본문에는 문제, 변경 이유, 검증 결과와 검토할 부분을 적는다.
- 실행하지 않은 테스트나 측정하지 않은 성능 개선은 완료로 쓰지 않는다.
- 상세 설계는 관련 문서로 연결한다.

## 자동 리뷰

PR-Agent 0.49.0을 GitHub Actions에서 실행한다. 일반 PR의 생성·재오픈·새 커밋에 한국어 리뷰를 게시한다. Draft PR과 외부 fork는 자동 실행하지 않는다. PR 본문 자동 작성과 자동 코드 수정은 실행하지 않는다.

모델 API 인증이 등록되고 설정이 main에 반영된 뒤, 저장소 OWNER·MEMBER·COLLABORATOR는 PR에 `/review`를 남겨 다시 실행할 수 있다.

워크플로는 PR 소스를 checkout하거나 실행하지 않고 GitHub API로 diff를 읽는다. 리뷰 결과는 오류 후보이며, 작성자는 재현과 테스트로 채택 여부를 판단한다. Swift 컴파일·XCTest·화면 동작 확인은 별도로 수행한다.

## 관리자 설정

1. Settings → Secrets and variables → Actions에 `OPENAI_KEY` Repository secret을 등록한다.
2. 기본 모델은 `gpt-6.1-sol`이다. 다른 OpenAI 모델은 Repository variable `PR_AGENT_MODEL`로 지정한다.
3. API 접근 권한과 사용 요금을 확인하고, 첫 리뷰의 결과와 실행 비용을 확인한다.

`GITHUB_TOKEN`은 GitHub가 워크플로에 발급한다. 모델 API 키와 역할이 다르다. 키를 소스나 PR 본문에 적지 않는다.

초기 설정 PR은 같은 저장소의 해당 브랜치에서 `.pr_agent.toml`을 읽는다. 댓글 실행은 기본 브랜치의 설정을 사용한다. Python 3.12와 PR-Agent 0.49.0을 사용하며 setup-python Action은 커밋 SHA로 고정한다.
