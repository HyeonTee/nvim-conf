# 개인 Neovim IDE

Java/Spring, Go, Rust, TypeScript 중심 설정. macOS 및 glibc Linux의 arm64/x86_64를 대상으로 한다.
Neovim은 `.nvim-version`, 플러그인은 `lazy-lock.json`, 외부 도구는 `lua/config/toolchain.lua`로 관리한다.
매번 최신화하지 않고 **명시적인 bootstrap으로 설치·버전을 맞춘다.**

## 새 컴퓨터 설치

먼저 시스템 의존성을 설치한다. 스크립트는 sudo, 시스템 패키지 관리자, 셸 설정을 자동 변경하지 않는다.

| 의존성 | 용도 |
| --- | --- |
| git, curl, tar, unzip, C 컴파일러, make | 플러그인과 Treesitter 빌드 |
| Node 20 이상 + npm | TypeScript/ESLint/Prettier 실행 |
| Go 1.25 이상 | gopls/goimports 설치·프로젝트 분석. 필요한 빌드 툴체인을 Go가 추가 다운로드할 수 있음 |
| rustup + Rust 툴체인 | 프로젝트와 같은 rust-analyzer/rustfmt/Clippy 사용. cargo로 blink.cmp fuzzy 라이브러리 빌드 |
| tree-sitter CLI **0.26.11** | 파서 빌드. npm 패키지는 사용하지 않음 |
| ripgrep, fd | 검색 및 Python 가상환경 검색 |
| Python 3 + venv/pip | 유지 중인 Python LSP 설치 |
| 프로젝트용 JDK | Java 17/21/25 중 프로젝트에 맞는 버전. 서버 실행용 JDK와 별개 |
| Nerd Font | 터미널 아이콘. 터미널에서 별도 선택 |

macOS 기본 패키지 예시:

```sh
xcode-select --install  # 이미 설치돼 있으면 생략
brew install git curl node go rustup ripgrep fd python openjdk@21
rustup toolchain install stable
cargo install tree-sitter-cli --version 0.26.11 --locked
```

Ubuntu/Debian 기본 패키지 예시:

```sh
sudo apt-get update
sudo apt-get install build-essential git curl tar unzip ripgrep fd-find python3-venv python3-pip openjdk-21-jdk
# Node/npm, Go, rustup은 위 요구사항에 맞게 각 공식 배포판/기존 버전 관리자로 설치.
# 배포판에 fd 대신 fdfind만 있다면 PATH에 fd -> fdfind 링크를 준비.
cargo install tree-sitter-cli --version 0.26.11 --locked
```

`cargo install` 경로가 PATH에 있어야 한다. 다른 tree-sitter가 먼저 잡히면 bootstrap이 버전 불일치로 중단한다.
Linux 데스크톱 클립보드는 Wayland의 `wl-clipboard`, X11의 `xclip`/`xsel`이 필요하다.
Alpine/musl, Windows, 원격 서버의 데스크톱 클립보드는 지원 범위에 포함하지 않는다.

이 저장소를 원하는 위치에 clone하고 실행한다:

```sh
bash scripts/bootstrap.sh
bash scripts/doctor.sh
bash scripts/test.sh --smoke
bash scripts/nvim.sh .
```

`scripts/nvim.sh`는 현재 프로젝트 디렉터리를 유지하고 저장소의 고정 Neovim과 설정을 사용한다.
시스템 `nvim`은 그대로 둔다. 자주 쓰려면 셸에 `alias nvim='bash /실제/저장소/scripts/nvim.sh'`를 직접 추가한다.
기존 `~/.config/nvim`에 clone한 경우에도 버전 재현을 위해 이 실행기를 사용한다.

bootstrap은 공식 Neovim 아카이브를 저장소의 고정 SHA256과 비교해 `.tools/`에 설치하고, 플러그인 커밋을 복원한다.
누락되거나 버전이 다른 Mason 도구는 정책 버전으로 설치한다(다운그레이드 포함).
Rust 컴포넌트는 현재 활성 툴체인에 추가하고, 파서 및 Java 번들을 준비한다.
기존 Mason의 다른 패키지는 삭제하지 않으며 LSP 허용 목록 밖이면 자동 활성화하지 않는다.
다운로드가 중단되면 오류를 수정하고 다시 실행한다. 실행 중인 Neovim은 설치 완료 후 재시작한다.

## 프로젝트와 머신별 설정

`lua/config/local.lua.example`을 `lua/config/local.lua`로 복사해 `JAVA21_HOME` 등을 지정할 수 있다.
로컬 파일은 Git에서 제외된다. 환경변수로 지정해도 동일하다. 다른 major의 JDK를 지정하면 실패한다.
JDK가 없으면 임의의 다른 버전을 JavaSE-21로 등록하지 않는다.

프로젝트에는 `.editorconfig`, Prettier/ESLint 설정, `rust-toolchain.toml`, `rustfmt.toml`,
`go.mod`/`go.work`, Maven/Gradle wrapper 및 Java toolchain 설정을 커밋한다.
Rust 버전을 바꾸면 해당 프로젝트에서 `rustup component add rust-analyzer rust-src rustfmt clippy`도 실행한다.
프로젝트 로컬 Prettier/TypeScript가 있으면 해당 프로젝트 버전이 우선할 수 있으므로 프로젝트 lockfile도 필요하다.

## 지원하는 기능

| 언어 | 분석·완성 | 포맷/import | 실행·디버그 |
| --- | --- | --- | --- |
| Java/Spring | nvim-java + jdtls + Spring LS | jdtls 포맷, `<leader>jo` import 정리 | Java 테스트·DAP 키맵 |
| Go | gopls | goimports로 저장 시 포맷/import 정리 | 터미널의 go test/go run |
| Rust | rustup의 rust-analyzer, Clippy | 프로젝트 rustfmt | 터미널의 cargo test/cargo run |
| TS/TSX | ts_ls 하나 + 프로젝트 ESLint | Prettier, LSP code action | 프로젝트 npm/pnpm 명령 |

Go/Rust/TypeScript의 DAP 어댑터는 아직 기본 구성에 포함하지 않는다.
Neovim 내부 테스트 러너/디버거가 필요한 경우 별도로 검증해 추가한다.
Python·Lua 및 기존 편집 플러그인은 유지한다.

기존 포커스/버퍼 이탈 자동 저장과 저장 시 포맷은 유지된다. [키맵 전체](docs/keymaps.md).
`Space e`: 파일 트리, `;f`: 파일 검색, `;r`: 본문 검색, `Space f`: 포맷, `Space o`: 심볼 목록.

## 유지보수

`doctor`는 버전, 누락 도구, JDK 불일치, LSP 중복, 파서/쿼리를 확인하고 실패 시 종료 코드 1을 반환한다.
도구를 설치하거나 업데이트하지 않는다. 캐시/로그는 Neovim 기본 디렉터리를 사용할 수 있다.
`test.sh`는 회귀 검사, `test.sh --smoke`는 실제 LSP 연결·심볼 응답·포맷 및 Spring LS 초기화를 검사한다.
smoke는 샘플 프로젝트의 캐시/의존성을 생성할 수 있으며 첫 Java 분석에는 시간이 걸린다.
`NVIM_SMOKE_LANGS=go,rust bash scripts/test.sh --smoke`처럼 언어를 선택할 수 있다.

업데이트 정책과 검증 범위는 [toolchain 문서](docs/toolchain.md), 문제 해결은 [TROUBLESHOOTING.md](TROUBLESHOOTING.md),
AI 에이전트의 변경 규칙은 [AGENTS.md](AGENTS.md)를 따른다.
실제로 확인한 플랫폼과 미검증 범위는 [검증 기록](docs/verification.md)에 남긴다.
