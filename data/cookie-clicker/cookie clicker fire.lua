local appData = {
    -- main game
    cookie = 0,
    cookiePerClick = 1,

    -- products
    CursorOwn = 0,
    CursorPrice = 15,
    CursorUpgradeMult = 1,

    GrandmaOwn = 0,
    GrandmaPrice = 100,
    GrandmaUpgradeMult = 1,

    FarmOwn = 0,
    FarmPrice = 1100,
    FarmUpgradeMult = 1,

    MineOwn = 0,
    MinePrice = 12000,
    MineUpgradeMult = 1,

    -- settings
    gameLow = false,

    -- upgrades
    rifUnlocked = false,
    rifBought = false,

    ctpcUnlocked = false,
    ctpcBought = false,

    AmbidextrousUnlocked = false,
    AmbidextrousBought = false,

    frgUnlocked = false,
    frgBought = false,

    prpnUnlocked = false,
    prpnBought = false,

    ldUnlocked = false,
    ldBought = false,

    chUnlocked = false,
    chBought = false
}

-- Game Data (no save)
local cps = 0
local cookieVer = "QuackEdition 0.3.0"

-- non list
local clickCount = 0
local cookieOverlap = false
local upgradeLength = 0
local productHovered = false
local isClicked = false
local insideExtras = false
local settingsChosen = 1
local extrasState = "menu"

-- list
local productList = {
    --  Name             Description                          CPS  St. Val Multi
    {"Cursor",  "Autoclicks once every 10 seconds.",          0.1,    15,  1.15},
    {"Grandma", "A nice grandma to bake more cookies",          1,   100,  1.25},
    {"Farm",    "Grows cookie plants from cookie seeds.",       8,  1100,  1.05},
    {"Mine",    "Mines out cookie dough and chocolate chips.", 47, 12000,  1.01},
	{"Skibidi", "brrr skibidi dopdopdop yesyesyes.",          100, 24000,  1.50}
}
local upgradesList = {
    --     Name               Description                                         ID     Req to Unlock  Starting VAL
    {"rif",          "The mouse and cursors are twice as efficient.", 1, {"Cursor",   1},      100},
    {"ctpc",         "The mouse and cursors are twice as efficient.", 1, {"Cursor",   1},     1000},
    {"Ambidextrous", "The mouse and cursors are twice as efficient.", 1, {"Cursor",  10},    10000},
    {"frg",          "Grandmas are twice as efficient.",              2, {"Grandma",  1},     1000},
    {"prpn",         "Grandmas are twice as efficient.",              2, {"Grandma",  5},     5000},
    {"ld",           "Grandmas are twice as efficient.",              2, {"Grandma", 25},    50000},
    {"ch",           "Farms are twice as efficient.",                 3, {"Farm",     1},    11000}
}
local upgradesUnlocked = {}
local allGraphic = {}
local listToRemove = {"cookie", "smallCookie", "click", "intro", "cookieClicked"}
local extrasName = {
    "Game Settings",
    --"Restart", -- Use it only for Debugging Purposes
    "Save & Exit",
}
local settingsName = {
    {"Low Detail", "gameLow", "If you do not want a lotta lag, enable this! Disables cookie spawning and text spawning.", "boolean"},
}

function onCreatePost()
    initSaveData('CCNael2xdVer')
    for k, v in pairs(appData) do
        appData[k] = getDataFromSave('CCNael2xdVer', k, v)
    end

    setProperty("camGame.alpha", 0)
    setProperty("camHUD.alpha", 0)
    setPropertyFromClass("ClientPrefs", "hideHud", true)
    setPropertyFromClass('flixel.FlxG', 'mouse.visible', true)

    -- Text Stuff
    makeText("cookieOwn", 0, 75, 60)
    makeText("cpsOwn", 0, 145, 20)
    makeText("prodDescription", 0, 10, 25)
    setTextString("prodDescription", "")
    makeText("Saving", 750, 650, 45)
    setTextString("Saving", "Saving...")
    makeText("ccpe", 2, 702, 12)
    setTextAlignment("ccpe", "left")
    setTextString("ccpe", "Cookie Clicker Psych Edition (v"..cookieVer..")")

    -- Sprites (i should precache them)
    makeSprite("background", 0, 0)
    scaleObject("background", 1.25, 0.775)
    makeSprite("glowBlack", 0, 365)
    scaleObject("glowBlack", 1.35, 1)
    makeSprite("cookie", 0, 0)
    scaleObject("cookie", 0.2, 0.2)
    screenCenter("cookie")
    makeSprite("extras", 0, 0)
    scaleObject("extras", 0.33, 0.33)
    screenCenter("extras")
    setProperty("extras.y", 625)

    makeAnimatedLuaSprite("loading", "loading", 1485, 640)
    addAnimationByPrefix("loading", "loading", "loading", 12, true)
    addLuaSprite("loading", true)
    scaleObject("loading", 0.5, 0.5)
    setObjectCamera("loading", "other")

    makeAnimatedLuaSprite("static", "static", 0, 0)
    addAnimationByPrefix("static", "static", "static", 24, true)
    addLuaSprite("static", true)
    setObjectCamera("static", "other")
    screenCenter("static")
    setProperty("static.alpha", 0)

    runTimer("cps", 1, 0)
    runTimer("save", 60, 0)

    for i in pairs(productList) do
        if appData.cookie >= productList[i][4] then
            makeProduct(i)
        end
    end

    makeSprite("intro", 0, 0, true)
    doTweenX("introx", "intro.scale", 200, 3, "easeIn")
    doTweenY("introy", "intro.scale", 200, 3, "easeIn")
    setObjectOrder("extras", 1000000000)
    setObjectOrder("intro", 1000050000)

    sortUpgrade()
    recalculateCps()
end

function onPause()
    return Function_Stop
end

function onUpdate()
    setTextString("cookieOwn", math.floor(appData.cookie))
    setTextString("cpsOwn", cps.." cookies per second")

    if mouseClicked("left") then
        playSound("click")
    end

    if productHovered then
        productHovered = false
        runTimer("prodBye", 0, 1)
    end

    if mouseOverlaps("extras") and mouseClicked("left") then
        if insideExtras then
            insideExtras = false
            extrasState = "menu"
            stopSound("hi1")
            stopSound("hi2")
            cancelTimer("camloop")
            cancelTween("static")
            cancelTimer("colorChange")
            setProperty("static.alpha", 1)
            doTweenAlpha("static", "static", 0, 0.33, "linear")
            setProperty("ccpe.alpha", 1)
            setProperty("cookieOwn.alpha", 1)
            setProperty("cpsOwn.alpha", 1)
            for i=1,#allGraphic do
                removeLuaSprite(allGraphic[i])
                removeLuaText("extrasName"..i)
            end
            for k, v in pairs(allGraphic) do
                allGraphic[k] = nil
            end
            for i in pairs(productList) do
                setProperty("productInfo"..i..".alpha", 1)
                setProperty("products/"..productList[i][1]..".alpha", 1)
                setProperty("smallCookiePrice"..i..".alpha", 1)
                setProperty("price"..i..".alpha", 1)
                setProperty("own"..i..".alpha", 1)
                setProperty(productList[i][1]..".alpha", 1)
            end
            for i=1,#extrasName do
                removeLuaSprite("extraOutline"..i)
                removeLuaSprite("extraButton"..i)
                removeLuaSprite("extrasName"..i)
            end
        else
            insideExtras = true
            playSound("camloop", 2, "hi1")
            playSound("menu", 1, "hi2")
            runTimer("camloop", 9, 0)
            setProperty("static.alpha", 1)
            doTweenAlpha("static", "static", 0.2, 1, "linear")
            graphicMake("coolCol", 0, 0, 1280, 720, "FF0000")
            graphicMake("bar1", 0, 0, 1280, 45, "000000")
            graphicMake("bar2", 0, 0, 45, 1280, "000000")
            graphicMake("bar3", 1240, 0, 45, 1280, "000000")
            graphicMake("bar4", 0, 675, 1280, 45, "000000")
            for i=1,3 do
                graphicMake("move"..i, 0, 0, 0, 0, "000000")
            end
            doTweenColor("color1", "coolCol", "FFFF00", 2, "linear")
            runTimer("colorChange", 2, 0)
            setProperty("ccpe.alpha", 0)
            setProperty("cookieOwn.alpha", 0)
            setProperty("cpsOwn.alpha", 0)
            for i in pairs(productList) do
                setProperty("productInfo"..i..".alpha", 0)
                setProperty("products/"..productList[i][1]..".alpha", 0)
                setProperty("smallCookiePrice"..i..".alpha", 0)
                setProperty("price"..i..".alpha", 0)
                setProperty("own"..i..".alpha", 0)
                setProperty(productList[i][1]..".alpha", 0)
            end
            for i=1,#extrasName do
                makeExtras(i)
            end
        end
    end

    if not insideExtras then
        -- Products
        for i in pairs(productList) do
            setBlendMode("productInfo"..i, "NORMAL")
            if mouseOverlaps("productInfo"..i) then
                productHovered = true
                setBlendMode("productInfo"..i, "LIGHTEN")
                setTextString("prodDescription", productList[i][2])
                if mouseClicked("left") and appData.cookie >= appData[productList[i][1].."Price"] then
                    playSound("purchase")
                    appData.cookie = appData.cookie - appData[productList[i][1].."Price"]
                    appData[productList[i][1].."Own"] = appData[productList[i][1].."Own"] + 1
                    appData[productList[i][1].."Price"] = math.floor(appData[productList[i][1].."Price"] * productList[i][5])
                    setTextString("price"..i, math.floor(appData[productList[i][1].."Price"]))
                    setTextString("own"..i, appData[productList[i][1].."Own"])
                    for ii in pairs(upgradesList) do
                        local isUnlocked = true
                        for iii in pairs(upgradesUnlocked) do
                            if ii == upgradesUnlocked[iii] then
                                isUnlocked = false
                            end
                        end
                        if (appData[upgradesList[ii][4][1].."Own"] >= upgradesList[ii][4][2]) and isUnlocked then
                            makeUpgrade(ii)
                            table.insert(upgradesUnlocked, ii)
                            sortUpgrade()
                        end
                    end
                    recalculateCps()
                end
            end
            if appData.cookie >= appData[productList[i][1].."Price"] then
                setTextColor("price"..i, "00FF00")
            else
                setTextColor("price"..i, "FF0000")
            end
        end

        -- Upgrades
        for i in pairs(upgradesList) do
            setBlendMode("upgradeFrame"..i, "NORMAL")
            if appData.cookie >= upgradesList[i][5] then
                setBlendMode("upgrades/"..upgradesList[i][1], "NORMAL")
            else
                setBlendMode("upgrades/"..upgradesList[i][1], "DARKEN")
            end
            if mouseOverlaps("upgradeFrame"..i) then
                setBlendMode("upgradeFrame"..i, "LIGHTEN")
                setTextString("prodDescription", upgradesList[i][2].."\nCookie Costs: "..upgradesList[i][5])
                productHovered = true
                if mousePressed("left") and appData.cookie >= upgradesList[i][5] and not isClicked then
                    playSound("purchase")
                    appData.cookie = appData.cookie - upgradesList[i][5]
                    upgradeLength = upgradeLength - 1
                    appData[upgradesList[i][1].."Bought"] = true
                    removeLuaSprite("upgradeFrame"..i)
                    removeLuaSprite("upgrades/"..upgradesList[i][1])
                    local exists = 0
                    for ii=1,#upgradesList do
                        if luaSpriteExists("upgradeFrame"..ii) then
                            exists = exists + 1
                            setProperty("upgradeFrame"..ii..".x", -60 + (60*exists))
                            setProperty("upgrades/"..upgradesList[ii][1]..".x", -55 + (60*exists))
                        end
                    end
                    sortUpgrade()
                    recalculateCps(upgradesList[i][3])
                end
                isClicked = mousePressed("left") -- Psych Engine really making me make another local then
            end
        end

        -- Cookie Physics
        if mouseOverlaps('cookie') then
            if not cookieOverlap then
                doTweenX("boing1", "cookie.scale", 0.225, 2, "elasticOut")
                doTweenY("boing2", "cookie.scale", 0.225, 2, "elasticOut")
            end
            cookieOverlap = true
            if mouseClicked("left") then
                setProperty("cookie.scale.x", 0.2175)
                setProperty("cookie.scale.y", 0.2175)
                doTweenX("boing1", "cookie.scale", 0.225, 2, "elasticOut")
                doTweenY("boing2", "cookie.scale", 0.225, 2, "elasticOut")
                appData.cookie = appData.cookie + appData.cookiePerClick
                for i in pairs(productList) do
                    if appData.cookie >= productList[i][4] and not luaTextExists("price"..i) then
                        makeProduct(i)
                        sortUpgrade()
                    end
                end
                spawnCookies(true)
            end
        else
            if cookieOverlap then
                doTweenX("boing1", "cookie.scale", 0.2, 2, "elasticOut")
                doTweenY("boing2", "cookie.scale", 0.2, 2, "elasticOut")
            end
            cookieOverlap = false
        end
    else
        local find = {}
        for i=1,3 do
            table.insert(find, math.floor(getProperty("move"..i..".x")))
        end
        setProperty("coolCol.color", getColorFromHex(rgbToHex(find)))

        -- Le Menu Items
        if extrasState == "menu" then
            doTweenY("no no", "extras", 625, 0.25, "linear")
            for i=1,#extrasName do
                setProperty("extraOutline"..i..".alpha", 1)
                setProperty("extraButton"..i..".alpha", 1)
                setProperty("extrasName"..i..".alpha", 1)
                if mouseOverlaps("extraButton"..i) and mouseClicked("left") then
                    local hoverName = getTextString("extrasName"..i)
                    if hoverName == "Game Settings" then
                        extrasState = "settings"
                        makeSettings()
                        makeText('settingsDesc', 0, 65, 25)
                    elseif hoverName == "Save & Exit" then
                        for k, v in pairs(appData) do
                            setDataFromSave('CCNael2xdVer', k, v)
                        end
                        flushSaveData('CCNael2xdVer')
                        exitSong(true)
                    elseif hoverName == "Restart" then
                        restartSong(true)
                    end
                end
            end
        else
            doTweenY("no no", "extras", 750, 0.1, "linear")
            for i=1,#extrasName do
                setProperty("extraOutline"..i..".alpha", 0)
                setProperty("extraButton"..i..".alpha", 0)
                setProperty("extrasName"..i..".alpha", 0)
            end
            if extrasState == "settings" then
                setTextString("settingsDesc", settingsName[settingsChosen][3].."\nPress ESCAPE to leave Game Settings and Save your Progress.")
                if keyJustPressed("up") then
                    settingsChosen = settingsChosen - 1
                    if settingsChosen == 0 then
                        settingsChosen = #settingsName
                    end
                    makeSettings()
                elseif keyJustPressed("down") then
                    settingsChosen = settingsChosen + 1
                    if settingsChosen == #settingsName+1 then
                        settingsChosen = 1
                    end
                    makeSettings()
                end
                for i=1,#settingsName do
                    if i == settingsChosen then
                        setTextBorder("settings"..i, 3, "676767")
                        if keyJustPressed("accept") then
                            if settingsName[i][4] == "boolean" then
                                local isTrue = appData[settingsName[i][2]]
                                if isTrue then
                                    appData[settingsName[i][2]] = false
                                else
                                    appData[settingsName[i][2]] = true
                                end
                                playSound("confirmMenu")
                            end
                            makeSettings()
                        end
                    else
                        setTextBorder("settings"..i, 0)
                    end
                end
            end
            if keyJustPressed("pause") and not keyboardJustPressed("ENTER") then
                extrasState = "menu"
                removeLuaText("settingsDesc")
                runTimer("save", 0.01, 1)
                makeSettings()
                playSound("cancelMenu")
            end
        end
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if stringStartsWith(tag, "cps") then
        local seconds = 0
        if cps >= 100 then
            repeat
                seconds = seconds + (1/100)
                runTimer("cookieFall"..seconds, seconds, 1)
            until seconds >= 1
        else
            repeat
                seconds = seconds + (1/cps)
                runTimer("cookieFall"..seconds, seconds, 1)
            until seconds >= 1
        end
        appData.cookie = appData.cookie + math.fmod(cps,1)
    end
    if stringStartsWith(tag, "save") then
        if stringEndsWith(tag, "Back") then
            doTweenX("save1", "Saving", 750, 0.75, "cubeIn")
            doTweenX("save2", "loading", 1485, 0.75, "cubeIn")
        else
            for k, v in pairs(appData) do
                setDataFromSave('CCNael2xdVer', k, v)
            end
            flushSaveData('CCNael2xdVer')
            doTweenX("save1", "Saving", 450, 0.75, "cubeOut")
            doTweenX("save2", "loading", 1185, 0.75, "cubeOut")
            runTimer("saveBack", 3, 1)
        end
    end
    if tag == "prodBye" then
        setTextString("prodDescription", "")
    end
    if stringStartsWith(tag, "cookieFall") then
        appData.cookie = appData.cookie + 1
        spawnCookies(false)
    end
    if tag == "camloop" then
        playSound("camloop", 1, "hi1")
    end
    if tag == "colorChange" then
        local aCol = {}
        for i=1,3 do
            table.insert(aCol, getRandomInt(0,255))
            doTweenX("movin"..i, "move"..i, aCol[i], 2, "linear")
        end
    end
end

function onTweenCompleted(tag)
    for k, v in pairs(listToRemove) do
        if stringStartsWith(tag, v) then
            if luaSpriteExists(tag) then
                removeLuaSprite(tag)
            else
                removeLuaText(tag)
            end
            break
        end
    end
end

function makeSprite(name, x, y, isFront)
    local name2 = name
    if stringStartsWith(name, "smallCookie") then
        name2 = "smallCookie"
    elseif stringStartsWith(name, "productInfo") then
        name2 = "productInfo"
    elseif stringStartsWith(name, "upgradeFrame") then
        name2 = "upgradeFrame"
    end
    if not (name2 == "smallCookie" and insideExtras) then
        makeLuaSprite(name, name2, 0, 0)
        addLuaSprite(name, isFront)
        setObjectCamera(name, "other")
        screenCenter(name)
        setProperty(name..".x", x)
        setProperty(name..".y", y)
    end
end

function graphicMake(name, x, y, width, height, color, center)
    makeLuaSprite(name, "", 0, 0)
    makeGraphic(name, width, height, color)
    addLuaSprite(name)
    setObjectCamera(name, "other")
    setProperty(name..".x", x)
    setProperty(name..".y", y)
    table.insert(allGraphic, name)
    if center then
        screenCenter(name)
        setProperty(name..".y", y)
    end
end

function makeText(name, x, y, size)
    makeLuaText(name, name, 1280, x, y)
    setTextSize(name, size)
    setTextAlignment(name, 'CENTER')
    addLuaText(name)
    setObjectCamera(name, 'camOther')
    setTextBorder(name, 0)
end

function makeProduct(id)
    appData[upgradesList[id][1].."Unlocked"] = true
    makeSprite("productInfo"..id, 1000, 0 + (72 * id))
    scaleObject("productInfo"..id, 0.75, 0.75)
    makeSprite("products/"..productList[id][1], 1004, 3 + (72 * id))
    if productList[id][1] == "Cursor" then
        scaleObject("products/"..productList[id][1], 0.675, 0.675)
    else
        scaleObject("products/"..productList[id][1], 0.7375, 0.7375)
    end
    makeText(productList[id][1], 1060, 5 + (72 * id), 35)
    makeSprite('smallCookiePrice'..id, 1065, 45 + (72 * id))
    scaleObject("smallCookiePrice"..id, 0.25, 0.25)
    makeText("price"..id, 1085, 42 + (72 * id), 15)
    setTextColor("price"..id, "FF0000")
    setTextString("price"..id, appData[productList[id][1].."Price"])
    makeText("own"..id, -10, 8 + (72 * id), 45)
    setTextString("own"..id, appData[productList[id][1].."Own"])
    setProperty("own"..id..".alpha", 0.9)
    setTextColor("own"..id, "737163")
    setTextBorder("own"..id, 1, "959385")
    setTextAlignment("own"..id, "right")
    setTextAlignment("price"..id, "left")
    setTextAlignment(productList[id][1], "left")
end

function makeUpgrade(id)
    appData[upgradesList[id][1].."Unlocked"] = true
    upgradeLength = upgradeLength + 1
    makeSprite("upgradeFrame"..id, -60 + (61*upgradeLength), 0)
    scaleObject("upgradeFrame"..id, 0.5, 0.5)
    makeSprite("upgrades/"..upgradesList[id][1], -55 + (61*upgradeLength), 7.5)
end

function makeExtras(id)
    graphicMake("extraOutline"..id, 0, -2.5+(80*id), 266, 70, "FFFFFF", true)
    graphicMake("extraButton"..id, 0, 0+(80*id), 256, 64, "000000", true)
    makeText("extrasName"..id, 0, 12.5+(80*id), 30)
    setTextString("extrasName"..id, extrasName[id])
end

function makeSettings()
    playSound("scrollMenu")
    for i=1,#settingsName do
        removeLuaText("settings"..i)
        if not (extrasState == "menu") then
            makeText("settings"..i, 100+(12*(i-settingsChosen)), 280+(60*(i-settingsChosen)), 50)
            setTextString("settings"..i, settingsName[i][1]..": "..tostring(appData[settingsName[i][2]]))
            setTextBorder("settings"..i, 3, "676767")
            setTextAlignment("settings"..i, "left")
        end
    end
end

function sortUpgrade()
    -- Deletes all frames and upgrade looks and makes it again but in ID sort.
    for i=1,#upgradesList do
        if luaSpriteExists("upgradeFrame"..i) then
            removeLuaSprite("upgradeFrame"..i)
            removeLuaSprite("upgrades/"..upgradesList[i][1])
        end
        upgradesUnlocked[i] = nil
    end
    upgradeLength = 0
    for i in pairs(upgradesList) do
        if (appData[upgradesList[i][4][1].."Own"] >= upgradesList[i][4][2]) and (appData[upgradesList[i][1].."Unlocked"] and not appData[upgradesList[i][1].."Bought"]) then
            makeUpgrade(i)
            table.insert(upgradesUnlocked, i)
        else
            if appData[upgradesList[i][1].."Bought"] then
                table.insert(upgradesUnlocked, i)
            end
        end
    end
end

function spawnCookies(isClicked)
    clickCount = clickCount + 1
    local opti = 'cookieClicked'..clickCount
    local x = getMouseX("other") - 635
    local y = getMouseY("other")
    local opti2 = "smallCookie"..clickCount
    local repeatTimes = (isClicked and 1 or 2)
    if not appData.gameLow then
        if repeatTimes == 1 then
            makeText(opti, x, y, 25)
        end
        for i=repeatTimes,2 do
            if repeatTimes == 2 then
                opti2 = "smallCookieSky"..clickCount
            end
            makeSprite(opti2, (stringStartsWith(opti2, "smallCookieSky") and getRandomInt(-30, 1275) or x+617), (stringStartsWith(opti2, "smallCookieSky") and -50 or y-15), true)
            scaleObject(opti2, 0.5, 0.5)
            setProperty(opti2..".alpha", 0.65)
            if i == 1 then
                doTweenX("wee"..opti2, opti2, x+getRandomInt(417, 817), 1.5, "linear")
                doTweenY("velo"..opti2, opti2, y+(getMouseY("other")+395), 1.5, "backIn")
                doTweenAngle(opti2, opti2, getRandomInt(-90, 90), 1.5, "linear")
                doTweenAlpha("ohHi"..opti2, opti2, -0.33, 1.5, "linear")
                setTextString(opti, "+"..appData.cookiePerClick)
                doTweenY("click"..clickCount, opti, getProperty(opti..".y") - 200, 2.5, "linear")
                doTweenAlpha(opti, opti, 0, 2.5, "linear")
            else
                doTweenX("weew"..opti2, opti2, getProperty(opti2..".x")+getRandomInt(-150, 150), 1.675, "5")
                doTweenY("velo1"..opti2, opti2, 900, 1.675, "sineIn")
                doTweenAngle(opti2, opti2, getRandomInt(-180, 180), 1.675, "linear")
                doTweenAlpha("ohHi1"..opti2, opti2, -0.33, 1.675, "linear")
            end
            opti2 = "smallCookieSky"..clickCount
        end
    end
end

function recalculateCps(name)
    if name == 1 then
        appData.cookiePerClick = appData.cookiePerClick*2
        appData.CursorUpgradeMult = appData.CursorUpgradeMult*2
    end
    if name == 2 then
        appData.GrandmaUpgradeMult = appData.GrandmaUpgradeMult*2
    end
    if name == 3 then
        appData.FarmUpgradeMult = appData.FarmUpgradeMult*2
    end
    cps = appData.CursorOwn/10 * appData.CursorUpgradeMult
    for i=2,#productList do
        cps = cps + ((appData[productList[i][1].."Own"]*productList[i][3]) * appData[productList[i][1].."UpgradeMult"])
    end
end

------------------------------------------------------------------------------------------------------------------------
--- CODES I USED FROM OTHER SOURCES!! ALL LINKS ARE INCLUDED ASWELL ----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

-- https://github.com/ShadowMario/FNF-PsychEngine/issues/12755#issuecomment-1641455548
function mouseOverlaps(tag)
    addHaxeLibrary('Reflect')
    return runHaxeCode([[
        var obj = game.getLuaObject(']]..tag..[[');
        if (obj == null) obj = Reflect.getProperty(game, ']]..tag..[[');
        if (obj == null) return false;
        return obj.getScreenBounds(null, obj.cameras[0]).containsPoint(FlxG.mouse.getScreenPosition(obj.cameras[0]));
    ]])
end

-- https://gist.github.com/marceloCodget/3862929
function rgbToHex(rgb)
    local hexadecimal = ''
    for key, value in pairs(rgb) do
        local hex = ''
        while (value > 0) do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex
        end
        if (string.len(hex) == 0) then
            hex = '00'
        elseif (string.len(hex) == 1) then
            hex = '0' .. hex
        end
        hexadecimal = hexadecimal .. hex
    end
    return hexadecimal
end
