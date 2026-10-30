require("constants")
if storage[STORAGE_NAME] then
  log("Cleanup storage bacause too large changes")
  storage[STORAGE_NAME] = nil
end
