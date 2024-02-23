#!/usr/bin/env lua


-- variables
local cursorPosition = { x = 7, y = 2 }
local fileLineCount = 0
local function getTerminalSize()
    local width = io.popen('tput cols'):read('*n')
    local height = io.popen('tput lines'):read('*n')
    return width, height
end
local terminalWidth, terminalHeight = getTerminalSize()
local fileContent = {}
local lineCountPadding = 0

-- functions
local function setNonBlockingMode()
    os.execute("stty -icanon -echo")
end

local function resetTerminalMode()
    os.execute("stty icanon echo")
end

local function exit_zero()
    io.write("\27[2J\27[H")
    resetTerminalMode()
    os.exit(0)
end
local function handleKeyPress(key)
    if key == "\27" then -- Check for ESC key
        exit_zero()
    elseif key == "h" then
        cursorPosition.x = cursorPosition.x - 1
    elseif key == "j" then
        cursorPosition.y = cursorPosition.y + 1
    elseif key == "k" then
        cursorPosition.y = cursorPosition.y - 1
    elseif key == "l" then
        cursorPosition.x = cursorPosition.x + 1
    end
    if cursorPosition.y < 2 then
        cursorPosition.y = 2
    end
    if cursorPosition.x < 5 then
        cursorPosition.x = 5
    end
    if cursorPosition.y > fileLineCount then
        cursorPosition.y = fileLineCount + 1
    end
end
local function countDigits(number)
    local count = 0
    while number ~= 0 do
        number = math.floor(number / 10)
        count = count + 1
    end
    return count
end
local function readfile()
    if #arg < 1 then
        print("missing filename")
        exit_zero()
    end
    local filename = arg[1]
    local file = io.open(filename, "r")
    if file then
        local lines = {}
        for line in file:lines() do
            table.insert(lines, line)
            fileLineCount = fileLineCount + 1
        end
        fileContent = lines
        lineCountPadding = countDigits(fileLineCount) + 1
        file:close()
    else
        print("Can't open" .. filename)
    end
end

local function countDigitDifference(number1, number2)
    local count1 = 0
    local count2 = 0
    local temp1 = number1
    while temp1 ~= 0 do
        temp1 = math.floor(temp1 / 10)
        count1 = count1 + 1
    end
    local temp2 = number2
    while temp2 ~= 0 do
        temp2 = math.floor(temp2 / 10)
        count2 = count2 + 1
    end
    return math.abs(count1 - count2)
end

local function draw()
    local lines = fileContent
    for i, line in ipairs(lines) do
        if i == 1 then
            local l = "─"
            for i_l = 1, 95 - 1, 1 do
                if i_l == lineCountPadding then
                    l = l .. "┬"
                else
                    l = l .. "─"
                end
            end
            print(l)
        end
        -- numberpadding
        ----
        local pad = countDigitDifference(fileLineCount, i)
        local spaces = ""
        for j = 1, pad do
            spaces = spaces .. " "
        end
        print((i) .. spaces .. " │ " .. line)
        ----
        if i == fileLineCount then
            local l = "─"
            for i_l = 1, 95 - 1, 1 do
                if i_l == lineCountPadding then
                    l = l .. "┴"
                else
                    l = l .. "─"
                end
            end
            print(l)
            print("MODE: NORMAL")
            local l = "─"
            for i_l = 1, 95 - 1, 1 do
                l = l .. "─"
            end
            print(l)
            print("t height:        " .. terminalHeight)
            print("t width:         " .. terminalWidth)
            print("file line count: " .. fileLineCount)
        end
    end
end

local function init()
    setNonBlockingMode()
    io.write("\27[2J\27[H")
    readfile()
    print("t height:        " .. terminalHeight)
    print("t width:         " .. terminalWidth)
    print("file line count: " .. fileLineCount)
end

-- main
local function main()
    init()
    while true do
        io.write("\27[2J\27[H")
        draw()
        io.write(string.format("\27[%d;%dH", cursorPosition.y, cursorPosition.x))
        local key = io.read(1)
        if key then
            handleKeyPress(key)
        end
    end
end
main()
