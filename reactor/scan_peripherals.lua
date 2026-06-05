for _, name in ipairs(peripheral.getNames()) do
    print("Name: " .. name)
    print("Type: " .. tostring(peripheral.getType(name)))

    local methods = peripheral.getMethods(name)
    if methods then
        print("Methods: " .. textutils.serialize(methods))
    end

    print("----------------------------")
end
