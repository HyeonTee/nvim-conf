## Keymaps

### 편집
- `+` / `-` : 숫자 증감
- `dw` : 커서 왼쪽 단어까지 일괄 삭제
- `<C-a>` : 전체 선택
- `<leader>i` : 점프리스트 forward (`<C-i>`)

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

### 자동완성 (blink.cmp)
- `<C-Space>` : 완성 메뉴 열기
- `<C-n>` / `<C-p>` 또는 방향키 : 다음/이전 항목
- `<Tab>` / `<S-Tab>` : 스니펫의 다음/이전 자리
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
