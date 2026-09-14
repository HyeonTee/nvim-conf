# 이 저장소를 수정하는 에이전트에게

목표: macOS/Linux에서 Java/Spring, Go, Rust, TypeScript IDE를 재현한다.
README.md와 docs/toolchain.md를 먼저 읽고 설치 담당/버전 원본을 유지한다.
증상을 진단할 때는 TROUBLESHOOTING.md의 알려진 실패 유형과 진단 명령을 먼저 확인한다.

- 사용자 변경을 보존한다. 특히 lazy-lock.json의 기존 변경을 임의로 되돌리지 않는다.
- 머신별 절대 경로는 공통 설정에 넣지 않는다. 환경변수 또는 Git 제외 local.lua를 사용한다.
- LSP는 명시적인 허용 목록만 활성화한다. ensure_installed가 실행 허용 목록이라고 가정하지 않는다.
- Java는 nvim-java, Rust는 rustup, 나머지 명시한 도구는 Mason이 관리한다. 중복 설치 담당을 만들지 않는다.
- JDK 경로는 실행 파일과 실제 major를 검증한다. 서버 실행 JDK와 프로젝트 JDK를 혼동하지 않는다.
- 직접 도구 버전은 toolchain.lua, Neovim은 .nvim-version, 플러그인은 lazy-lock.json에서 변경한다.
- Neovim 버전을 바꾸면 checksums/의 플랫폼별 공식 SHA256도 함께 갱신한다.
- 새 도구를 추가하면 설치 정책, doctor 검사, 문서도 함께 수정한다.
- 일반 Neovim 시작 중 자동 업데이트/도구 다운로드를 추가하지 않는다.
- 누락된 플러그인/서버를 숨기는 pcall로 테스트를 통과시키지 않는다. doctor는 누락/불일치에 실패해야 한다.
- bootstrap은 반복 가능해야 하고 실패를 종료 코드로 전달해야 한다. 캐시 전체 삭제, 시스템 패키지/셸 설정의 자동 변경은 하지 않는다.
- 비공개 키/토큰/머신별 환경 전체를 로그에 출력하지 않는다.
- 변경 후 `bash scripts/test.sh`, 관련 언어의 `bash scripts/test.sh --smoke`, `bash scripts/doctor.sh`를 실행한다.
- bootstrap/다운로드 변경 시 깨끗한 XDG 환경 및 재실행을 검증한다. 플랫폼 CI 실행 여부를 구분해 기록한다.
- Lua는 stylua.toml 기준으로 포맷한다. fixtures는 포맷 검사용으로 의도적으로 정렬하지 않았다.
- README, troubleshooting에 옛 설치 경로나 작동하지 않는 API 설명을 남기지 않는다.
- 테스트로 확인한 범위와 미검증 범위를 구분한다. CI 파일을 추가한 것을 CI 통과라고 보고하지 않는다.
