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

첫 설치 검사에서 Spring 플러그인 의존성 누락, bootstrap 모듈 로드 순서,
공식 릴리스 체크섬 파일명 가정 문제를 발견해 수정한 후 설치를 완료했다.

## 미검증 및 한계

- Linux/macOS CI는 파일만 추가했다. 이 작업에서 원격 CI를 실행하지 않았다.
- 로컬 Docker daemon이 실행 중이 아니어서 Linux 컨테이너 검증은 수행하지 못했다.
- macOS x86_64/Linux arm64 실행 미검증.
- Spring/JUnit/DAP 전체 실행 세션, GUI 키 입력, 실제 사용자 프로젝트의 모든 빌드 조합은 미검증.
- 고정 Spring 플러그인에서 `client.request` deprecated 경고가 관찰되지만 위 smoke는 통과했다.
- JDK 21 프로젝트를 사용하려면 실제 JDK 21 설치 및 필요 시 JAVA21_HOME 지정이 남아 있다.
