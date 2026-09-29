-- Read local credentials as data, never as shell code.
-- File values take precedence over inherited connection variables.
local aliases = {
  test_postgres = "DADBOD_TEST_POSTGRES_URL",
  test_mysql = "DADBOD_TEST_MYSQL_URL",
  test_sqlserver = "DADBOD_TEST_SQLSERVER_URL",
}
local values = {}
local path = vim.fn.expand("~/.config/dadbod/.env")
if vim.fn.filereadable(path) == 1 then
  for _, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("\r$", "")
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key then
      local first, last = value:sub(1, 1), value:sub(-1)
      if (first == '"' or first == "'") and last == first then
        value = value:sub(2, -2)
      end
      values[key] = value
    end
  end
end
local dbs = {}
for alias, key in pairs(aliases) do
  local url = values[key]
  if url == nil then
    url = vim.env[key]
  end
  if url and url ~= "" then
    dbs[alias] = url
  end
end
return dbs
