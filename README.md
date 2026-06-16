개인 Neovim 설정. `~/.config/nvim` → 이 repo로 심볼릭 링크해서 사용.

Leader 키는 `Space`. 컬러스킴은 `catppuccin` (mocha, transparent).

## 설치

### 1. 시스템 의존성 (직접 설치)

`git clone` 만으로는 부족하다. 아래 패키지는 OS에 미리 있어야 한다 (clone에 포함되지 않음).

| 의존성 | 용도 | 비고 |
| --- | --- | --- |
| **Neovim 0.12+ (nightly)** | 필수 | nvim-treesitter `main` 브랜치가 0.12+ API(`vim.list` 등) 요구. 0.11.x 에서는 파서 설치 크래시 + 하이라이트 미작동 |
| **tree-sitter CLI** | 필수 | `main` 브랜치가 파서를 소스 컴파일. 라이브러리 formula `tree-sitter` 와는 별개 |
| **git** | 필수 | 플러그인/파서 clone |
| **ripgrep** | Telescope live grep | |
| **node** | 일부 LSP (`ts_ls` 등) | |
| **JDK 21+** | jdtls 런타임 | `java -version` 으로 확인. 프로젝트 자체는 다른 Java 버전이어도 됨 (필요 시 `lua/plugins/java.lua` 의 `settings.java.configuration.runtimes` 에 등록). Homebrew JDK 사용 시 jdtls 가 안 뜨면 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 참고 |
| **클립보드 도구** | `clipboard = unnamedplus` (시스템 클립보드 연동) | macOS 는 `pbcopy`/`pbpaste` 내장. **Linux 는 `xclip`/`xsel`(X11) 또는 `wl-clipboard`(Wayland) 설치 필요** |
| **C 컴파일러 + make** | telescope-fzf-native 빌드 | macOS: Xcode CLT. Linux: `build-essential` |
| **Nerd Font** | 아이콘 (lualine, neo-tree) | 설치 후 터미널 폰트로 지정 |

macOS (Homebrew) 한 방에 설치:

```bash
xcode-select --install                              # C 컴파일러 + make (이미 있으면 skip)
brew install neovim --HEAD tree-sitter-cli ripgrep node
brew install --cask font-jetbrains-mono-nerd-font   # Nerd Font (취향껏 다른 폰트도 OK)
# JDK 21+ 는 별도로 (예: brew install openjdk@21)
```

Ubuntu / Debian 한 방에 설치:

```bash
# Neovim 0.12+ (nightly) — apt 의 안정판은 보통 너무 낮음. PPA 또는 nightly 릴리스 사용
sudo add-apt-repository ppa:neovim-ppa/unstable && sudo apt update && sudo apt install neovim
# 빌드 도구 / ripgrep / node / 클립보드(X11 기준 xclip; Wayland 면 wl-clipboard)
sudo apt install build-essential git ripgrep nodejs xclip
# tree-sitter CLI — apt 패키지가 없거나 낮으면 cargo/npm 으로:
cargo install tree-sitter-cli        # 또는: npm install -g tree-sitter-cli
# JDK 21
sudo apt install openjdk-21-jdk
# Nerd Font 는 직접 내려받아 ~/.local/share/fonts 에 두고 fc-cache -f
```

> **Java 21 경로**: Spring Boot LS 는 Java 21 로 빌드돼 있어 OS 무관하게 Java 21 바이너리를 자동 탐지한다 (macOS `java_home`, Linux `/usr/lib/jvm` 스캔). 비표준 위치에 설치했다면 `SPRING_BOOT_JAVA_HOME`(또는 `JDTLS_JAVA_HOME`) 환경변수로 JDK 홈을 지정하면 된다.

### 2. 설정 가져오기

```bash
git clone <repo> ~/project/nvim-conf
ln -s ~/project/nvim-conf ~/.config/nvim
nvim
```

### 3. 자동으로 되는 것 (손 안 대도 됨)

첫 `nvim` 실행 시:

- **lazy.nvim** 이 자동 부트스트랩되며 플러그인 전부 설치
- **Mason** 이 LSP 서버 자동 설치 (`lua_ls`, `ts_ls`, `gopls`, `rust_analyzer`, `basedpyright`)
- **nvim-java** 가 Java 파일을 처음 열 때 jdtls·lombok·java-test·java-debug-adapter·spring-boot-tools 를 자체 mason 레지스트리로 자동 설치

→ Mason 패키지를 수동으로 깔 필요는 없다. 설치 완료 후 `:checkhealth` 로 환경을 점검하면 끝.

## 구조

```
init.lua                      진입점
lua/config/options.lua        옵션 (leader = Space, 기본값)
lua/config/keymaps.lua        키맵
lua/config/autocmds.lua       자동 명령
lua/config/lazy.lua           lazy.nvim 부트스트랩
lua/plugins/                  플러그인 정의
```

## 플러그인

- **lazy.nvim** — 플러그인 매니저 (`lua/config/lazy.lua`에서 부트스트랩)
- **catppuccin** — 컬러스킴 (mocha, transparent)
- **neo-tree** — 파일 탐색기
- **telescope** — 퍼지 검색
- **blink.cmp** — 자동완성
- **lualine** — 상태바
- **gitsigns** — Git diff 사이드 표시 / hunk 조작
- **nvim-treesitter** — 구문 하이라이트 + 언어별 인덴트
- **mason + nvim-lspconfig** — LSP 서버 설치/설정 관리
- **conform.nvim** — 저장 시 자동 포맷 (prettier, stylua, gofmt 등)
- **nvim-surround** — 따옴표/괄호 등 감싸기·바꾸기·삭제 (`ys`, `cs`, `ds`). 비주얼 모드에서 `(`, `[`, `{` 로 즉시 감싸기 가능
- **nvim-autopairs** — 괄호/따옴표 자동 짝 입력 (treesitter 인지)
- **indent-blankline.nvim** — 인덴트 단계마다 세로 가이드 선
- **rainbow-delimiters.nvim** — 중첩 괄호를 깊이별로 다른 색으로 표시
- **which-key.nvim** — 리더키 누르고 잠시 멈추면 사용 가능한 매핑 팝업
- **toggleterm.nvim** — 통합 터미널. `<C-\>` 로 플로팅 터미널 토글, 가로/세로 분할, lazygit 연동
- **flash.nvim** — 화면 어디든 두 글자로 점프 (`s`, `S`)
- **nvim-treesitter-textobjects** — 함수/클래스/인자 단위 선택·이동·편집
- **aerial.nvim** — 심볼 아웃라인 사이드바 (클래스/메서드 구조 트리, LSP `documentSymbol` 기반)
- **render-markdown.nvim** — 마크다운 버퍼 안에서 헤딩/코드블럭/체크박스/테이블 렌더링
- **nvim-java** — Java/Spring 올인원. jdtls·lombok·java-test·java-debug-adapter·spring-boot.nvim 을 자체 번들/mason 레지스트리로 관리 (이전 `nvim-jdtls` 수동 와이어업 대체)
- **spring-boot.nvim** — Spring Boot LSP(STS4) 통합 (bean 점프, `application.yml/properties` 자동완성). nvim-java 가 번들
- **nvim-dap** + **nvim-dap-ui** + **nvim-dap-virtual-text** — 디버거 (Spring Boot / JUnit)

### LSP 서버 (Mason 자동 설치)

`lua_ls`, `ts_ls`, `gopls`, `rust_analyzer`, `basedpyright`

> `jdtls` 는 여기 `ensure_installed` 에 없다 — **nvim-java** 가 자체 mason 레지스트리(`github:nvim-java/mason-registry`)로 설치하고 `require("java").setup()` + `vim.lsp.enable("jdtls")` 로 직접 활성화한다. 이중 setup 충돌을 막기 위해 mason-lspconfig 의 `automatic_enable.exclude` 로 jdtls 를 제외한다.

### Java 툴체인 (nvim-java 자동 설치)

`jdtls`, `lombok`, `java-debug-adapter`, `java-test`, `vscode-spring-boot-tools` (STS4, `1.63.0` 핀)

> nvim-java 의 mason 레지스트리를 mason 코어 레지스트리보다 **먼저** 등록해 버전을 우선시킨다 (`lua/plugins/lsp.lua` 의 `registries`).
>
> Java 포맷은 별도 외부 포매터 대신 **jdtls 자체 포맷**(Eclipse 표준, 4칸 스페이스) 을 사용 — 저장 시 conform 의 `lsp_format = "fallback"` 흐름으로 처리됨.

## 유지보수

- `:Lazy` — 플러그인 상태 보기
- `:Lazy sync` / `:Lazy update` — 플러그인 설치/업데이트
- `:Mason` — LSP/포매터/린터 바이너리 관리
- `:checkhealth` — 환경 점검 (의존성, 설정 문제 진단)
- 문제 해결: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Keymaps

### 편집
- `+` / `-` : 숫자 증감
- `dw` : 커서 왼쪽 단어까지 일괄 삭제
- `<C-a>` : 전체 선택
- `<C-m>` : 점프리스트 forward (`<C-i>`)

### 화면 분할
- `ss` : 수평 분할
- `sv` : 수직 분할
- `sh` / `sj` / `sk` / `sl` : 분할 이동
- `<C-w>` + 방향키 : 분할 크기 조정

### 탭
- `te` : 새 탭
- `<Tab>` / `<S-Tab>` : 탭 이동

### 진단
- `<C-j>` : 다음 진단 위치로 점프

### 파일 탐색
- `<leader>e` : Neo-tree 토글
- 트리 안에서 `l` / `h` : 폴더 열기 / 닫기
- `nvim .` (또는 디렉토리 인자) 로 시작하면 Neo-tree 가 자동으로 사이드바에 열림 (netrw 비활성화)

### 심볼 아웃라인 (aerial)
- `<leader>o` : 아웃라인 사이드바 토글 (현재 파일의 클래스/메서드 구조 트리)
- 사이드바 안에서 `<CR>` 점프 / `p` 미리보기 / `{` `}` 이전·다음 심볼 / `q` 닫기

> 긴 Java 클래스의 구조 파악·메서드 간 점프에 유용. LSP(jdtls `documentSymbol`) 우선, 없으면 treesitter 폴백.

### LSP
- `gd` : 정의로 이동
- `gD` : 선언으로 이동
- `gr` : 참조 찾기
- `gi` : 구현 찾기
- `K` : 호버 문서
- `<leader>rn` : 이름 변경
- `<leader>ca` : 코드 액션
- `<leader>f` : 포맷
- `<leader>uh` : inlay hints 토글 (파라미터 이름·추론 타입 인라인 표시. 서버 지원 시 기본 ON, 버퍼별 토글)

> inlay hints 는 지원하는 모든 LSP(Java·TS·Go·Rust·Python 등)에 적용된다. Java(jdtls)는 메서드 인자에 파라미터 이름을 함께 표시한다.

### 자동완성 (blink.cmp)
- `<C-Space>` : 완성 메뉴 열기
- `<Tab>` / `<S-Tab>` : 다음/이전 항목
- `<CR>` : 선택 항목 확정
- `<C-e>` : 메뉴 닫기

### Telescope (퍼지 검색)
- `;f` : 파일 검색 (hidden 포함)
- `;r` : Live grep (ripgrep 필요)
- `;b` : 버퍼 목록
- `;o` : 최근 연 파일
- `;t` : 도움말 검색
- `;;` : 직전 picker 재개
- `;e` : 진단 목록
- `;s` : 문서 심볼 (LSP)

### Git (gitsigns)
- `]c` / `[c` : 다음/이전 hunk
- `<leader>hs` : Stage hunk (다시 누르면 unstage)
- `<leader>hr` : Reset hunk
- `<leader>hS` : 버퍼 전체 stage
- `<leader>hp` : Hunk 미리보기
- `<leader>hb` : 줄 blame
- `<leader>hd` : Diff vs index

### 감싸기 (nvim-surround)
- Normal: `ys{motion}{char}` — 감싸기 (예: `ysiw)` → 단어를 `()` 로)
- Normal: `cs{old}{new}` — 바꾸기 (예: `cs"'` → `"` → `'`)
- Normal: `ds{char}` — 삭제 (예: `ds(` → `()` 제거)
- Visual: 선택 후 `(` / `[` / `{` — 해당 괄호로 즉시 감싸기

### Flash (점프)
- `s` + 글자 1~2개 + 라벨 : 화면 어디든 점프
- `S` : Treesitter 노드(함수/블록 등) 단위로 점프
- 오퍼레이터와 조합: `ds<글자><라벨>`(삭제), `ys<글자><라벨>`(복사), `vs<글자><라벨>`(선택)

### Treesitter 텍스트 객체
| 키 | 동작 |
| --- | --- |
| `if` / `af` | 함수 안 / 함수 통째로 |
| `ic` / `ac` | 클래스 안 / 클래스 통째로 |
| `ia` / `aa` | 인자 안 / 인자 통째로 |
| `]f` / `[f` | 다음/이전 함수로 점프 |
| `]]` / `[[` | 다음/이전 클래스로 점프 |

오퍼레이터와 조합 예: `vif`(함수 선택), `daf`(함수 삭제), `caf`(함수 변경), `yaf`(함수 복사).

### 마크다운 (render-markdown)
- `<leader>um` : 렌더링 토글 (마크다운 파일에서만)

### Java (nvim-java)
- `<leader>jo` : import 정리
- `<leader>jv` : 변수 추출 (visual 모드 가능)
- `<leader>jc` : 상수 추출 (visual 모드 가능)
- `<leader>jm` : 메서드 추출 (visual 모드)
- `<leader>jt` : 현재 클래스 테스트 실행
- `<leader>jn` : 커서 위치 메서드 테스트 실행
- `<leader>jr` : main 클래스 실행

> 첫 실행 시 jdtls 가 프로젝트를 인덱싱하느라 1~수분 걸릴 수 있음.

### 디버그 (nvim-dap)
- `<leader>db` : 브레이크포인트 토글
- `<leader>dc` : 계속 / 디버그 시작
- `<leader>di` : step into
- `<leader>do` : step over
- `<leader>dO` : step out
- `<leader>dt` : 디버그 종료
- `<leader>du` : DAP UI 토글

### 터미널 (toggleterm)
- `<C-\>` : 플로팅 터미널 토글 (어디서든)
- `<leader>th` : 가로 분할 터미널
- `<leader>tv` : 세로 분할 터미널
- `<leader>tg` : lazygit (별도 설치 필요: `brew install lazygit`)
- `<C-\>` 앞에 숫자를 붙이면 번호별 터미널 (`2<C-\>` → 2번 터미널)

터미널 모드(입력 중) 단축키 — `:term` 등 모든 터미널에 공통 적용:
- `<Esc>` : 노멀 모드로 빠져나오기 (스크롤·복사 가능)
- `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` : 다른 창으로 이동
- 터미널 창은 줄번호가 꺼지고 진입 시 자동으로 입력 모드가 됨

### which-key
별도 매핑 없음. `Space`(리더) 또는 `g`, `]`, `[` 등을 누르고 잠시 멈추면 사용 가능한 후속 매핑이 팝업으로 자동 표시됩니다.
