local function as_lines(inputstr)
        local t={}
        for str in inputstr:gmatch("[^\n]*\n?") do
            local without_eol = str:gsub('\n$', '')
            table.insert(t, without_eol)
        end
        return t
end

return {
    as_lines = as_lines,
}
