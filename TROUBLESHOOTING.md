# 트러블슈팅

설정 사용 중 겪은 문제와 해결법 모음. 새 머신 세팅 시 참고.

## jdtls / spring-boot 가 안 뜸 (exit code 13)

**증상**

- java 파일을 열어도 LSP(jdtls)가 attach 되지 않음
- spring-boot 기능(bean 점프, `application.yml` 자동완성)도 동작 안 함
- jdtls 로그/`:checkhealth` 에 `exit code 13` 비슷한 메시지

**원인**

jdtls 는 **Java 21+ 로 부팅**되어야 한다 (프로젝트 자체 JDK 와는 별개). `ftplugin/java.lua`
는 jdtls 부팅용 java 를 아래 우선순위로 찾는다:

1. `JDTLS_JAVA_HOME` 환경변수
2. macOS: `/usr/libexec/java_home -v 21` 결과
3. `JAVA_HOME`
4. PATH 의 `java` (최후 폴백)

Homebrew 로 `openjdk@21` 을 설치하면 `/opt/homebrew/opt/openjdk@21` 에는 깔리지만
**Apple 의 `/Library/Java/JavaVirtualMachines/` 에는 자동 등록되지 않는다.** 그러면:

- `/usr/libexec/java_home -v 21` 가 21 을 못 찾고 실패 (등록된 건 17 같은 구버전뿐)
- 폴백이 PATH 의 `java`(예: 17) 를 잡음
- jdtls 가 Java 버전 부족으로 **exit code 13** 으로 종료

`/usr/libexec/java_home` 이 말하는 버전과 실제 Homebrew 설치 버전이 다른 게 핵심.

**확인**

```bash
/usr/libexec/java_home -v 21   # 21 경로가 나와야 정상. 실패하면 이 문제
ls /Library/Java/JavaVirtualMachines/   # 21 이 등록돼 있는지
ls -d /opt/homebrew/opt/openjdk@21       # Homebrew 21 설치 여부
```

**해결 (둘 중 하나)**

방법 A — Homebrew JDK 를 시스템에 등록 (권장, sudo 필요). java_home 에 잡히면
jdtls 뿐 아니라 gradle/maven/터미널 전부 21 을 쓰게 된다:

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-21.jdk
/usr/libexec/java_home -v 21   # 이제 경로가 나와야 함
```

방법 B — jdtls 전용 env 변수 (sudo 없이). 시스템은 그대로 두고 jdtls 만 21 로 띄움:

```bash
# ~/.zshrc 에 추가
export JDTLS_JAVA_HOME=/opt/homebrew/opt/openjdk@21
```

적용 후 nvim 에서 `:e` 로 java 파일을 다시 열면 jdtls 가 새 java 로 재시작된다.

## 회사에선 되는데 git pull 받은 머신에서 spring-boot 만 깨짐

**증상**

- jdtls(LSP)는 정상 attach 되고 일반 자바 기능은 됨
- 그런데 **Spring 기능만** 안 됨 (bean 점프, `@RequestMapping` 심볼 검색,
  `application.yml`/`.properties` 자동완성)
- 머신마다 됐다 안 됐다 함 — 특히 새로 git pull 받은 머신에서 재현

**원인 — mason 버전 드리프트**

`lazy-lock.json` 은 **플러그인 git 커밋만** 고정한다. **Mason 패키지 버전은 고정 대상이
아니다.** spring-boot.nvim 은 mason 의 `vscode-spring-boot-tools` 안에 있는 jar 들
(`jdt-ls-extension.jar`, `sts-gradle-tooling.jar`, `io.projectreactor.reactor-core.jar`
등)을 **하드코딩된 이름**으로 jdtls bundle 에 주입한다.

핀이 없으면 새 머신의 첫 설치에서 mason 이 **최신** sts4 를 받는데, 그 버전의 jar
레이아웃/이름이 현재 고정된 spring-boot.nvim 커밋이 기대하는 것과 어긋나면 bundle 주입이
실패해 Spring 기능만 죽는다. (jdtls 자체는 멀쩡하므로 일반 자바는 됨 → 진단이 헷갈림)

**해결 — 버전 핀 (적용 완료)**

`lua/plugins/java.lua` 의 `mason-tool-installer` 에 sts4 버전을 고정해 둠:

```lua
{ "vscode-spring-boot-tools", version = "1.63.0" },
```

이러면 어느 머신이든 spring-boot.nvim 커밋과 짝이 맞는 동일 sts4 를 받는다.

**이미 다른 버전이 깔려 깨진 머신에서**

`auto_update = false` 라 mason-tool-installer 가 자동 다운그레이드하지 않는다. 한 번만
수동으로 맞춰준다:

```vim
:MasonInstall vscode-spring-boot-tools@1.63.0
```

설치 후 nvim 재시작(또는 java 파일에서 `:e`). 확인:

```bash
cat ~/.local/share/nvim/mason/packages/vscode-spring-boot-tools/mason-receipt.json \
  | grep -o 'vscode-spring-boot@[0-9.]*'   # vscode-spring-boot@1.63.0 이어야 함
```

**업그레이드할 때**

sts4 를 올리려면 spring-boot.nvim 플러그인 커밋과 이 버전 핀을 **함께** 올려야 한다.
한쪽만 올리면 다시 드리프트로 깨진다.
