# 검증 기록 — 2026-09-13

## 확인한 환경

- macOS arm64, 저장소의 Neovim 0.12.1 공식 바이너리(SHA256 대조).
- 기존 사용자 데이터 환경과 별도 checkout/XDG config/data/state/cache 환경.
- Node 20.16.0, Go 1.25.5, Rust 1.87.0, tree-sitter CLI 0.26.11.
- 서버 JDK 25.0.3, Java smoke 프로젝트용 JDK 17.

## 결과

- 기존 설치의 누락된 goimports 및 rust-analyzer 컴포넌트 설치 성공.
- 비어 있던 IDE 데이터 환경에서 플러그인, Mason 도구, 파서, Java/Spring 번들 설치 완료.
- 설치 재실행 성공. 프로젝트 lazy-lock.json 원본 내용 유지.
- doctor: 실패 0, 경고 1 (현재 머신에 프로젝트용 JDK 21 없음).
- JDK major 불일치 거부, 서버 소유권, Lua 문법 회귀 검사 통과.
- TS/Go/Rust/Java 실제 LSP attach, 문서 심볼 응답, 실제 포맷 통과.
- Go의 누락된 fmt import 자동 추가 확인.
- Java 파일보다 application.yml을 먼저 열어도 Spring LS 초기화 성공.
- 별도 checkout에서 원래 ~/.config/nvim의 Lua 모듈을 읽지 않는지 검사 통과.
- Telescope/Blink 네이티브 라이브러리 로딩 및 parser revision/쿼리 검사 통과.

## 2026-09-14 (macOS arm64) 추가 검증

- blink.cmp를 로컬 빌드(`build = 'cargo build --release'`, 프리빌트 다운로드 비활성)로 전환.
  다운로드본이 남기는 태그 `version` 파일 때문에 평상시 실행에서 Lua로 폴백하던 문제를 제거했다.
  로컬 빌드는 `version`에 플러그인 HEAD sha를 남기므로, doctor는 `version` 부재 또는
  HEAD sha 일치를 검사한다(태그/옛 sha면 실패). bootstrap은 낡은 표시를 지우고 다시 빌드한다.
  이미 옛 설정으로 설치된 머신은 재bootstrap만으로 복구된다(깨끗한 XDG 및 태그 표시 상태 모두 검증).
- spring-boot.nvim 핀을 `218c0c26` → `eea95b75`로 갱신했다. 상류 `affc5d1`이 `client.request`를
  `client:request`로 고쳐 deprecated 경고가 사라지고, `eea95b75`(#31)가 기존 로컬
  executeClientCommand shim과 동일한 nil→vim.NIL 처리를 상류에 반영했다(shim은 그대로 유지).
- nvim-java가 쓰는 API(`setup{ls_path}`, `init_lsp_commands`), `util.java_bin` 패치 지점,
  클라이언트 이름 `spring-boot`, exploded LS jar 기동 경로가 새 버전에서도 유지됨을 확인했다.
- bootstrap 성공, doctor 실패 0/경고 0, 회귀 검사 통과, `NVIM_SMOKE_LANGS=java` smoke 통과.
- application.yml → Java 순서로 열어 `spring-boot`/`jdtls` attach 후 deprecated 메시지 0건 확인.
- 이 머신의 tree-sitter CLI가 Homebrew 0.26.9로 드리프트해 있어 정책 0.26.11을 cargo로 설치했다.
  Homebrew 경로가 PATH에서 앞서므로 검증은 `PATH="$HOME/.cargo/bin:$PATH"`로 실행했다.
  셸 설정은 변경하지 않았다.

첫 설치 검사에서 Spring 플러그인 의존성 누락, bootstrap 모듈 로드 순서,
공식 릴리스 체크섬 파일명 가정 문제를 발견해 수정한 후 설치를 완료했다.

## 미검증 및 한계

- Linux/macOS CI는 파일만 추가했다. 이 작업에서 원격 CI를 실행하지 않았다.
- 로컬 Docker daemon이 실행 중이 아니어서 Linux 컨테이너 검증은 수행하지 못했다.
- macOS x86_64/Linux arm64 실행 미검증.
- Spring/JUnit/DAP 전체 실행 세션, GUI 키 입력, 실제 사용자 프로젝트의 모든 빌드 조합은 미검증.
- JDK 21 프로젝트를 사용하려면 실제 JDK 21 설치 및 필요 시 JAVA21_HOME 지정이 남아 있다.
