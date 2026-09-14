# 문제 해결

먼저 `bash scripts/doctor.sh`를 실행하고 FAIL 항목부터 해결한다.

## 시스템 nvim과 동작이 다름

`bash scripts/nvim.sh --version`과 `nvim --version`을 비교한다.
지원 기준은 `.nvim-version`의 고정 바이너리다. Homebrew nightly 업데이트와 함께 IDE 버전을 바꾸지 않는다.

## Java 도구 누락/초기화 실패

`bash scripts/bootstrap.sh` 후 Neovim을 재시작한다. Java 도구는 Mason이 아니라
`stdpath('data')/nvim-java/packages` 아래에서 nvim-java가 관리한다.
예전 `:MasonInstall vscode-spring-boot-tools@1.63.0`은 현재 Java 번들을 고치지 않는다.
`doctor`가 설치 디렉터리는 찾는데 초기화가 실패하면 다운로드 중단으로 불완전한 디렉터리인지 확인한다.
해당 **단일 패키지/버전 디렉터리만 다른 이름으로 이동해 보관**한 뒤 bootstrap을 다시 실행한다.
전체 Mason/nvim 데이터를 삭제하지 않는다.

## 프로젝트 JDK가 없거나 이름과 버전이 다름

`JAVA21_HOME/bin/java -version` 등을 확인한다. JavaSE-21에는 실제 JDK 21만 등록한다.
macOS `java_home -v 21`이 다른 버전을 반환할 수 있으므로 그 출력만 신뢰하지 않는다.
Homebrew의 JDK는 자동으로 시스템에 등록되지 않아도 실제 JDK 홈을 `JAVA21_HOME`에 지정하면 된다.
서버용 고정 JDK 25.0.3은 프로젝트 JDK를 대체하지 않는다.

## TypeScript 진단이 중복됨

`:lua =vim.lsp.get_clients({bufnr=0})`로 확인한다. 기본 구성에서는 ts_ls 하나만 있어야 한다.
과거 설치한 vtsls가 Mason에 남아 있어도 실행되지 않는다. local.lua나 프로젝트 설정의 별도 enable을 점검한다.

## Go import 정리가 안 됨

`:ConformInfo`에서 goimports를 확인한다. bootstrap이 버전까지 맞춰 설치한다.
gofmt만으로는 import 추가/삭제를 처리하지 않는다.

## Rust 서버 또는 표준 라이브러리 분석 실패

프로젝트 디렉터리에서 `rustup show active-toolchain`, `rustup which rust-analyzer`를 확인한다.
`rustup component add rust-analyzer rust-src rustfmt clippy`를 실행한다.
Mason에 남은 rust-analyzer는 사용하지 않는다. project override가 있으면 다른 프로젝트의 검사 결과와 달라질 수 있다.

## 완성 후보가 느리고 blink fuzzy 경고가 뜸

`No fuzzy matching library found!` 또는 `Falling back to Lua implementation`은 네이티브 fuzzy 라이브러리를
쓰지 못한다는 뜻이다. 기능은 동작하지만 정렬이 Lua 구현으로 폴백한다. 다음을 확인한다:

```sh
P="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/blink.cmp"
cat "$P/target/release/version"; git -C "$P" rev-parse HEAD
```

`version`은 **없거나 플러그인 HEAD와 같은 40자 sha**여야 한다. `v1.10.2`처럼 태그가 들어 있으면
예전 프리빌트 다운로드가 남긴 표시다. 이 구성은 프리빌트를 받지 않으므로 blink이 Lua로 폴백한다.
`bash scripts/bootstrap.sh`가 표시를 지우고 `cargo build --release`로 다시 빌드한다.
플러그인이 이미 고정 커밋이면 lazy는 build를 건너뛰므로, 수동으로 고칠 때는 `version`만 지우고 재빌드한다.
`target/` 전체나 플러그인 디렉터리를 삭제할 필요는 없다. `doctor`의 `Blink native library` 검사가 이 상태를 잡는다.

## tree-sitter 버전 불일치로 bootstrap이 중단됨

`Missing/incompatible prerequisite: tree-sitter <버전>`은 PATH에서 먼저 잡힌 CLI가 정책 버전과 다른 경우다.

```sh
which -a tree-sitter; tree-sitter --version
```

macOS에서 흔한 원인은 Homebrew다. `brew install neovim`이 tree-sitter를 의존성으로 함께 설치하고,
Homebrew stable은 고정 버전보다 앞서 나간다. `/opt/homebrew/bin`이 `~/.cargo/bin`보다 PATH에서 앞서면
정확한 버전을 cargo로 설치해도 Homebrew 것이 먼저 잡힌다. 셸 설정에서 `~/.cargo/bin`을 앞으로 옮기고
`lua/config/toolchain.lua`의 `treesitter_cli` 버전을 `cargo install tree-sitter-cli --version <버전> --locked`로 설치한다.
Homebrew의 tree-sitter는 neovim/cask의 의존성이므로 제거하지 않는다. 정책 버전을 PATH 사정에 맞춰 바꾸지 않는다.

## 고정 플러그인의 deprecated API 경고

`client.request is deprecated` 같은 경고는 대개 고정된 플러그인이 옛 LSP API를 쓰는 경우다.
저장소 설정이 원인인지 먼저 가른다:

```sh
grep -rn "client\.request(\|client\.supports_method(" lua/
git -C "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/<플러그인>" grep -n "client\.request("
```

플러그인이 원인이면 상류에 수정 커밋이 있는지 확인하고, 있으면 `lazy-lock.json`의 해당 커밋만 올린다.
핀을 올릴 때는 저장소가 쓰는 API(호환 계층이 덮어쓰는 함수, LSP 클라이언트 이름)가 유지되는지 확인하고
`bootstrap` → `doctor` → 해당 언어 smoke까지 실행한다. 경고를 숨기는 pcall이나 알림 필터로 덮지 않는다.

## 설치 네트워크 오류

bootstrap이 표시한 실패 패키지와 Neovim의 `:MasonLog`/`:messages`를 확인한다.
GitHub, npm/PyPI, Go 모듈 프록시, Eclipse, Open VSX, Oracle 접근이 필요하다.
폐쇄망에서는 승인된 미러/프록시 구성이 별도로 필요하다. 잠금을 최신 버전으로 풀어 우회하지 않는다.
