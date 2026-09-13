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

## 설치 네트워크 오류

bootstrap이 표시한 실패 패키지와 Neovim의 `:MasonLog`/`:messages`를 확인한다.
GitHub, npm/PyPI, Go 모듈 프록시, Eclipse, Open VSX, Oracle 접근이 필요하다.
폐쇄망에서는 승인된 미러/프록시 구성이 별도로 필요하다. 잠금을 최신 버전으로 풀어 우회하지 않는다.
