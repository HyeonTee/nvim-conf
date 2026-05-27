-- java 파일을 열 때마다 호출되어 jdtls 를 buffer 에 attach 한다.
-- nvim-jdtls 의 start_or_attach 는 같은 root_dir 에 대해선 기존 클라이언트를
-- 재사용하므로 같은 프로젝트 안에서 여러 java 파일을 열어도 1개의 jdtls 만 뜬다.

-- Java 버퍼 들여쓰기: 4칸 스페이스 (Java 커뮤니티 표준 / Eclipse 기본).
-- 전역 옵션은 4칸이지만 버퍼 단위로 명시해 어떤 ftplugin/포매터가 덮어써도 유지.
-- 이 값은 LSP 클라이언트가 jdtls 에 formatOptions 로도 전달되어 포맷 결과에 반영됨.
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then
  return
end

local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages"
local jdtls_path = mason_pkg .. "/jdtls"

-- OS 별 jdtls config 디렉토리
local config_dir = "config_linux"
if vim.fn.has("mac") == 1 then
  config_dir = "config_mac"
elseif vim.fn.has("win32") == 1 then
  config_dir = "config_win"
end

-- jdtls 부팅에 쓸 java 바이너리 결정.
-- jdtls 자체가 Java 21+ 를 요구하므로 PATH 의 java 가 더 낮은 버전이면 exit code 13.
-- 우선순위:
--   1. JDTLS_JAVA_HOME (사용자가 명시한 jdtls 전용 JDK)
--   2. macOS: /usr/libexec/java_home -v 21 결과
--   3. JAVA_HOME (사용자가 21+ 로 설정했다고 가정)
--   4. PATH 의 "java" (최후 폴백)
local function find_jdtls_java()
  if vim.env.JDTLS_JAVA_HOME and vim.env.JDTLS_JAVA_HOME ~= "" then
    return vim.env.JDTLS_JAVA_HOME .. "/bin/java"
  end
  if vim.fn.has("mac") == 1 then
    local handle = io.popen("/usr/libexec/java_home -v 21 2>/dev/null")
    if handle then
      local home = handle:read("*l")
      handle:close()
      if home and home ~= "" then
        return home .. "/bin/java"
      end
    end
  end
  if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
    return vim.env.JAVA_HOME .. "/bin/java"
  end
  return "java"
end
local jdtls_java = find_jdtls_java()

-- equinox launcher jar (버전이 매번 바뀌므로 glob 으로 잡는다)
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
if launcher_jar == "" then
  vim.notify(
    "jdtls launcher jar 를 찾지 못함. mason-tool-installer 가 백그라운드에서 설치 중이거나 아직 설치되지 않은 상태입니다.\n"
      .. ":MasonToolsUpdate 로 진행상황 확인, 또는 :MasonInstall jdtls 로 즉시 설치 후 :e 로 버퍼를 다시 여세요.",
    vim.log.levels.WARN
  )
  return
end

-- 프로젝트 루트 (gradle/maven/git 우선순위)
local root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" }
local root_dir = vim.fs.root(0, root_markers)
if not root_dir then
  return
end

-- 워크스페이스는 프로젝트별로 분리해야 인덱스 충돌이 안 난다.
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

-- jdtls 에 주입할 bundle jar 들 (DAP + Test + Spring 확장)
local bundles = {}

local java_debug_jars = vim.split(
  vim.fn.glob(mason_pkg .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"),
  "\n",
  { trimempty = true }
)
vim.list_extend(bundles, java_debug_jars)

local java_test_jars = vim.split(
  vim.fn.glob(mason_pkg .. "/java-test/extension/server/*.jar"),
  "\n",
  { trimempty = true }
)
-- com.microsoft.java.test.runner-jar-with-dependencies.jar 는 bundle 에 넣으면 안 됨
java_test_jars = vim.tbl_filter(function(jar)
  return not string.find(jar, "com.microsoft.java.test.runner-jar-with-dependencies")
end, java_test_jars)
vim.list_extend(bundles, java_test_jars)

local ok_spring, spring_boot = pcall(require, "spring_boot")
if ok_spring and spring_boot.java_extensions then
  vim.list_extend(bundles, spring_boot.java_extensions())
end

-- blink.cmp 가 지원하는 capabilities (스니펫 등) 전달
local capabilities = {}
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
  capabilities = blink.get_lsp_capabilities()
end

local config = {
  cmd = {
    jdtls_java,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx2g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. jdtls_path .. "/lombok.jar",
    "-jar", launcher_jar,
    "-configuration", jdtls_path .. "/" .. config_dir,
    "-data", workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  settings = {
    java = {
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
        },
        importOrder = { "java", "javax", "com", "org" },
      },
      configuration = {
        updateBuildConfiguration = "automatic",
      },
      sources = {
        organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
      },
      -- 포맷 들여쓰기 4칸 스페이스 강제 (LSP formatOptions 가 미전달돼도 안전망)
      format = {
        enabled = true,
        tabSize = 4,
        insertSpaces = true,
      },
    },
  },
  init_options = {
    bundles = bundles,
  },
  on_attach = function(_, bufnr)
    -- DAP 통합 (java-debug-adapter + java-test bundle 을 jdtls 가 들고 있어야 동작)
    local ok_dap, _ = pcall(require, "dap")
    if ok_dap then
      jdtls.setup_dap({ hotcodereplace = "auto", config_overrides = {} })
      pcall(function()
        require("jdtls.dap").setup_dap_main_class_configs()
      end)
    end

    -- jdtls 전용 키맵 (organize_imports, extract_*, test runner)
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, vim.tbl_extend("force", opts, { desc = "Java: import 정리" }))
    vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, vim.tbl_extend("force", opts, { desc = "Java: 변수 추출" }))
    vim.keymap.set("v", "<leader>jv", function() jdtls.extract_variable(true) end, vim.tbl_extend("force", opts, { desc = "Java: 변수 추출" }))
    vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, vim.tbl_extend("force", opts, { desc = "Java: 상수 추출" }))
    vim.keymap.set("v", "<leader>jc", function() jdtls.extract_constant(true) end, vim.tbl_extend("force", opts, { desc = "Java: 상수 추출" }))
    vim.keymap.set("v", "<leader>jm", function() jdtls.extract_method(true) end, vim.tbl_extend("force", opts, { desc = "Java: 메서드 추출" }))
    vim.keymap.set("n", "<leader>jt", function() require("jdtls.dap").test_class() end, vim.tbl_extend("force", opts, { desc = "Java: 클래스 테스트" }))
    vim.keymap.set("n", "<leader>jn", function() require("jdtls.dap").test_nearest_method() end, vim.tbl_extend("force", opts, { desc = "Java: 가장 가까운 메서드 테스트" }))
  end,
}

jdtls.start_or_attach(config)
