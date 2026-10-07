-- Helm 차트 템플릿은 Go 템플릿({{ }})이 섞여 yaml 파서로는 ERROR 노드가 생긴다.
-- Chart.yaml이 있는 차트의 templates/ 아래만 helm으로 본다(values.yaml 등은 yaml 유지).
local function helm(path)
  local chart = vim.fs.find("Chart.yaml", { path = vim.fs.dirname(path), upward = true })[1]
  if chart and vim.startswith(path, vim.fs.dirname(chart) .. "/templates/") then
    return "helm"
  end
end

vim.filetype.add({
  pattern = {
    [".*/templates/.*%.ya?ml"] = helm,
    [".*/templates/.*%.tpl"] = helm,
  },
})
