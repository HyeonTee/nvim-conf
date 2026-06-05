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
