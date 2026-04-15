local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Camera = workspace.CurrentCamera

local function GetPlayer(Target)
    local Player = nil
    local Character = nil

    if Target and Target:IsA("Player") then
        Player = Target
        Character = Player.Character
    elseif Target and Target:IsA("Model") then
        Character = Target
        Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
    elseif not Target then
        Player = game:GetService("Players").LocalPlayer
        Character = Player.Character
    end

    local PlayerGui = Player and Player:FindFirstChild("PlayerGui")
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")

    return Player, PlayerGui, Character, Root
end

local function TimedLoop(loopName, duration, callback, onComplete)
    if _G.VP.Loops[loopName] then
        _G.VP.Loops[loopName]:Disconnect()
        _G.VP.Loops[loopName] = nil
    end

    local elapsed = 0
    local maxDuration = (duration and duration > 0) and duration or math.huge

    _G.VP.Loops[loopName] = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        
        if elapsed < maxDuration then
            local function disconnect()
                if _G.VP.Loops[loopName] then
                    _G.VP.Loops[loopName]:Disconnect()
                    _G.VP.Loops[loopName] = nil
                    if onComplete then onComplete() end
                end
            end
            callback(dt, disconnect)
        else
            if _G.VP.Loops[loopName] then
                _G.VP.Loops[loopName]:Disconnect()
                _G.VP.Loops[loopName] = nil
                if onComplete then onComplete() end
            end
        end
    end)
end

local function GetSafePos(targetCFrame)
    local tempPart = Instance.new("Part")
    tempPart.Size = Vector3.new(2, 2, 2)
    tempPart.Transparency = 1
    tempPart.CanCollide = false
    tempPart.Anchored = true
    tempPart.Parent = workspace

    local basePos = targetCFrame.Position + Vector3.new(0, 3, 0)
    tempPart.CFrame = CFrame.new(basePos)

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character, tempPart}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    for i = 1, 10 do
        local boundCheck = workspace:GetPartBoundsInBox(tempPart.CFrame, tempPart.Size, overlapParams)
        
        if #boundCheck == 0 then
            break
        end
        tempPart.CFrame = tempPart.CFrame + Vector3.new(0, 0.5, 0)
    end

    local safeCFrame = tempPart.CFrame

    tempPart:Destroy()
    return safeCFrame
end

local Trigger = {
    Mouse=function(TargetX, TargetY)
        local viewport = Camera.ViewportSize
        local x = TargetX or viewport.X / 2
        local y = TargetY or viewport.Y / 2

        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end,
    Key=function(key, duration)
        duration = duration or 0.1
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(duration)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
}

local Player, PlayerGui, Character = GetPlayer()

if _G.VP then
    if _G.VP.Refresh then
        _G.VP.Refresh()
    end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "Victory Path Exploit"
Screen.DisplayOrder = 9999
Screen.Parent = CoreGui or PlayerGui

_G.VP = {
    Refresh = function()
        Screen:Destroy()
    end,
    Loops = {},
    Events = {},
    Positions = {},
    LoadStrings = {
        Dex="https://raw.githubusercontent.com/Uav3537/RobloxScripts/refs/heads/main/Global/DexExplorer.lua",
        IY="https://raw.githubusercontent.com/Uav3537/RobloxScripts/refs/heads/main/Global/InfiniteYield.lua",
        UNC="https://raw.githubusercontent.com/Uav3537/RobloxScripts/refs/heads/main/Global/UncTester.lua",
        TrashCan="https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Trashcan%20Man"
    },
    Games = {
        AB={
            Id=8573962925,
            Locations={
                Atrain={-494, 139, -51458},
                FNF={6620, 15, -89},
                JudgementHall={33301, -302, 13},
                KrisUlt={6117, 229, 3375},
                MarisaUlt={49988, 450, 26852},
                NightmareBox={5433, 3352, 1883},
                ReaperO3={34, 6420, -13},
                ReaperO4={-1012, 6385, 76},
            }
        },
        ABA={
            Id=12283052444,
            Locations={
                Spawn={-33, -273, 273},
                Ceiling={71, 259, -486},
            }
        },
        TSB={
            Id=10449761463
        }
    },
}

local function ParseTarget(text)
    local allPlayers = Players:GetPlayers()
    local root = {}
    local targets = string.split(text or "me", ",")

    for _, target in ipairs(targets) do
        target = target:lower():gsub("%s+", "")
        if target == "me" then
            if Player.Character then table.insert(root, Player.Character) end
        elseif target == "all" then
            for _, p in ipairs(allPlayers) do if p.Character then table.insert(root, p.Character) end end
        elseif target == "others" then
            for _, p in ipairs(allPlayers) do if p ~= Player and p.Character then table.insert(root, p.Character) end end
        else
            for _, p in ipairs(allPlayers) do
                if p.Name:lower():sub(1, #target) == target or (p.DisplayName and p.DisplayName:lower():sub(1, #target) == target) then
                    if p.Character then table.insert(root, p.Character) end
                end
            end
        end
    end
    return root
end

local TypeTransformers = {
    ["number"] = function(val, default)
        return tonumber(val) or default
    end,
    ["player"] = function(val, default)
        if not val or val == "" then val = default end
        return ParseTarget(val)
    end,
    ["string"] = function(val, default)
        return (val and val ~= "") and val or default
    end,
    ["boolean"] = function(val, default)
        if val == "on" or val == "true" or val == "yes" then return true end
        if val == "off" or val == "false" or val == "no" then return false end
        return default
    end
}

local Commands = {}

Commands["copypos"] = {
    Description = "copies the position",
    Args = {
    },
    Function = function(args) 
        local _, _, _, Root = GetPlayer()

        local x = math.floor(Root.Position.X)
        local y = math.floor(Root.Position.Y)
        local z = math.floor(Root.Position.Z)

        setclipboard(x .. " " .. y .. " " .. z)
    end
}

Commands["tpto"] = {
    Description = "teleports to the player",
    Args = {
        {Type = "player", Default = "me", Name = "Target"},
    },
    Function = function(args) 
        local _, _, _, Root = GetPlayer()
        if not Root then return end

        local targets = args[1]

        if targets and #targets > 0 then
            local targetChar = targets[1] 
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

            if targetRoot then
                Root.CFrame = CFrame.new(GetSafePos(targetRoot.CFrame).Position) * Root.CFrame.Rotation
            end
        end
    end
}

Commands["tppos"] = {
    Description = "teleports to position",
    Args = {
        {Type = "number", Default = 0, Name = "X"},
        {Type = "number", Default = 0, Name = "Y"},
        {Type = "number", Default = 0, Name = "Z"}
    },
    Function = function(args) 
        local Player, PlayerGui, Character, Root = GetPlayer()

        Root.CFrame = CFrame.new(GetSafePos(CFrame.new(args[1], args[2], args[3])).Position) * Root.CFrame.Rotation
    end
}

Commands["setflag"] = {
    Description = "sets a flag",
    Args = {
    },
    Function = function(args) 
        local _, _, _, Root = GetPlayer()

        _G.VP.Positions.Flag = Root.CFrame
    end
}

Commands["tpflag"] = {
    Description = "tp to flag",
    Args = {
    },
    Function = function(args) 
        local _, _, _, Root = GetPlayer()

        Root.CFrame = _G.VP.Positions.Flag
    end
}

Commands["hitbox"] = {
    Description = "sets the target hitbox",
    Args = {
        {Type = "player", Default = "others", Name = "target"},
        {Type = "number", Default = 50, Name = "Size"},
    },
    Function = function(args) 
        local Player, PlayerGui, Character, Root = GetPlayer()

        TimedLoop("Hitbox", nil, function(dt, disconnect)
            for _, t in ipairs(args[1]) do
                local TargetPlayer, _, _, TargetRoot = GetPlayer(t)
                if TargetRoot and TargetPlayer ~= Player then
                    TargetRoot.CanCollide = false

                    TargetRoot.Size = Vector3.new(args[2], args[2], args[2])
                    TargetRoot.Transparency = 0.5
                end
            end
        end)
    end
}

Commands["fakeout"] = {
    Description = "teleports to void",
    Args = {
        {Type = "number", Default = 0, Name = "X"},
        {Type = "number", Default = nil, Name = "Y"},
        {Type = "number", Default = 0, Name = "Z"},
        {Type = "number", Default = nil, Name = "Duration"},
    },
    Function = function(args) 
        if _G.VP.Loops.Fakeout then
            _G.VP.Loops.Fakeout:Disconnect()
        end

        local Player, PlayerGui, Character, Root = GetPlayer()

        local BeforeFrame = Root.CFrame
        local IsStunned = Character:GetAttribute("IsStunned") 
            or (Character:FindFirstChild("Data") and Character.Data:FindFirstChild("Stunned") and Character.Data.Stunned.Value)
        if args[2] == nil then args[2] = workspace.FallenPartsDestroyHeight + 20 end

        if IsStunned then
            if args[4] == nil then args[4] = 10 end
            local StunTick = 0
            TimedLoop("Fakeout", 10, function(dt, disconnect)
                local IsStunned = Character:GetAttribute("IsStunned") 
                    or (Character:FindFirstChild("Data") and Character.Data:FindFirstChild("Stunned") and Character.Data.Stunned.Value)
                print(IsStunned)
                if not IsStunned then
                    StunTick = StunTick + dt
                    if StunTick >= 0.5 then
                        disconnect()
                        return
                    end
                end
                local Player, PlayerGui, Character, Root = GetPlayer()
                Root.CFrame = CFrame.new(args[1], args[2], args[3])
            end, function()
                Root.CFrame = BeforeFrame
            end)
        else
            if args[4] == nil then args[4] = 3 end
            TimedLoop("Fakeout", 1.5, function(dt, disconnect)
                local Player, PlayerGui, Character, Root = GetPlayer()
                Root.CFrame = CFrame.new(args[1], args[2], args[3])
            end, function()
                Root.CFrame = BeforeFrame
            end)
        end
    end
}

Commands["speed"] = {
    Description = "sets your speed",
    Args = {
        {Type = "number", Default = 50, Name = "Speed"}
    },
    Function = function(args)
        if(_G.VP.Events.Speed) then
            _G.VP.Events.Speed:Disconnect()
            _G.VP.Events.Speed = nil
        end
        
        local Player, PlayerGui, Character, Root = GetPlayer()
        local Humanoid = Character:FindFirstChild("Humanoid")

        if(Humanoid) then Humanoid.WalkSpeed = args[1] end
        _G.VP.Events.Speed = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if(Humanoid) then Humanoid.WalkSpeed = args[1] end
        end)
    end
}

Commands["unspeed"] = {
    Description = "cancels speed",
    Args = {
    },
    Function = function(args) 
        if(_G.VP.Events.Speed) then
            _G.VP.Events.Speed:Disconnect()
            _G.VP.Events.Speed = nil
        end
    end
}


Commands["reset"] = {
    Description = "resets your character",
    Args = {
    },
    Function = function(args) 
        local Player, PlayerGui, Character, Root = GetPlayer()
        local Humanoid = Character:FindFirstChild("Humanoid")

        if replicatesignal then
            replicatesignal(Player.Kill)
        elseif humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        else
            Character:BreakJoints()
        end
    end
}

Commands["rj"] = {
    Description = "rejoins server",
    Args = {
    },
    Function = function(args) 
        local Player, PlayerGui, Character, Root = GetPlayer()
        local Humanoid = Character:FindFirstChild("Humanoid")

        if #Players:GetPlayers() <= 1 then
            Player:Kick("\nRejoining...")
            wait()
            TeleportService:Teleport(game.PlaceId, Player)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        end
    end
}

Commands["clicktp"] = {
    Description = "teleports if both mouth buttons are clicked",
    Args = {
    },
    Function = function(args) 
        local Player, PlayerGui, Character, Root = GetPlayer()

        if(_G.VP.Events.ClickTp) then
            _G.VP.Events.ClickTp:Disconnect()
            _G.VP.Events.ClickTp = nil
        end
        if(_G.VP.Events.MouseClick) then
            _G.VP.Events.MouseClick:Disconnect()
            _G.VP.Events.MouseClick = nil
        end

        local Mouse = Player:GetMouse()
        local inputState = {
            [Enum.UserInputType.MouseButton1] = false,
            [Enum.UserInputType.MouseButton2] = false
        }

        _G.VP.Events.ClickTp = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            
            if inputState[input.UserInputType] ~= nil then
                inputState[input.UserInputType] = true
            end

            if inputState[Enum.UserInputType.MouseButton1] and inputState[Enum.UserInputType.MouseButton2] then
                local _, _, _, Root = GetPlayer()
                if Root and Mouse.Hit then
                    Root.CFrame = CFrame.new(GetSafePos(Mouse.hit).Position) * Root.CFrame.Rotation
                end
            end
        end)

        _G.VP.Events.MouseClick = UserInputService.InputEnded:Connect(function(input)
            if inputState[input.UserInputType] ~= nil then
                inputState[input.UserInputType] = false
            end
        end)
    end
}

Commands["unclicktp"] = {
    Description = "cancels clicktp",
    Args = {
    },
    Function = function(args)
        if(_G.VP.Events.ClickTp) then
            _G.VP.Events.ClickTp:Disconnect()
            _G.VP.Events.ClickTp = nil
        end
        if(_G.VP.Events.MouseClick) then
            _G.VP.Events.MouseClick:Disconnect()
            _G.VP.Events.MouseClick = nil
        end
    end
}

Commands["dex"] = {
    Description = "opens dex",
    Args = {
    },
    Function = function(args) 
        loadstring(game:HttpGet(_G.VP.LoadStrings.Dex, true))()
    end
}

Commands["iy"] = {
    Description = "opens Infinite Yield",
    Args = {
    },
    Function = function(args) 
        loadstring(game:HttpGet(_G.VP.LoadStrings.IY, true))()
        Frames.IY.Hide()
    end
}

Commands["unc"] = {
    Description = "tests executor unc",
    Args = {
    },
    Function = function(args) 
        loadstring(game:HttpGet(_G.VP.LoadStrings.UNC, true))()
    end
}

if game.PlaceId == _G.VP.Games.AB.Id then
    print("AB 감지됨")
    Commands["multiply"] = {
        Description = "multiplies character speed",
        Args = {
            {Type = "number", Default = 2.5, Name = "Multiplier"},
        },
        Function = function(args) 
            local _, _, Character = GetPlayer()
            if not Character then return end

            local TimeMulti = Character.Data.TimeMulti
            TimeMulti.Value = args[1]
        end
    }
    Commands["maxstamina"] = {
        Description = "sets your character stamina to max",
        Args = {
            {Type = "number", Default = 2.5, Name = "Multiplier"},
        },
        Function = function(args) 
            local _, _, Character = GetPlayer()
            if not Character then return end

            local stamina = Character.Data.RunStamina
            local staminaMax = stamina.Max

            TimedLoop("MaxStamina", nil, function(dt, disconnect)
                stamina.Value = staminaMax.Value
            end)
        end
    }
end

if game.PlaceId == _G.VP.Games.ABA.Id then
    print("ABA 감지됨")
    local GameTick = Workspace:WaitForChild("CT", 1)
    Commands["multiply"] = {
        Description = "multiplies your character speed",
        Args = {
            {Type = "number", Default = 2.5, Name = "Multiplier"},
        },
        Function = function(args) 
            local _, _, Character = GetPlayer()
            if not Character then return end

            Character:SetAttribute("TimeMulti", args[1])
        end
    }
    Commands["lmb"] = {
        Description = "infinite lmbs player",
        Args = {
            {Type = "player", Default = nil, Name = "Target"},
        },
        Function = function(args) 
            if not args[1] then return end

            local target = args[1][1]

            local Player, PlayerGui, Character, Root = GetPlayer()
            local TargetPlayer, _, TargetCharacter, TargetRoot = GetPlayer(target)
            local Cooldowns = Workspace:WaitForChild("Game", 5):WaitForChild("Cooldowns", 1):WaitForChild(Player.Name, 1)

            local function tpFront(distant)
                local newPosition = TargetRoot.CFrame.Position + (TargetRoot.CFrame.LookVector * distant)
                Root.CFrame = CFrame.lookAt(newPosition, TargetRoot.CFrame.Position)
            end
            local count = 0
            Character:SetAttribute("TimeMulti", 10)
            task.spawn(function()
                while clicking do
                    count = count + 1
                    tpFront(4)
                    Trigger.Mouse()
                    task.wait(0.17)
                    if(count > 30) then break end
                end
            end)

        end
    }
end

if game.PlaceId == _G.VP.Games.ABA.TSB then
    Commands["trashcan"] = {
        Description = "opens trashcan",
        Args = {
        },
        Function = function(args) 
            loadstring(game:HttpGet(_G.VP.LoadStrings.TrashCan, true))()
        end
    }
end

local Parser = {
    String = function(self, str)
        local Units = string.split(str, ";")
        for _, Unit in ipairs(Units) do
            local cleanUnit = string.gsub(Unit, "^%s*(.-)%s*$", "%1")
            if cleanUnit ~= "" then
                self:Unit(cleanUnit)
            end
        end
    end,
    Unit = function(self, str)
        local Words = string.split(str, " ")
        local cmdName = table.remove(Words, 1):lower()
        local cmdData = Commands[cmdName]

        if not cmdData then
            warn("명령어를 찾을 수 없음: " .. cmdName)
            return
        end

        local finalArgs = {}
        for i, argSchema in ipairs(cmdData.Args) do
            local rawValue = Words[i]
            local transformer = TypeTransformers[argSchema.Type]
            if transformer then
                finalArgs[i] = transformer(rawValue, argSchema.Default)
            else
                finalArgs[i] = rawValue or argSchema.Default
            end
        end

        task.spawn(function()
            local success, err = pcall(function()
                cmdData.Function(finalArgs)
            end)
            if not success then warn("실행 에러 [" .. cmdName .. "]: " .. err) end
        end)
    end
}

local function BtnVisibility(name)
    return function(text, btn, cursorPtr)
        if not text or not btn then return end
        local ptr = tonumber(cursorPtr) or (#text + 1)
        local textBeforeCursor = string.sub(text, 1, ptr - 1)
        local segments = string.split(textBeforeCursor, ";")
        local currentSegment = segments[#segments] or ""
        local cleanSegment = string.gsub(currentSegment, "^%s*(.-)%s*$", "%1")
        local firstWord = string.split(cleanSegment, " ")[1] or ""
        local search = firstWord:lower()
        local target = name:lower()

        if search == "" or string.sub(target, 1, #search) == search then
            btn.Visible = true
        else
            btn.Visible = false
        end
    end
end

local function replaceCurrentSegment(textBox, newCommand)
    textBox:CaptureFocus()
    local text = textBox.Text
    local cursor = textBox.CursorPosition
    local leftSide = string.sub(text, 1, cursor - 1)
    local lastSemicolon = 0
    for i = #leftSide, 1, -1 do
        if string.sub(leftSide, i, i) == ";" then
            lastSemicolon = i
            break
        end
    end
    local prefix = string.sub(leftSide, 1, lastSemicolon)
    local rightSide = string.sub(text, cursor)
    local nextSemicolon = string.find(rightSide, ";")
    local suffix = nextSemicolon and string.sub(rightSide, nextSemicolon) or ""
    local cleanCommand = newCommand:gsub("%s+", "")
    if lastSemicolon > 0 and not prefix:match(";%s$") then
        prefix = prefix .. " "
    end
    textBox.Text = prefix .. cleanCommand .. " " .. suffix
    local newCursorPos = #prefix + #cleanCommand + 2
    textBox.CursorPosition = newCursorPos
    task.defer(function()
        if not textBox:IsFocused() then
            textBox:CaptureFocus()
        end
        textBox.CursorPosition = newCursorPos
    end)
end

local Frames = {
    Loading = (function()
        local Background = Instance.new("Frame")
        Background.Name = "Loading-Background"
        Background.Size = UDim2.new(0, 400, 0, 300)
        Background.Position = UDim2.new(0.5, 0, 0.5, 0)
        Background.AnchorPoint = Vector2.new(0.5, 0.5)
        Background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        local BackgroundCorner = Instance.new("UICorner")
        BackgroundCorner.CornerRadius = UDim.new(0, 15)
        local Title = Instance.new("TextLabel")
        Title.Name = "Loading-Title"
        Title.Text = "VICTORY PATH Exploit"
        Title.Size = UDim2.new(0.8, 0, 0.2, 0)
        Title.Position = UDim2.new(0.5, 0, 0, 0)
        Title.AnchorPoint = Vector2.new(0.5, 0)
        Title.TextScaled = true
        Title.BackgroundTransparency = 1
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        local Welcome = Instance.new("TextLabel")
        Welcome.Name = "Loading-Welcome"
        Welcome.Text = "Welcome"
        Welcome.Size = UDim2.new(0.5, 0, 0.2, 0)
        Welcome.Position = UDim2.new(0.5, 0, 0.12, 0)
        Welcome.AnchorPoint = Vector2.new(0.5, 0)
        Welcome.BackgroundTransparency = 1
        Welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
        Welcome.Font = Enum.Font.GothamBold
        Welcome.TextSize = 35
        local Image = Instance.new("ImageLabel")
        Image.Name = "Loading-Image"
        Image.Size = UDim2.new(0, 100, 0, 100)
        Image.Position = UDim2.new(0.5, 0, 0.45, 0)
        Image.AnchorPoint = Vector2.new(0.5, 0.5)
        Image.BackgroundTransparency = 1
        Image.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Image
        local ImageStroke = Instance.new("UIStroke")
        ImageStroke.Thickness = 3
        ImageStroke.Color = Color3.fromRGB(255, 255, 255)
        ImageStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local Name = Instance.new("TextLabel")
        Name.Name = "Loading-Name"
        Name.Text = Player.DisplayName .. "\n(@" .. Player.Name .. ")"
        Name.Size = UDim2.new(0.5, 0, 0.2, 0)
        Name.Position = UDim2.new(0.5, 0, 0.6, 0)
        Name.AnchorPoint = Vector2.new(0.5, 0)
        Name.BackgroundTransparency = 1
        Name.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name.Font = Enum.Font.GothamBold
        Name.TextSize = 20
        local Loading = Instance.new("TextLabel")
        Loading.Name = "Loading-Name"
        Loading.Text = "Loading..."
        Loading.Size = UDim2.new(0.5, 0, 0.2, 0)
        Loading.Position = UDim2.new(0.5, 0, 1, 0)
        Loading.AnchorPoint = Vector2.new(0.5, 1)
        Loading.BackgroundTransparency = 1
        Loading.TextColor3 = Color3.fromRGB(255, 255, 255)
        Loading.Font = Enum.Font.GothamBold
        Loading.TextSize = 40
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(Loading, tweenInfo, {TextTransparency = 0.5})
        tween:Play()
        Background.Parent = Screen
        BackgroundCorner.Parent = Background
        Title.Parent = Background
        Welcome.Parent = Background
        Image.Parent = Background
        ImageStroke.Parent = Image
        Name.Parent = Background
        Loading.Parent = Background
        Background.Visible = false
        return {
            Main = Background,
            Show = function() Background.Visible = true end,
            Hide = function() Background.Visible = false end,
            Remove = function() Background:Destroy() end,
        }
    end)(),
    IY = (function()
        local Background = Instance.new("Frame")
        Background.Name = "IY-Background"
        Background.Size = UDim2.new(0, 500, 0, 250)
        Background.Position = UDim2.new(1, -20, 1, -20)
        Background.AnchorPoint = Vector2.new(1, 1)
        Background.BackgroundTransparency = 1
        local Bar = Instance.new("TextBox")
        Bar.Name = "IY-Bar"
        Bar.Size = UDim2.new(1, 0, 0, 40)
        Bar.Position = UDim2.new(0, 0, 1, 0)
        Bar.AnchorPoint = Vector2.new(0, 1)
        Bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Bar.BackgroundTransparency = 0.4
        Bar.Text = ""
        Bar.PlaceholderText = "Enter Command..."
        Bar.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
        Bar.TextColor3 = Color3.fromRGB(255, 255, 255)
        Bar.Font = Enum.Font.GothamMedium
        Bar.TextSize = 18
        Bar.ClearTextOnFocus = false
        Bar.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local cmd = Bar.Text
                if cmd ~= "" then
                    Parser:String(cmd)
                    Bar.Text = ""
                end
                
            end
        end)
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Name = "IY-Scroll"
        Scroll.Position = UDim2.new(0, 0, 1, -45)
        Scroll.AnchorPoint = Vector2.new(0, 1)
        Scroll.Size = UDim2.new(1, 0, 0, 0)
        Scroll.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Scroll.BackgroundTransparency = 0.4
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 4
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local Layout = Instance.new("UIListLayout")
        Layout.VerticalAlignment = Enum.VerticalAlignment.Top
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 2)
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local contentHeight = Layout.AbsoluteContentSize.Y
            local targetHeight = math.min(contentHeight, 200)
            
            TweenService:Create(Scroll, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
            
            Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        end)
        Background.Parent = Screen
        Bar.Parent = Background
        Scroll.Parent = Background
        Layout.Parent = Scroll
        Background.Visible = false
        return {
            Background = Background,
            Bar = Bar,
            Show = function()
                Background.Visible = true
            end,
            Hide = function()
                Background.Visible = false
            end,
            Insert = {
                Button = function(text, refresh, callback)
                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(1, 0, 0, 30)
                    Btn.Name = text
                    Btn.Text = text
                    
                    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    Btn.TextSize = 14
                    Btn.Font = Enum.Font.GothamBold
                    Btn.TextXAlignment = Enum.TextXAlignment.Left
                    Btn.TextStrokeTransparency = 0.5
                    
                    Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    Btn.BackgroundTransparency = 0.3
                    Btn.Parent = Scroll
                    Btn.Visible = false
                    if refresh then
                        Bar:GetPropertyChangedSignal("Text"):Connect(function()
                            if Bar:IsFocused() then
                                refresh(Bar.Text, Btn, Bar.CursorPosition)
                            end
                        end)
                        Bar:GetPropertyChangedSignal("CursorPosition"):Connect(function()
                            if Bar:IsFocused() then
                                refresh(Bar.Text, Btn, Bar.CursorPosition)
                            end
                        end)
                    end
                    Bar.FocusLost:Connect(function()
                        task.delay(0.2, function()
                            if not Bar:IsFocused() then 
                                Btn.Visible = false 
                            end
                        end)
                    end)
                    if callback then
                        Btn.MouseButton1Down:Connect(function()
                            callback(Bar)
                        end)
                    end
                end
            }
        }
    end)()
}

for name, data in pairs(Commands) do
    local ArgsText = " "
    for _, arg in ipairs(data.Args) do
        ArgsText = ArgsText .. arg.Name .. "[" .. arg.Type .. "] "
    end

    local buttonText = name .. (data.Description and " (" .. data.Description .. ")" or "") .. ArgsText
    
    Frames.IY.Insert.Button(buttonText, BtnVisibility(name), function(bar)
        replaceCurrentSegment(bar, name .. " ")
    end)
end


UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Semicolon then
        task.wait()
        Frames.IY.Bar:CaptureFocus()
        Frames.IY.Bar.Text = ""
    end
end)

UserInputService.MouseIconEnabled = true

Frames.Loading.Show()
task.wait(1.5)
Frames.Loading.Hide()
Frames.IY.Show()
