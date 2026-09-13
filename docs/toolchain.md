# 도구 소유권과 버전 정책

버전의 단일 원본은 `.nvim-version`, `lazy-lock.json`, `lua/config/toolchain.lua`다.
Neovim 아카이브 SHA256은 공식 GitHub Release API의 asset digest를 `checksums/`에 기록했다.
Neovim 버전을 바꿀 때 네 플랫폼의 digest도 함께 갱신한다.
플러그인 커밋은 사용자가 기존에 업데이트한 lockfile을 기준으로 유지한다.

| 대상 | 설치 담당 | 기준 |
| --- | --- | --- |
| Neovim | bootstrap 공식 아카이브 + 체크섬 | `.nvim-version` |
| 플러그인 및 parser revision 목록 | lazy.nvim | `lazy-lock.json` |
| 파서 | nvim-treesitter의 install/update | 고정 플러그인의 parser revision |
| LSP/포매터 | Mason, bootstrap만 버전 정합화 | `toolchain.mason` |
| bundled TypeScript | bootstrap npm | `toolchain.typescript` |
| Java 번들 | nvim-java | `toolchain.java` |
| Java 서버 JDK | nvim-java + config.java의 고정 archive spec | 25.0.3, latest URL 사용 금지 |
| Rust 분석/포맷/Clippy | rustup | 프로젝트 활성 toolchain |
| 프로젝트 컴파일러/포맷 설정 | 프로젝트 | 각 프로젝트의 toolchain/lock/config |

일반 실행에서는 플러그인 검사·Mason 도구 설치·파서 다운로드를 시작하지 않는다.
Java 최초 실행도 사전 설치된 경로를 사용한다. 누락된 환경은 bootstrap으로 복구한다.
언어 서버의 프로젝트 의존성 다운로드/인덱싱까지 금지하는 오프라인 모드는 아니다.

Java의 JDK archive spec과 Spring 실행 바이너리 연결은 고정 플러그인 API에 대한 작은 호환 계층이다.
이 플러그인 업데이트 시 config.java, executeClientCommand 응답, bootstrap, Spring smoke를 함께 확인한다.
서버용 JDK 25.0.3과 프로젝트용 JDK 17/21/25는 다른 설정이며 프로젝트용 major만 검증한다.

## 업데이트 절차

1. 별도 브랜치에서 필요한 플러그인만 업데이트하고 lazy-lock diff를 확인한다.
2. 외부 도구 변경이 필요하면 toolchain.lua의 정확한 버전을 수정한다.
3. bootstrap 후 doctor, 회귀 검사, 네 언어 smoke를 실행한다.
4. macOS/Linux CI를 확인한다. 실패하거나 실행하지 못한 환경은 명시한다.
5. 새 머신 또는 비어 있는 XDG 데이터 디렉터리에서도 설치를 검증한다.

bootstrap은 기존 외부 도구의 버전이 다르면 정책 버전으로 되돌릴 수 있다. 실행 전 Neovim을 닫는다.
일반 편집 중 `:Lazy update`/`:MasonUpdate`로 전체 IDE를 업데이트하지 않는다.
과거 버전으로 돌아갈 때도 해당 Git revision에서 bootstrap을 다시 실행한다.

## 재현성의 경계

OS/CPU에 따른 바이너리는 다르며, 시스템 라이브러리·프로젝트 의존성·폰트·터미널까지 동일하게 만들지는 않는다.
Mason 레지스트리의 설치 recipe와 npm/PyPI 전이 의존성은 upstream 변경 가능성이 있다.
완전한 hermetic/offline 배포가 필요하면 OS별 아티팩트 미러와 전이 의존성 lock도 추가해야 한다.
현재는 주요 직접 도구 버전과 활성화 정책을 고정하고 실제 검사로 편차를 탐지한다.

CI 대상은 Ubuntu 24.04 x86_64, macOS 14 arm64다. macOS x86_64/Linux arm64용 다운로드 분기는 제공하지만,
해당 아키텍처에서 CI를 실행한 것으로 간주하지 않는다.
smoke는 LSP attach, documentSymbol 응답, 실제 포맷, Spring LS 초기화를 검사한다.
전체 Spring 빌드/JUnit/DAP 세션, GUI 키 입력과 모든 프로젝트 조합은 이 검사만으로 보장하지 않는다.
