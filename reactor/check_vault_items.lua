local vault = ...

if not vault then
    print("Usage: check_vault_items <vaultPeripheral>")
    print("Example: check_vault_items create:item_vault_1")
    return
end

local inv = peripheral.wrap(vault)
if not inv then error("Missing peripheral: " .. vault) end
if type(inv.list) ~= "function" then error("Peripheral is not an inventory: " .. vault) end

local slots = inv.list()
for slot, item in pairs(slots) do
    print(slot .. ": " .. item.name .. " x" .. item.count)
end
