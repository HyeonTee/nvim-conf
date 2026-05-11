개인 Neovim 설정. `~/.config/nvim` → 이 repo로 심볼릭 링크해서 사용.

Leader 키는 `Space`. 컬러스킴은 `solarized-osaka` (transparent).

## 사전 요구사항

- Neovim 0.11 이상
- `git`
- `ripgrep` — Telescope live grep용
- `node` — 일부 LSP 서버 (`ts_ls` 등)
- Nerd Font — 아이콘 표시 (lualine, neo-tree)

## 설치

```bash
git clone <repo> ~/project/nvim-conf
ln -s ~/project/nvim-conf ~/.config/nvim
nvim
```

첫 실행 시 `lazy.nvim`이 자동으로 부트스트랩되며 플러그인을 설치한다.

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
- **solarized-osaka** — 컬러스킴
- **neo-tree** — 파일 탐색기
- **telescope** — 퍼지 검색
- **blink.cmp** — 자동완성
- **lualine** — 상태바
- **gitsigns** — Git diff 사이드 표시 / hunk 조작
- **nvim-treesitter** — 구문 하이라이트 + 언어별 인덴트
- **mason + nvim-lspconfig** — LSP 서버 설치/설정 관리
- **conform.nvim** — 저장 시 자동 포맷 (prettier, stylua, gofmt 등)
- **nvim-surround** — 따옴표/괄호 등 감싸기·바꾸기·삭제 (`ys`, `cs`, `ds`)
- **nvim-autopairs** — 괄호/따옴표 자동 짝 입력 (treesitter 인지)
- **indent-blankline.nvim** — 인덴트 단계마다 세로 가이드 선
- **rainbow-delimiters.nvim** — 중첩 괄호를 깊이별로 다른 색으로 표시
- **which-key.nvim** — 리더키 누르고 잠시 멈추면 사용 가능한 매핑 팝업
- **flash.nvim** — 화면 어디든 두 글자로 점프 (`s`, `S`)
- **nvim-treesitter-textobjects** — 함수/클래스/인자 단위 선택·이동·편집
- **render-markdown.nvim** — 마크다운 버퍼 안에서 헤딩/코드블럭/체크박스/테이블 렌더링

### LSP 서버 (Mason 자동 설치)

`lua_ls`, `ts_ls`, `gopls`, `rust_analyzer`, `basedpyright`

## 유지보수

- `:Lazy` — 플러그인 상태 보기
- `:Lazy sync` / `:Lazy update` — 플러그인 설치/업데이트
- `:Mason` — LSP/포매터/린터 바이너리 관리
- `:checkhealth` — 환경 점검 (의존성, 설정 문제 진단)

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

### LSP
- `gd` : 정의로 이동
- `gD` : 선언으로 이동
- `gr` : 참조 찾기
- `gi` : 구현 찾기
- `K` : 호버 문서
- `<leader>rn` : 이름 변경
- `<leader>ca` : 코드 액션
- `<leader>f` : 포맷

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

### which-key
별도 매핑 없음. `Space`(리더) 또는 `g`, `]`, `[` 등을 누르고 잠시 멈추면 사용 가능한 후속 매핑이 팝업으로 자동 표시됩니다.
