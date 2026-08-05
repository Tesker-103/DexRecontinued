--!native
--!optimize 2

--[[

    ____             ____  ______   _____           _       ___
   / __ \___  _  __ / __ \/ ____/  / ___/___  _____(_)___ _/ (_)___  ___  _____
  / / / / _ \| |/_// /_/ / __/     \__ \/ _ \/ ___/ / __ `/ / /_  / / _ \/ ___/
 / /_/ /  __/>  < / _, _/ /___    ___/ /  __/ /  / / /_/ / / / / /_/  __/ /
/_____/\___/_/|_|/_/ |_/_____/   /____/\___/_/  /_/\__,_/_/_/ /___/\___/_/


The most accurate and top lua roblox binary format serializer since late 2020

Made in preparation for The Augur's reign that started in July 2021

Many ServerScriptService and ServerStorage models of top games were saved with top accuracy

Fixed & Improved for DexRE, Originally made by Moon

]]


-- Made by Moon
local Main,Serializer,API,Settings,DefaultSettings,env

local service = setmetatable({},{__index = function(self,name)
	local serv = cloneref(game:GetService(name))
	self[name] = serv
	return serv
end})

-- Helper functions for new features
local function ActivateSafeMode()
pcall(function() game:GetService"Players".LocalPlayer:Kick("SaveInstance SafeMode: Saving initiated. Goodbye!") end)
end

local function BoostFPS()
	local s = false
	pcall(function()
		UserSettings().GameSettings.FPSUnlocked = false
		UserSettings().GameSettings.MasterVolume = 0
		game:GetService"RunService":Set3dRenderingEnabled(false)
		s = true
	end)
	if workspace.CurrentCamera then
		workspace.CurrentCamera.MaxAxisOfRotation = 0
	end
	return s
end

local function ksscripts()
if getreg then
for _, v in next, getreg() do
if type(v) == 'thread' then
pcall(function() task.cancel(v) end)
end
end
end
end

local antiAfkCon = nil
local function AntiIdle()
	 if getconnections then
        for _, c in getconnections(game:GetService"Players".LocalPlayer.Idled) do
            pcall(function() c:Disable() end)
            pcall(function() c:Disconnect() end)
        end
    end

    if antiAfkCon then
        antiAfkCon:Disconnect()
        antiAfkCon = nil
    end
    antiAfkCon = service.Players.LocalPlayer.Idled:Connect(function()
        service.VirtualUser:CaptureController()
        service.VirtualUser:ClickButton2(Vector2.zero)
    end)
end

local function cleanAnonymousData(root, options)
	if not options.Anonymous then return end

	local Players = service.Players
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then return end

	local UserIdStr = tostring(LocalPlayer.UserId)
	local PlayerName = LocalPlayer.Name
	local DisplayName = LocalPlayer.DisplayName

	local AnonConfig = typeof(options.Anonymous) == "table" and options.Anonymous or {
		UserId = "1",
		Name = "Roblox"
	}

	local AnonUserId = tostring(AnonConfig.UserId)
	local AnonName = AnonConfig.Name

	local function GsubCaseInsensitive(input, search, replacement)
		local inputLower = string.lower(input)
		search = string.lower(search)
		if not string.find(inputLower, search, 1, true) then
			return input
		end
		local lastFinish = 0
		local subStrings = {}
		local search_len = #search
		local input_len = #input
		while search_len <= input_len - lastFinish do
			local init = lastFinish + 1
			local start, finish = string.find(inputLower, search, init, true)
			if start == nil then
				break
			end
			table.insert(subStrings, string.sub(input, init, start - 1))
			lastFinish = finish
		end
		if lastFinish == 0 then
			return input
		end
		table.insert(subStrings, string.sub(input, lastFinish + 1))
		return tblconcat(subStrings, replacement)
	end

	local function ScrubValue(val)
		if type(val) == "string" then
			val = GsubCaseInsensitive(val, PlayerName, AnonName)
			if DisplayName then
				val = GsubCaseInsensitive(val, DisplayName, AnonName)
			end
			val = string.gsub(val, UserIdStr, AnonUserId)
			return val
		elseif type(val) == "number" and tostring(val) == UserIdStr then
			return tonumber(AnonUserId) or 1
		end
		return val
	end

	local function Process(inst)
		pcall(function()
			local OldName = inst.Name
			local NewName = ScrubValue(OldName)
			if NewName ~= OldName then
				inst.Name = NewName
			end
		end)

		if inst:IsA("StringValue") then
			pcall(function()
				inst.Value = ScrubValue(inst.Value)
			end)
		elseif inst:IsA("IntValue") or inst:IsA("NumberValue") then
			pcall(function()
				if tostring(inst.Value) == UserIdStr then
					inst.Value = tonumber(AnonUserId) or 1
				end
			end)
		elseif inst:IsA("TextLabel") or inst:IsA("TextBox") or inst:IsA("TextButton") then
			pcall(function()
				inst.Text = ScrubValue(inst.Text)
			end)
		end

		pcall(function()
			for AttrName, AttrVal in inst:GetAttributes() do
				local NewVal = ScrubValue(AttrVal)
				if NewVal ~= AttrVal then
					inst:SetAttribute(AttrName, NewVal)
				end
			end
		end)
		for _, child in inst:GetChildren() do
			Process(child)
		end
	end

	if root == game then
		for _, serviceObj in game:GetChildren() do
			local className = serviceObj.ClassName
			if className ~= "CoreGui" and className ~= "CorePackages" then
				Process(serviceObj)
			end
		end
	else
		local isTable = type(root) == "table"
		if isTable then
			for _, inst in root do
				Process(inst)
			end
		else
			Process(root)
		end
	end
end

DefaultSettings = {
	Serializer = {
		_Recurse = true,
		-- Decompilation
		Decompile = false,
		DecompileTimeout = 10,
		MaxThreads = 3,
		DecompileIgnore = {"Chat","CoreGui","CorePackages"},
		SaveScriptCache = false,
		SaveBytecode = false,
		-- Instance Selection
		NilInstances = false,
		RemovePlayerCharacters = true,
		SavePlayers = false,
		IsolateStarterPlayer = true,
		IsolateLocalPlayer = false,
		SavePlayerCharacters = false,
		-- Property Filtering
		IgnoreDefaultProps = true,
		IgnoreNotArchivable = true,
		-- Output & Formatting
		Binary = true,
		ShowStatus = true,
		ReadMe = true,
		Mode = "full",
		FilePath = false,
		Callback = false,
		Clipboard = false,
		AvoidFileOverwrite = false,
		-- Safety Features
		SafeMode = false,
		BoostFPS = false,
		KillAllScripts = false,
		AntiIdle = false,
		-- Data Cleanup
		Anonymous = false
	}
}

do
	if not table.clear then
		table.clear = function(t)
			for k in pairs(t) do t[k] = nil end
		end
	end

	if not string.split then
		string.split = function(s, sep)
			sep = sep or "%s"
			local res = {}
			if sep == "%s" then
				for token in s:gmatch("%S+") do res[#res+1] = token end
			else
				local pattern = "(.-)" .. sep
				local last_end = 1
				local s_len = #s
				local init = 1
				while true do
					local st, en, cap = s:find(pattern, init)
					if not st then break end
					res[#res+1] = cap
					init = en + 1
				end
				if init <= s_len then
					res[#res+1] = s:sub(init)
				end
			end
			return res
		end
	end

	if not table.move then
		table.move = function(a, f, e, t, dest)
			dest = dest or 1
			for i = f, e do a[dest + (i - f)] = a[i] end
			return a
		end
	end
end

local BufferCreate = buffer.create
local BufferWriteU8 = buffer.writeu8
local BufferWriteU16 = buffer.writeu16
local BufferWriteU32 = buffer.writeu32
local BufferWriteI8 = buffer.writei8
local BufferWriteI16 = buffer.writei16
local BufferWriteI32 = buffer.writei32
local BufferWriteF32 = buffer.writef32
local BufferWriteF64 = buffer.writef64
local BufferReadU8 = buffer.readu8
local BufferReadU32 = buffer.readu32
local BufferCopy = buffer.copy
local BufferToString = buffer.tostring
local BufferWriteString = buffer.writestring
local Bit32Extract = bit32.extract
local Bit32LRotate = bit32.lrotate
local MathFloor = math.floor
local MathCeil = math.ceil
local MathLog = math.log

local BufferWriter = {}
BufferWriter.__index = BufferWriter

local TempBuf4 = BufferCreate(4)
local TempBuf8 = BufferCreate(8)
local Log2Constant = 0.6931471805599453

function BufferWriter.New(InitialCapacity)
	local Self = setmetatable({}, BufferWriter)
	Self.Capacity = InitialCapacity or 1024
	Self.Buffer = BufferCreate(Self.Capacity)
	Self.Offset = 0
	return Self
end

function BufferWriter.EnsureCapacity(Self, SizeNeeded)
	local Needed = Self.Offset + SizeNeeded
	if Needed > Self.Capacity then
		local NewCapacity = Self.Capacity * 2
		if Needed > NewCapacity then
			NewCapacity = Needed * 2
		end
		local NewBuffer = BufferCreate(NewCapacity)
		BufferCopy(NewBuffer, 0, Self.Buffer, 0, Self.Offset)
		Self.Buffer = NewBuffer
		Self.Capacity = NewCapacity
	end
end

function BufferWriter.Skip(Self, Size)
	Self:EnsureCapacity(Size)
	Self.Offset = Self.Offset + Size
end

function BufferWriter.WriteUInt8(Self, Value)
	Self:EnsureCapacity(1)
	BufferWriteU8(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 1
end

function BufferWriter.WriteUInt8At(Self, TargetOffset, Value)
	BufferWriteU8(Self.Buffer, TargetOffset, Value)
end

function BufferWriter.WriteInt8(Self, Value)
	Self:EnsureCapacity(1)
	BufferWriteI8(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 1
end

function BufferWriter.WriteUInt16BE(Self, Value)
	Self:EnsureCapacity(2)
	BufferWriteU8(Self.Buffer, Self.Offset, Bit32Extract(Value, 8, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 1, Bit32Extract(Value, 0, 8))
	Self.Offset = Self.Offset + 2
end

function BufferWriter.WriteUInt32LE(Self, Value)
	Self:EnsureCapacity(4)
	BufferWriteU32(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 4
end

function BufferWriter.WriteUInt32BE(Self, Value)
	Self:EnsureCapacity(4)
	BufferWriteU8(Self.Buffer, Self.Offset, Bit32Extract(Value, 24, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 1, Bit32Extract(Value, 16, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 2, Bit32Extract(Value, 8, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 3, Bit32Extract(Value, 0, 8))
	Self.Offset = Self.Offset + 4
end

function BufferWriter.WriteInt32LE(Self, Value)
	Self:EnsureCapacity(4)
	BufferWriteI32(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 4
end

function BufferWriter.WriteInt32BE(Self, Value)
	Self:EnsureCapacity(4)
	local Unsigned = Value < 0 and (4294967296 + Value) or Value
	BufferWriteU8(Self.Buffer, Self.Offset, Bit32Extract(Unsigned, 24, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 1, Bit32Extract(Unsigned, 16, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 2, Bit32Extract(Unsigned, 8, 8))
	BufferWriteU8(Self.Buffer, Self.Offset + 3, Bit32Extract(Unsigned, 0, 8))
	Self.Offset = Self.Offset + 4
end

function BufferWriter.WriteFloat32LE(Self, Value)
	Self:EnsureCapacity(4)
	BufferWriteF32(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 4
end

function BufferWriter.WriteFloat32BE(Self, Value)
	Self:EnsureCapacity(4)
	BufferWriteF32(TempBuf4, 0, Value)
	local RawBits = BufferReadU32(TempBuf4, 0)
	Self:WriteUInt32BE(RawBits)
end

function BufferWriter.WriteFloat64LE(Self, Value)
	Self:EnsureCapacity(8)
	BufferWriteF64(Self.Buffer, Self.Offset, Value)
	Self.Offset = Self.Offset + 8
end

function BufferWriter.WriteFloat64BE(Self, Value)
	Self:EnsureCapacity(8)
	BufferWriteF64(TempBuf8, 0, Value)
	for Index = 7, 0, -1 do
		BufferWriteU8(Self.Buffer, Self.Offset, BufferReadU8(TempBuf8, Index))
		Self.Offset = Self.Offset + 1
	end
end

function BufferWriter.WriteInterleavedUInt32(Self, StartOffset, Index, Count, Value)
	local B1 = Bit32Extract(Value, 24, 8) -- MSB
	local B2 = Bit32Extract(Value, 16, 8)
	local B3 = Bit32Extract(Value, 8, 8)
	local B4 = Bit32Extract(Value, 0, 8)  -- LSB

	BufferWriteU8(Self.Buffer, StartOffset + Index, B1)
	BufferWriteU8(Self.Buffer, StartOffset + Index + Count, B2)
	BufferWriteU8(Self.Buffer, StartOffset + Index + Count * 2, B3)
	BufferWriteU8(Self.Buffer, StartOffset + Index + Count * 3, B4)
end

function BufferWriter.WriteInterleavedUInt64(Self, StartOffset, Index, Count, Value)
	local High = MathFloor(Value / 4294967296)
	local Low = Value % 4294967296
	BufferWriteU32(TempBuf8, 0, Low)
	BufferWriteU32(TempBuf8, 4, High)

	for B = 0, 7 do
		local ByteVal = BufferReadU8(TempBuf8, 7 - B)
		BufferWriteU8(Self.Buffer, StartOffset + Index + Count * B, ByteVal)
	end
end

function BufferWriter.WriteRobloxFloat32(Self, Value)
	BufferWriteF32(TempBuf4, 0, Value)
	local RawBits = BufferReadU32(TempBuf4, 0)
	local Rotated = Bit32LRotate(RawBits, 1)
	Self:WriteUInt32BE(Rotated)
end

function BufferWriter.GetRotatedFloatBits(Self, Value)
	BufferWriteF32(TempBuf4, 0, Value)
	local RawBits = BufferReadU32(TempBuf4, 0)
	return Bit32LRotate(RawBits, 1)
end

function BufferWriter.WriteRawString(Self, Value)
	local Length = #Value
	Self:EnsureCapacity(Length)
	BufferWriteString(Self.Buffer, Self.Offset, Value, Length)
	Self.Offset = Self.Offset + Length
end

function BufferWriter.WriteSizedStringLE(Self, Value)
	local Length = #Value
	Self:WriteUInt32LE(Length)
	Self:WriteRawString(Value)
end

function BufferWriter.WriteSizedStringBE(Self, Value)
	local Length = #Value
	Self:WriteUInt32BE(Length)
	Self:WriteRawString(Value)
end

function BufferWriter.ToString(Self)
	return BufferToString(Self.Buffer, 0, Self.Offset)
end

function BufferWriter.Reset(Self)
	Self.Offset = 0
end

Serializer = (function()
	local Serializer = {}

	local oldIndex,getnspval,getbspval,gethiddenprop,getnilinstances,getpcd,encodeBase64,lz4compress,hashmd5
	local classes,saveProps,testInsts = {},{},{}
	local FastCFrameMap = {}
	local tostring = tostring
	local format = string.format
	local gsub = string.gsub
	local sub = string.sub
	local getChildren = game.GetChildren
	local isa = game.IsA
	local components = CFrame.new(0,0,0).GetComponents
	local httpService = service.HttpService
	local urlEncode = httpService.UrlEncode
	local lrotate = bit32.lrotate
	local tableCreate = table.create
	local tblmove = table.move
	local tostring = tostring
	local tblsort = table.sort
	local tblconcat = table.concat
	local select = select
	local unpack = unpack
	local split = string.split
	local s_rep = string.rep
	local nilSafe = {}
	local gameId

	local b_create = buffer.create
	local b_writeu8 = buffer.writeu8
	local b_writeu16 = buffer.writeu16
	local b_writei16 = buffer.writei16
	local b_writeu32 = buffer.writeu32
	local b_writef32 = buffer.writef32
	local b_writef64 = buffer.writef64
	local b_readu8 = buffer.readu8
	local b_readu32 = buffer.readu32
	local b_readstring = buffer.readstring
	local b_writestring = buffer.writestring
	local b_tostring = buffer.tostring
	local b32_extract = bit32.extract
	local b32_lrotate = bit32.lrotate
	local m_floor = math.floor

	local function _fallbackReader(obj, name) return obj[name] end
	local function _oldIndexReader(obj, name) return oldIndex(obj, name) end

	local StaticPackBuf = b_create(4096)
	local s_pack, s_unpack
	if buffer then
		function s_pack(fmt, ...)
			local args = { ... }
			local offset, fmt_pos, arg_idx = 0, 1, 1
			while fmt_pos <= #fmt do
				local char = fmt:sub(fmt_pos, fmt_pos)
				if char == '<' or char == '>' or char == '=' then
					fmt_pos = fmt_pos + 1
				elseif char == 'I' then
					fmt_pos = fmt_pos + 1
					if fmt:sub(fmt_pos, fmt_pos) == '4' then
						buffer.writeu32(StaticPackBuf, offset, args[arg_idx])
						offset = offset + 4; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
					end
				elseif char == 'i' then
					fmt_pos = fmt_pos + 1
					if fmt:sub(fmt_pos, fmt_pos) == '4' then
						buffer.writei32(StaticPackBuf, offset, args[arg_idx])
						offset = offset + 4; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
					end
				elseif char == 'f' then
					buffer.writef32(StaticPackBuf, offset, args[arg_idx]); offset = offset + 4; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
				elseif char == 'd' then
					buffer.writef64(StaticPackBuf, offset, args[arg_idx]); offset = offset + 8; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
				elseif char == 'b' then
					buffer.writei8(StaticPackBuf, offset, args[arg_idx] or 0); offset = offset + 1; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
				elseif char == 'B' then
					buffer.writeu8(StaticPackBuf, offset, args[arg_idx] or 0); offset = offset + 1; arg_idx = arg_idx + 1; fmt_pos = fmt_pos + 1
				else
					fmt_pos = fmt_pos + 1
				end
			end
			return buffer.readstring(StaticPackBuf, 0, offset)
		end

		function s_unpack(fmt, data, offset)
			offset = offset or 1
			local buf_offset = offset - 1
			local buf = buffer.fromstring(data)
			local results, fmt_pos = {}, 1
			while fmt_pos <= #fmt do
				local char = fmt:sub(fmt_pos, fmt_pos)
				if char == '<' or char == '>' or char == '=' then
					fmt_pos = fmt_pos + 1
				elseif char == 'I' then
					fmt_pos = fmt_pos + 1
					if fmt:sub(fmt_pos, fmt_pos) == '4' then
						results[#results+1] = buffer.readu32(buf, buf_offset); buf_offset = buf_offset + 4; fmt_pos = fmt_pos + 1
					end
				elseif char == 'i' then
					fmt_pos = fmt_pos + 1
					if fmt:sub(fmt_pos, fmt_pos) == '4' then
						results[#results+1] = buffer.readi32(buf, buf_offset); buf_offset = buf_offset + 4; fmt_pos = fmt_pos + 1
					end
				elseif char == 'f' then
					results[#results+1] = buffer.readf32(buf, buf_offset); buf_offset = buf_offset + 4; fmt_pos = fmt_pos + 1
				elseif char == 'd' then
					results[#results+1] = buffer.readf64(buf, buf_offset); buf_offset = buf_offset + 8; fmt_pos = fmt_pos + 1
				elseif char == 'b' then
					results[#results+1] = buffer.readi8(buf, buf_offset); buf_offset = buf_offset + 1; fmt_pos = fmt_pos + 1
				elseif char == 'B' then
					results[#results+1] = buffer.readu8(buf, buf_offset); buf_offset = buf_offset + 1; fmt_pos = fmt_pos + 1
				else
					fmt_pos = fmt_pos + 1
				end
			end
			return unpack(results)
		end
	else
		s_pack = string.pack; s_unpack = string.unpack
	end
	if not s_pack or not s_unpack then
		local _msg = "string.pack/string.unpack not available; serialization requires Lua 5.3+ or a buffer implementation"
		s_pack = function() error(_msg) end
		s_unpack = function() error(_msg) end
	end
	--[[
	local propBypass = {
		["BasePart"] = {
			["Size"] = true,
			["Color"] = true,
		},
		["Part"] = {
			["Shape"] = true
		},
		["Fire"] = {
			["Heat"] = true,
			["Size"] = true,
		},
		["Smoke"] = {
			["Opacity"] = true,
			["RiseVelocity"] = true,
			["Size"] = true,
		},
		["DoubleConstrainedValue"] = {
			["Value"] = true
		},
		["IntConstrainedValue"] = {
			["Value"] = true
		},
		["TrussPart"] = {
			["Style"] = true
		}
	}
	]]
	local propBypass = {
		["BasePart"] = {
			["Color"] = true, -- No Coloruint8
		},
	}


	local propFilter = {
		["WeldConstraint"] = {
		["Part0Internal"] = true,
		["Part1Internal"] = true
		},

		["BasePart"] = {
			["Color3uint8"] = true
		},
		["BaseScript"] = {
			["LinkedSource"] = true
		},
		["Script"] = {
			["Source"] = true
		},
		["ModuleScript"] = {
			["LinkedSource"] = true,
			["Source"] = true
		},
		["Players"] = {
			["CharacterAutoLoads"] = true
		},
		["BillboardGui"] = {
			["PlayerToHideFrom"] = true
		},
		["Instance"] = {
			["SourceAssetId"] = true,
			["PropertyStatusStudio"] = true
		},
		["Model"] = {
			["WorldPivotData"] = true -- No OptionalCoordinateFrame
		},
		["TerrainRegion"] = { -- No Vector3int16
			["ExtentsMax"] = true,
			["ExtentsMin"] = true
		}
	}

	local xmlReplacePattern = "['\"<>&\0]"

	local xmlReplace = {
		["'"] = "&apos;",
		["\""] = "&quot;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;",
		["\0"] = ""
	}

	local serviceBlacklist = {
		["CoreGui"] = true,
		["CorePackages"] = true,
	}

	local nilClassParents = {
		["Attachment"] = "Part",
		["Bone"] = "Part",
		["Animator"] = "Humanoid",
		["SurfaceAppearance"] = "MeshPart"
	}

	local valueConverters = {
		["bool"] = function(name,val)
			return '\n<bool name="'..name..'">'..(val and "true" or "false")..'</bool>'
		end,
		["int"] = function(name,val)
			return format('\n<int name="%s">%d</int>',name,val)
		end,
		["int64"] = function(name,val)
			return format('\n<int64 name="%s">%s</int64>',name,tostring(val))
		end,
		["float"] = function(name,val)
			return format('\n<float name="%s">%.12f</float>',name,val)
		end,
		["double"] = function(name,val)
			return format('\n<double name="%s">%.12f</double>',name,val)
		end,
		["string"] = function(name,val)
			return '\n<string name="'..name..'">'..gsub(val,xmlReplacePattern,xmlReplace)..'</string>'
		end,
		["BrickColor"] = function(name,val)
			return format('\n<int name="%s">%d</int>',name,val.Number)
		end,
		["Vector2"] = function(name,val)
			return format('\n<Vector2 name="%s">\n<X>%.12f</X>\n<Y>%.12f</Y>\n</Vector2>',name,val.X,val.Y)
		end,
		["Vector3"] = function(name,val)
			return format('\n<Vector3 name="%s">\n<X>%.12f</X>\n<Y>%.12f</Y>\n<Z>%.12f</Z>\n</Vector3>',name,val.X,val.Y,val.Z)
		end,
		["Vector3int16"] = function(name,val)
			return format('\n<Vector3int16 name="%s">\n<X>%d</X>\n<Y>%d</Y>\n<Z>%d</Z>\n</Vector3int16>',name,val.X,val.Y,val.Z)
		end,
		["CFrame"] = function(name,val)
			return format('\n<CoordinateFrame name="%s">\n<X>%.12f</X>\n<Y>%.12f</Y>\n<Z>%.12f</Z>\n<R00>%.12f</R00>\n<R01>%.12f</R01>\n<R02>%.12f</R02>\n<R10>%.12f</R10>\n<R11>%.12f</R11>\n<R12>%.12f</R12>\n<R20>%.12f</R20>\n<R21>%.12f</R21>\n<R22>%.12f</R22>\n</CoordinateFrame>',name,components(val))
		end,
		["Content"] = function(name,val)
			if sub(val,1,15) == "rbxgameasset://" then
				val = format("https://assetdelivery.roblox.com/v1/asset?universeId=%d&assetName=%s&skipSigningScripts=1",gameId,urlEncode(httpService,sub(val,16)))
			end
			return '\n<Content name="'..name..'"><url>'..gsub(val,xmlReplacePattern,xmlReplace)..'</url></Content>'
		end,
		["UDim"] = function(name,val)
			return format('\n<UDim name="%s">\n<S>%.12f</S>\n<O>%d</O>\n</UDim>',name,val.Scale,val.Offset)
		end,
		["UDim2"] = function(name,val)
			local x = val.X
			local y = val.Y
			return format('\n<UDim2 name="%s">\n<XS>%.12f</XS>\n<XO>%d</XO>\n<YS>%.12f</YS>\n<YO>%d</YO>\n</UDim2>',name,x.Scale,x.Offset,y.Scale,y.Offset)
		end,
		["Color3"] = function(name,val)
			return format('\n<Color3 name="%s">\n<R>%.12f</R>\n<G>%.12f</G>\n<B>%.12f</B>\n</Color3>',name,val.R,val.G,val.B)
		end,
		["NumberRange"] = function(name,val)
			return '\n<NumberRange name="'..name..'">'..tostring(val)..'</NumberRange>'
		end,
		["NumberSequence"] = function(name,val)
			return '\n<NumberSequence name="'..name..'">'..tostring(val)..'</NumberSequence>'
		end,
		["ColorSequence"] = function(name,val)
			return '\n<ColorSequence name="'..name..'">'..tostring(val)..'</ColorSequence>'
		end,
		["Rect"] = function(name,val)
			local min = val.Min
			local max = val.Max
			return format('\n<Rect2D name="%s">\n<min>\n<X>%.12f</X>\n<Y>%.12f</Y>\n</min>\n<max>\n<X>%.12f</X>\n<Y>%.12f</Y>\n</max>\n</Rect2D>',name,min.X,min.Y,max.X,max.Y)
		end,
		["PhysicalProperties"] = function(name,val)
			if val then
				return format('\n<PhysicalProperties name="%s">\n<CustomPhysics>true</CustomPhysics>\n<Density>%.12f</Density>\n<Friction>%.12f</Friction>\n<Elasticity>%.12f</Elasticity>\n<FrictionWeight>%.12f</FrictionWeight>\n<ElasticityWeight>%.12f</ElasticityWeight>\n</PhysicalProperties>',name,val.Density,val.Friction,val.Elasticity,val.FrictionWeight,val.ElasticityWeight)
			else
				return '\n<PhysicalProperties name="'..name..'">\n<CustomPhysics>false</CustomPhysics>\n</PhysicalProperties>'
			end
		end,
		["Faces"] = function(name,val)
			local faceInt = (val.Front and 32 or 0) + (val.Bottom and 16 or 0) + (val.Left and 8 or 0) + (val.Back and 4 or 0) + (val.Top and 2 or 0) + (val.Right and 1 or 0)
			return format('\n<Faces name="%s">\n<faces>%d</faces>\n</Faces>',name,faceInt)
		end,
		["Axes"] = function(name,val)
			local axisInt = (val.Z and 4 or 0) + (val.Y and 2 or 0) + (val.X and 1 or 0)
			return format('\n<Axes name="%s">\n<axes>%d</axes>\n</Axes>',name,axisInt)
		end,
		["Ray"] = function(name,val)
			local origin = val.Origin
			local direction = val.Direction
			return format('\n<Ray name="%s">\n<origin>\n<X>%.12f</X>\n<Y>%.12f</Y>\n<Z>%.12f</Z>\n</origin>\n<direction>\n<X>%.12f</X>\n<Y>%.12f</Y>\n<Z>%.12f</Z>\n</direction>\n</Ray>',name,origin.X,origin.Y,origin.Z,direction.X,direction.Y,direction.Z)
		end,
		["BinaryString"] = function(name,val)
			if val then
				return '\n<BinaryString name="'..name..'"><![CDATA['..val..']]></BinaryString>'
			else
				return ""
			end
		end,
		["ProtectedString"] = function(name,val)
			return '\n<ProtectedString name="'..name..'">'..gsub(val,xmlReplacePattern,xmlReplace)..'</ProtectedString>'
		end,
		["SharedString"] = function(name,val)
			return '\n<SharedString name="'..name..'">'..val..'</SharedString>'
		end,
		["SecurityCapabilities"] = function(name,val)
			return format('\n<SecurityCapabilities name="%s">%d</SecurityCapabilities>',name,val or 0)
		end,
		["OptionalCoordinateFrame"] = function(name,val)
			if val then
				return format('\n<OptionalCoordinateFrame name="%s">\n<CFrame>\n<X>%.12f</X>\n<Y>%.12f</Y>\n<Z>%.12f</Z>\n<R00>%.12f</R00>\n<R01>%.12f</R01>\n<R02>%.12f</R02>\n<R10>%.12f</R10>\n<R11>%.12f</R11>\n<R12>%.12f</R12>\n<R20>%.12f</R20>\n<R21>%.12f</R21>\n<R22>%.12f</R22>\n</CFrame>\n</OptionalCoordinateFrame>',name,components(val))
			else
				return '\n<OptionalCoordinateFrame name="'..name..'"></OptionalCoordinateFrame>'
			end
		end,
	}

	local binaryDataTypes = {
		["string"] = "\1",
		["ContentId"] = "\1",
		["BinaryString"] = "\1",
		["bool"] = "\2",
		["int"] = "\3",
		["float"] = "\4",
		["double"] = "\5",
		["UDim"] = "\6",
		["UDim2"] = "\7",
		["Ray"] = "\8",
		["Faces"] = "\9",
		["Axes"] = "\10",
		["BrickColor"] = "\11",
		["Color3"] = "\12",
		["Vector2"] = "\13",
		["Vector3"] = "\14",
		["CFrame"] = "\16",
		["Enum"] = "\18",
		["Referent"] = "\19",
		["Vector3int16"] = "\20",
		["NumberSequence"] = "\21",
		["ColorSequence"] = "\22",
		["NumberRange"] = "\23",
		["Rect"] = "\24",
		["PhysicalProperties"] = "\25",
		["Color3uint8"] = "\26",
		["int64"] = "\27",
		["SharedString"] = "\28",
		["OptionalCoordinateFrame"] = "\30",
		["Font"] = "\32"
	}

	local binaryCFrameMap = {
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = "\2",
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = "\3",
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = "\5",
		["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = "\6",
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = "\7",
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = "\9",
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = "\10",
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = "\12",
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = "\13",
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = "\14",
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = "\16",
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = "\17",
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = "\20",
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = "\21",
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = "\23",
		["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = "\24",
		["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = "\25",
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = "\27",
		["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = "\28",
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = "\30",
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = "\31",
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = "\32",
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = "\34",
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = "\35",
	}

	local binaryPropHandlers = {
		["string"] = function(objs,name,func)
			local szObjs = #objs
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			local totalSize = 0
			local vals = tableCreate(szObjs)
			for i = 1, szObjs do
				local val = reader(objs[i], name) or ""
				vals[i] = val
				totalSize = totalSize + 4 + #val
			end
			local buf = b_create(totalSize)
			local offset = 0
			for i = 1, szObjs do
				local str = vals[i]
				local len = #str
				b_writeu32(buf, offset, len)
				b_writestring(buf, offset + 4, str, len)
				offset = offset + 4 + len
			end
			return b_tostring(buf)
		end,

		["ContentId"] = function(objs,name,func)
			local szObjs = #objs
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			local totalSize = 0
			local vals = tableCreate(szObjs)
			for i = 1, szObjs do
				local val = reader(objs[i], name) or ""
				vals[i] = val
				totalSize = totalSize + 4 + #val
			end
			local buf = b_create(totalSize)
			local offset = 0
			for i = 1, szObjs do
				local str = vals[i]
				local len = #str
				b_writeu32(buf, offset, len)
				b_writestring(buf, offset + 4, str, len)
				offset = offset + 4 + len
			end
			return b_tostring(buf)
		end,
		["BinaryString"] = function(objs,name,func)
			if not getbspval then return end
			local szObjs = #objs
			local totalSize = 0
			local vals = tableCreate(szObjs)
			for i = 1, szObjs do
				local val = getbspval(objs[i], name) or ""
				vals[i] = val
				totalSize = totalSize + 4 + #val
			end
			local buf = b_create(totalSize)
			local offset = 0
			for i = 1, szObjs do
				local str = vals[i]
				local len = #str
				b_writeu32(buf, offset, len)
				b_writestring(buf, offset + 4, str, len)
				offset = offset + 4 + len
			end
			return b_tostring(buf)
		end,
		["bool"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(szObjs)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				b_writeu8(buf, i - 1, reader(objs[i], name) and 1 or 0)
			end
			return b_tostring(buf)
		end,
		["int"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(4 * szObjs)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				local zigzag = (val < 0) and (2 * -val - 1) or (2 * val)
				local base = i - 1
				b_writeu8(buf, base, b32_extract(zigzag, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(zigzag, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(zigzag, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(zigzag, 0, 8))
			end
			return b_tostring(buf)
		end,
		["float"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(4 * szObjs)
			local temp = b_create(4)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				b_writef32(temp, 0, reader(objs[i], name))
				local rot = b32_lrotate(b_readu32(temp, 0), 1)
				local base = i - 1
				b_writeu8(buf, base, b32_extract(rot, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(rot, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(rot, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(rot, 0, 8))
			end
			return b_tostring(buf)
		end,
		["double"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(8 * szObjs)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			local offset = 0
			for i = 1, szObjs do
				b_writef64(buf, offset, reader(objs[i], name))
				offset = offset + 8
			end
			return b_tostring(buf)
		end,
		["UDim"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(8 * SzObjs)
			Writer:Skip(8 * SzObjs)
			for I = 1, SzObjs do
				local Val
				if Func then
					Val = Func(Objs[I], Name)
				elseif oldIndex then
					Val = oldIndex(Objs[I], Name)
				else
					Val = Objs[I][Name]
				end
	
				local ScaleRotated = Writer:GetRotatedFloatBits(Val.Scale)
				local OffsetTransformed = Val.Offset < 0 and (2 * -Val.Offset - 1) or (2 * Val.Offset)
	
				Writer:WriteInterleavedUInt32(0, I - 1, SzObjs, ScaleRotated)
				Writer:WriteInterleavedUInt32(4 * SzObjs, I - 1, SzObjs, OffsetTransformed)
			end
			return Writer:ToString()
		end,

		["UDim2"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(16 * SzObjs)
			Writer:Skip(16 * SzObjs)
			for I = 1, SzObjs do
				local Val
				if Func then
					Val = Func(Objs[I], Name)
				elseif oldIndex then
					Val = oldIndex(Objs[I], Name)
				else
					Val = Objs[I][Name]
				end
				local X = Val.X
				local Y = Val.Y
	
				local XScaleRotated = Writer:GetRotatedFloatBits(X.Scale)
				local YScaleRotated = Writer:GetRotatedFloatBits(Y.Scale)
				local XOffsetTransformed = X.Offset < 0 and (2 * -X.Offset - 1) or (2 * X.Offset)
				local YOffsetTransformed = Y.Offset < 0 and (2 * -Y.Offset - 1) or (2 * Y.Offset)
	
				Writer:WriteInterleavedUInt32(0, I - 1, SzObjs, XScaleRotated)
				Writer:WriteInterleavedUInt32(4 * SzObjs, I - 1, SzObjs, YScaleRotated)
				Writer:WriteInterleavedUInt32(8 * SzObjs, I - 1, SzObjs, XOffsetTransformed)
				Writer:WriteInterleavedUInt32(12 * SzObjs, I - 1, SzObjs, YOffsetTransformed)
			end
			return Writer:ToString()
		end,
		["Ray"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(24 * SzObjs)
			for I = 1, SzObjs do
				local Val
				if Func then
					Val = Func(Objs[I], Name)
				elseif oldIndex then
					Val = oldIndex(Objs[I], Name)
				else
					Val = Objs[I][Name]
				end
				local Origin = Val.Origin
				local Dir = Val.Direction
	
				Writer:WriteFloat32LE(Origin.X)
				Writer:WriteFloat32LE(Origin.Y)
				Writer:WriteFloat32LE(Origin.Z)
				Writer:WriteFloat32LE(Dir.X)
				Writer:WriteFloat32LE(Dir.Y)
				Writer:WriteFloat32LE(Dir.Z)
			end
			return Writer:ToString()
		end,
		["Faces"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				local FaceInt = (Val.Front and 32 or 0) + (Val.Bottom and 16 or 0) + (Val.Left and 8 or 0) + (Val.Back and 4 or 0) + (Val.Top and 2 or 0) + (Val.Right and 1 or 0)
				Writer:WriteUInt8(FaceInt)
			end
			return Writer:ToString()
		end,

		["Axes"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				local AxisInt = (Val.Z and 4 or 0) + (Val.Y and 2 or 0) + (Val.X and 1 or 0)
				Writer:WriteUInt8(AxisInt)
			end
			return Writer:ToString()
		end,

		["BrickColor"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(4 * SzObjs)
			Writer:Skip(4 * SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				Writer:WriteInterleavedUInt32(0, I - 1, SzObjs, Val.Number)
			end
			return Writer:ToString()
		end,
		["Color3"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(12 * szObjs)
			local temp = b_create(4)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
	
				b_writef32(temp, 0, val.R); local rRot = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.G); local gRot = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.B); local bRot = b32_lrotate(b_readu32(temp, 0), 1)
	
				local base = i - 1
				b_writeu8(buf, base, b32_extract(rRot, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(rRot, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(rRot, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(rRot, 0, 8))
	
				local gBase = 4 * szObjs + base
				b_writeu8(buf, gBase, b32_extract(gRot, 24, 8))
				b_writeu8(buf, gBase + szObjs, b32_extract(gRot, 16, 8))
				b_writeu8(buf, gBase + szObjs * 2, b32_extract(gRot, 8, 8))
				b_writeu8(buf, gBase + szObjs * 3, b32_extract(gRot, 0, 8))
	
				local bBase = 8 * szObjs + base
				b_writeu8(buf, bBase, b32_extract(bRot, 24, 8))
				b_writeu8(buf, bBase + szObjs, b32_extract(bRot, 16, 8))
				b_writeu8(buf, bBase + szObjs * 2, b32_extract(bRot, 8, 8))
				b_writeu8(buf, bBase + szObjs * 3, b32_extract(bRot, 0, 8))
			end
			return b_tostring(buf)
		end,
		["Vector2"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(8 * SzObjs)
			Writer:Skip(8 * SzObjs)
			for I = 1, SzObjs do
				local Val
				if Func then
					Val = Func(Objs[I], Name)
				elseif oldIndex then
					Val = oldIndex(Objs[I], Name)
				else
					Val = Objs[I][Name]
				end
	
				local XRotated = Writer:GetRotatedFloatBits(Val.X)
				local YRotated = Writer:GetRotatedFloatBits(Val.Y)
	
				Writer:WriteInterleavedUInt32(0, I - 1, SzObjs, XRotated)
				Writer:WriteInterleavedUInt32(4 * SzObjs, I - 1, SzObjs, YRotated)
			end
			return Writer:ToString()
		end,
		["Vector3"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(12 * szObjs)
			local temp = b_create(4)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
	
				b_writef32(temp, 0, val.X); local xRot = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.Y); local yRot = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.Z); local zRot = b32_lrotate(b_readu32(temp, 0), 1)
	
				local base = i - 1
				b_writeu8(buf, base, b32_extract(xRot, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(xRot, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(xRot, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(xRot, 0, 8))
	
				local yBase = 4 * szObjs + base
				b_writeu8(buf, yBase, b32_extract(yRot, 24, 8))
				b_writeu8(buf, yBase + szObjs, b32_extract(yRot, 16, 8))
				b_writeu8(buf, yBase + szObjs * 2, b32_extract(yRot, 8, 8))
				b_writeu8(buf, yBase + szObjs * 3, b32_extract(yRot, 0, 8))
	
				local zBase = 8 * szObjs + base
				b_writeu8(buf, zBase, b32_extract(zRot, 24, 8))
				b_writeu8(buf, zBase + szObjs, b32_extract(zRot, 16, 8))
				b_writeu8(buf, zBase + szObjs * 2, b32_extract(zRot, 8, 8))
				b_writeu8(buf, zBase + szObjs * 3, b32_extract(zRot, 0, 8))
			end
			return b_tostring(buf)
		end,
		["CFrame"] = function(objs,name,func)
			local szObjs = #objs
			local temp = b_create(36)
			local buf = b_create(49 * szObjs)
			local offset = 0
			local positions = tableCreate(szObjs)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
	
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				positions[i] = val.Position
	
				local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = components(val)
				b_writef32(temp, 0, R00) b_writef32(temp, 4, R01) b_writef32(temp, 8, R02)
				b_writef32(temp, 12, R10) b_writef32(temp, 16, R11) b_writef32(temp, 20, R12)
				b_writef32(temp, 24, R20) b_writef32(temp, 28, R21) b_writef32(temp, 32, R22)
	
				local strKey = b_tostring(temp)
				local mappedID = binaryCFrameMap[strKey]
	
				if mappedID then
					b_writestring(buf, offset, mappedID, 1)
					offset = offset + 1
				else
					b_writeu8(buf, offset, 0)
					b_writestring(buf, offset + 1, strKey, 36)
					offset = offset + 37
				end
			end
	
			local posStart = offset
			offset = offset + 12 * szObjs
	
			local temp2 = b_create(4)
			for i = 1, szObjs do
				local pos = positions[i]
				b_writef32(temp2, 0, pos.X); local xRot = b32_lrotate(b_readu32(temp2, 0), 1)
				b_writef32(temp2, 0, pos.Y); local yRot = b32_lrotate(b_readu32(temp2, 0), 1)
				b_writef32(temp2, 0, pos.Z); local zRot = b32_lrotate(b_readu32(temp2, 0), 1)
	
				local base = i - 1
				b_writeu8(buf, posStart + base, b32_extract(xRot, 24, 8))
				b_writeu8(buf, posStart + base + szObjs, b32_extract(xRot, 16, 8))
				b_writeu8(buf, posStart + base + szObjs * 2, b32_extract(xRot, 8, 8))
				b_writeu8(buf, posStart + base + szObjs * 3, b32_extract(xRot, 0, 8))
	
				local yBase = posStart + 4 * szObjs + base
				b_writeu8(buf, yBase, b32_extract(yRot, 24, 8))
				b_writeu8(buf, yBase + szObjs, b32_extract(yRot, 16, 8))
				b_writeu8(buf, yBase + szObjs * 2, b32_extract(yRot, 8, 8))
				b_writeu8(buf, yBase + szObjs * 3, b32_extract(yRot, 0, 8))
	
				local zBase = posStart + 8 * szObjs + base
				b_writeu8(buf, zBase, b32_extract(zRot, 24, 8))
				b_writeu8(buf, zBase + szObjs, b32_extract(zRot, 16, 8))
				b_writeu8(buf, zBase + szObjs * 2, b32_extract(zRot, 8, 8))
				b_writeu8(buf, zBase + szObjs * 3, b32_extract(zRot, 0, 8))
			end
	
			return b_tostring(buf, 0, offset)
		end,
		["Enum"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(4 * szObjs)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				local enumVal = val and val.Value or 0
				local base = i - 1
				b_writeu8(buf, base, b32_extract(enumVal, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(enumVal, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(enumVal, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(enumVal, 0, 8))
			end
			return b_tostring(buf)
		end,
		["Vector3int16"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(6 * SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				Writer:EnsureCapacity(6)
				buffer.writei16(Writer.Buffer, Writer.Offset, Val.X)
				buffer.writei16(Writer.Buffer, Writer.Offset + 2, Val.Y)
				buffer.writei16(Writer.Buffer, Writer.Offset + 4, Val.Z)
				Writer.Offset = Writer.Offset + 6
			end
			return Writer:ToString()
		end,

		["NumberSequence"] = function(objs,name,func)
			local szObjs = #objs
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			local temp_bufs = tableCreate(szObjs)
			local totalSize = 0
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				local kps = val.Keypoints
				local n_kps = #kps
				local seq_buf = b_create(4 + 12 * n_kps)
				b_writeu32(seq_buf, 0, n_kps)
				local offset = 4
				for j = 1, n_kps do
					local kp = kps[j]
					b_writef32(seq_buf, offset, kp.Time)
					b_writef32(seq_buf, offset + 4, kp.Value)
					b_writef32(seq_buf, offset + 8, kp.Envelope)
					offset = offset + 12
				end
				temp_bufs[i] = b_tostring(seq_buf)
				totalSize = totalSize + offset
			end
			local buf = b_create(totalSize)
			local offset = 0
			for i = 1, szObjs do
				local str = temp_bufs[i]
				local len = #str
				b_writestring(buf, offset, str, len)
				offset = offset + len
			end
			return b_tostring(buf)
		end,
		["ColorSequence"] = function(objs,name,func)
			local szObjs = #objs
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			local temp_bufs = tableCreate(szObjs)
			local totalSize = 0
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				local kps = val.Keypoints
				local n_kps = #kps
				local seq_buf = b_create(4 + 20 * n_kps)
				b_writeu32(seq_buf, 0, n_kps)
				local offset = 4
				for j = 1, n_kps do
					local kp = kps[j]
					local col = kp.Value
					b_writef32(seq_buf, offset, kp.Time)
					b_writef32(seq_buf, offset + 4, col.R)
					b_writef32(seq_buf, offset + 8, col.G)
					b_writef32(seq_buf, offset + 12, col.B)
					b_writef32(seq_buf, offset + 16, 0)
					offset = offset + 20
				end
				temp_bufs[i] = b_tostring(seq_buf)
				totalSize = totalSize + offset
			end
			local buf = b_create(totalSize)
			local offset = 0
			for i = 1, szObjs do
				local str = temp_bufs[i]
				local len = #str
				b_writestring(buf, offset, str, len)
				offset = offset + len
			end
			return b_tostring(buf)
		end,
		["NumberRange"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(8 * SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				Writer:WriteFloat32LE(Val.Min)
				Writer:WriteFloat32LE(Val.Max)
			end
			return Writer:ToString()
		end,
		["Rect"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(16 * szObjs)
			local temp = b_create(4)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				b_writef32(temp, 0, val.Min.X); local x1 = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.Min.Y); local y1 = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.Max.X); local x2 = b32_lrotate(b_readu32(temp, 0), 1)
				b_writef32(temp, 0, val.Max.Y); local y2 = b32_lrotate(b_readu32(temp, 0), 1)
	
				local base = i - 1
				b_writeu8(buf, base, b32_extract(x1, 24, 8))
				b_writeu8(buf, base + szObjs, b32_extract(x1, 16, 8))
				b_writeu8(buf, base + szObjs * 2, b32_extract(x1, 8, 8))
				b_writeu8(buf, base + szObjs * 3, b32_extract(x1, 0, 8))
	
				local y1Base = 4 * szObjs + base
				b_writeu8(buf, y1Base, b32_extract(y1, 24, 8))
				b_writeu8(buf, y1Base + szObjs, b32_extract(y1, 16, 8))
				b_writeu8(buf, y1Base + szObjs * 2, b32_extract(y1, 8, 8))
				b_writeu8(buf, y1Base + szObjs * 3, b32_extract(y1, 0, 8))
	
				local x2Base = 8 * szObjs + base
				b_writeu8(buf, x2Base, b32_extract(x2, 24, 8))
				b_writeu8(buf, x2Base + szObjs, b32_extract(x2, 16, 8))
				b_writeu8(buf, x2Base + szObjs * 2, b32_extract(x2, 8, 8))
				b_writeu8(buf, x2Base + szObjs * 3, b32_extract(x2, 0, 8))
	
				local y2Base = 12 * szObjs + base
				b_writeu8(buf, y2Base, b32_extract(y2, 24, 8))
				b_writeu8(buf, y2Base + szObjs, b32_extract(y2, 16, 8))
				b_writeu8(buf, y2Base + szObjs * 2, b32_extract(y2, 8, 8))
				b_writeu8(buf, y2Base + szObjs * 3, b32_extract(y2, 0, 8))
			end
			return b_tostring(buf)
		end,
		["PhysicalProperties"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(21 * szObjs)
			local offset = 0
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				if val then
					b_writeu8(buf, offset, 1)
					b_writef32(buf, offset + 1, val.Density)
					b_writef32(buf, offset + 5, val.Friction)
					b_writef32(buf, offset + 9, val.Elasticity)
					b_writef32(buf, offset + 13, val.FrictionWeight)
					b_writef32(buf, offset + 17, val.ElasticityWeight)
					offset = offset + 21
				else
					b_writeu8(buf, offset, 0)
					offset = offset + 1
				end
			end
			return b_tostring(buf, 0, offset)
		end,
		["Color3uint8"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(4 * SzObjs)
			for I = 1, SzObjs do
				local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
				Writer:WriteUInt8(1)
				Writer:WriteInt8(Val.R)
				Writer:WriteInt8(Val.G)
				Writer:WriteInt8(Val.B)
			end
			return Writer:ToString()
		end,
		["int64"] = function(objs,name,func)
			local szObjs = #objs
			local buf = b_create(8 * szObjs)
			local temp = b_create(8)
			local reader = func or (oldIndex and _oldIndexReader) or _fallbackReader
			for i = 1, szObjs do
				local val = reader(objs[i], name)
				local zigzag = (val < 0) and (2 * -val - 1) or (2 * val)
				local high = m_floor(zigzag / 4294967296)
				local low = zigzag % 4294967296
				b_writeu32(temp, 0, low)
				b_writeu32(temp, 4, high)
				local base = i - 1
				for b = 0, 7 do
					b_writeu8(buf, base + szObjs * b, b_readu8(temp, 7 - b))
				end
			end
			return b_tostring(buf)
		end,
		["OptionalCoordinateFrame"] = (function()
			local TempCFrameBuf = buffer.create(36)
			return function(Objs, Name, Func)
				local SzObjs = #Objs
				local Buf = b_create(2 + 51 * SzObjs)
				local Offset = 0
	
				b_writeu8(Buf, Offset, 16); Offset += 1 -- CFrame ID prefix
	
				local Positions = tableCreate(SzObjs)
				local ExistsList = tableCreate(SzObjs)
				local Reader = Func or (oldIndex and _oldIndexReader) or _fallbackReader
	
				for I = 1, SzObjs do
					local Val = Reader(Objs[I], Name)
					local Exists = true
					if not Val then
						Exists = false
						Val = CFrame.new()
					end
	
					ExistsList[I] = Exists
					Positions[I] = Val.Position
	
					local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = components(Val)
					buffer.writef32(TempCFrameBuf, 0, R00)
					buffer.writef32(TempCFrameBuf, 4, R01)
					buffer.writef32(TempCFrameBuf, 8, R02)
					buffer.writef32(TempCFrameBuf, 12, R10)
					buffer.writef32(TempCFrameBuf, 16, R11)
					buffer.writef32(TempCFrameBuf, 20, R12)
					buffer.writef32(TempCFrameBuf, 24, R20)
					buffer.writef32(TempCFrameBuf, 28, R21)
					buffer.writef32(TempCFrameBuf, 32, R22)
	
					local StrKey = b_tostring(TempCFrameBuf)
					local MappedID = binaryCFrameMap[StrKey]
	
					if MappedID then
						b_writestring(Buf, Offset, MappedID, 1)
						Offset += 1
					else
						b_writeu8(Buf, Offset, 0)
						b_writestring(Buf, Offset + 1, StrKey, 36)
						Offset += 37
					end
				end
	
				local PosStart = Offset
				Offset += 12 * SzObjs
	
				local Temp2 = b_create(4)
				for I = 1, SzObjs do
					local Pos = Positions[I]
					b_writef32(Temp2, 0, Pos.X); local XRot = b32_lrotate(b_readu32(Temp2, 0), 1)
					b_writef32(Temp2, 0, Pos.Y); local YRot = b32_lrotate(b_readu32(Temp2, 0), 1)
					b_writef32(Temp2, 0, Pos.Z); local ZRot = b32_lrotate(b_readu32(Temp2, 0), 1)
	
					local Base = I - 1
					b_writeu8(Buf, PosStart + Base, b32_extract(XRot, 24, 8))
					b_writeu8(Buf, PosStart + Base + SzObjs, b32_extract(XRot, 16, 8))
					b_writeu8(Buf, PosStart + Base + SzObjs * 2, b32_extract(XRot, 8, 8))
					b_writeu8(Buf, PosStart + Base + SzObjs * 3, b32_extract(XRot, 0, 8))
	
					local YBase = PosStart + 4 * SzObjs + Base
					b_writeu8(Buf, YBase, b32_extract(YRot, 24, 8))
					b_writeu8(Buf, YBase + SzObjs, b32_extract(YRot, 16, 8))
					b_writeu8(Buf, YBase + SzObjs * 2, b32_extract(YRot, 8, 8))
					b_writeu8(Buf, YBase + SzObjs * 3, b32_extract(YRot, 0, 8))
	
					local ZBase = PosStart + 8 * SzObjs + Base
					b_writeu8(Buf, ZBase, b32_extract(ZRot, 24, 8))
					b_writeu8(Buf, ZBase + SzObjs, b32_extract(ZRot, 16, 8))
					b_writeu8(Buf, ZBase + SzObjs * 2, b32_extract(ZRot, 8, 8))
					b_writeu8(Buf, ZBase + SzObjs * 3, b32_extract(ZRot, 0, 8))
				end
	
				b_writeu8(Buf, Offset, 2); Offset += 1 -- Boolean ID prefix
				for I = 1, SzObjs do
					b_writeu8(Buf, Offset, ExistsList[I] and 1 or 0)
					Offset += 1
				end
	
				return b_tostring(Buf, 0, Offset)
			end
		end)(),
		["Font"] = function(Objs, Name, Func)
			local SzObjs = #Objs
	
			local DefaultWeight = { Value = 400 }
			local DefaultStyle = { Value = 0 }
			pcall(function() DefaultWeight = Enum.FontWeight.Regular end)
			pcall(function() DefaultStyle = Enum.FontStyle.Normal end)

			local Families = tableCreate(SzObjs)
			local Weights = tableCreate(SzObjs)
			local Styles = tableCreate(SzObjs)
			local TotalSize = 0
	
			local Reader = Func or (oldIndex and _oldIndexReader) or _fallbackReader
	
			for I = 1, SzObjs do
				local Val = Reader(Objs[I], Name)
				if typeof(Val) == "EnumItem" then
					local Success, FontObj = pcall(Font.fromEnum, Val)
					if Success then
						Val = FontObj
					else
						Val = {
							Family = "rbxasset://fonts/families/" .. Val.Name .. ".json",
							Weight = DefaultWeight,
							Style = DefaultStyle
						}
					end
				elseif not Val then
					Val = {
						Family = "",
						Weight = DefaultWeight,
						Style = DefaultStyle
					}
				end
	
				local Fam = Val.Family
				Families[I] = Fam
				Weights[I] = Val.Weight.Value
				Styles[I] = Val.Style.Value
				TotalSize += 11 + #Fam
			end
	
			local Buf = b_create(TotalSize)
			local Offset = 0
			for I = 1, SzObjs do
				local Fam = Families[I]
				local FamLen = #Fam
				b_writeu32(Buf, Offset, FamLen)
				b_writestring(Buf, Offset + 4, Fam, FamLen)
				b_writeu16(Buf, Offset + 4 + FamLen, Weights[I])
				b_writeu8(Buf, Offset + 6 + FamLen, Styles[I])
				b_writeu32(Buf, Offset + 7 + FamLen, 0)
				Offset += 11 + FamLen
			end
	
			return b_tostring(Buf)
		end,
		["SecurityCapabilities"] = function(Objs, Name, Func)
			local SzObjs = #Objs
			local Writer = BufferWriter.New(8 * SzObjs)
			Writer:Skip(8 * SzObjs)
	
			local GetValue
			if Func then
				GetValue = function(Obj, PropName)
					local Success, Res = pcall(Func, Obj, PropName)
					return Success and Res
				end
			elseif oldIndex then
				GetValue = function(Obj, PropName)
					local Success, Res = pcall(oldIndex, Obj, PropName)
					return Success and Res
				end
			else
				GetValue = function(Obj, PropName)
					local Success, Res = pcall(function() return Obj[PropName] end)
					return Success and Res
				end
			end

			for I = 1, SzObjs do
				local Val = GetValue(Objs[I], Name)
				local BitsCount = 0
				if Val then
					local ValStr = tostring(Val)
					for _, Flag in next, string.split(ValStr, " | ") do
						local Bit = CAPABILITY_BITS[Flag]
						if Bit then
							BitsCount = BitsCount + Bit
						end
					end
				end
				Writer:WriteInterleavedUInt64(0, I - 1, SzObjs, BitsCount)
			end
			return Writer:ToString()
		end,
	}

	local specialProps = {
		["Script"] = {
			{Name = "Source", ValueType = {Name = "ProtectedString", Category = "DataType"}, Special = "Decompile"}
		},
		["ModuleScript"] = {
			{Name = "Source", ValueType = {Name = "ProtectedString", Category = "DataType"}, Special = "Decompile"}
		},
		["TerrainRegion"] = { -- TODO: Vector3int16 support for gethiddenprop
			{Name = "ExtentsMin", ValueType = {Name = "Vector3int16", Category = "DataType"}, Special = "Func", Func = function(obj) return workspace.Terrain.MaxExtents.Min end},
			{Name = "ExtentsMax", ValueType = {Name = "Vector3int16", Category = "DataType"}, Special = "Func", Func = function(obj) return workspace.Terrain.MaxExtents.Max end},
		},
		["Model"] = { -- TODO: OptionalCoordinateFrame support for gethiddenprop
			{Name = "WorldPivotData", ValueType = {Name = "OptionalCoordinateFrame", Category = "DataType"}, IndexName = "WorldPivot"},
		},
	}

	--[[
	local specialProps = {
		["Instance"] = {
			{Name = "AttributesSerialize", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "Tags", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
		},
		["TriangleMeshPart"] = {
			{Name = "LODData", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "PhysicalConfigData", ValueType = {Name = "SharedString"}, Special = "SharedString"},
		},
		["PartOperation"] = {
			{Name = "AssetId", ValueType = {Name = "Content"}, Special = "NotScriptable"},
			{Name = "InitialSize", ValueType = {Name = "Vector3"}, Special = "NotScriptable"},
			{Name = "ChildData", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "MeshData", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "PhysicsData", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "ChildData2", ValueType = {Name = "SharedString"}, Special = "SharedString"},
			{Name = "MeshData2", ValueType = {Name = "SharedString"}, Special = "SharedString"},
			{Name = "FormFactor", ValueType = {Name = "FormFactor", Category = "Enum"}, Special = "NotScriptable"},
		},
		["MeshPart"] = {
			{Name = "InitialSize", ValueType = {Name = "Vector3"}, Special = "NotScriptable"},
			{Name = "PhysicsData", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
		},
		["Terrain"] = {
			{Name = "Decoration", ValueType = {Name = "bool"}, Special = "NotScriptable"},
			{Name = "MaterialColors", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "SmoothGrid", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "PhysicsGrid", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
		},
		["TerrainRegion"] = { -- TODO: Vector3int16 support for gethiddenprop
			{Name = "SmoothGrid", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
			{Name = "ExtentsMin", ValueType = {Name = "Vector3int16"}, Special = "Func", Func = function(obj) return workspace.Terrain.MaxExtents.Min end},
			{Name = "ExtentsMax", ValueType = {Name = "Vector3int16"}, Special = "Func", Func = function(obj) return workspace.Terrain.MaxExtents.Max end},
		},
		["BinaryStringValue"] = {
			{Name = "Value", ValueType = {Name = "BinaryString"}, Special = "BinaryString"},
		},
		["Workspace"] = {
			{Name = "PGSPhysicsSolverEnabled", ValueType = {Name = "bool"}, Special = "Func", Func = function(obj) return obj:PGSIsEnabled() end},
			{Name = "CollisionGroups", ValueType = {Name = "string"}, Special = "Func", Func = function(obj)
				local groupTable = {}
				for i,v in game:GetService("PhysicsService"):GetCollisionGroups() do
					groupTable[i] = v.name.."^"..v.id.."^"..v.mask
				end
				return tblconcat(groupTable,"\\")
			end}
		},
		["Humanoid"] = {
			{Name = "Health_XML", ValueType = {Name = "float"}, IndexName = "Health"},
		},
		["Sound"] = {
			{Name = "xmlRead_MaxDistance_3", ValueType = {Name = "float"}, IndexName = "MaxDistance"},
		},
		["WeldConstraint"] = {
			{Name = "CFrame0", ValueType = {Name = "CFrame"}, Special = "NotScriptable"},
			{Name = "CFrame1", ValueType = {Name = "CFrame"}, Special = "NotScriptable"},
			{Name = "Part0Internal", ValueType = {Name = "Instance", Category = "Class"}, IndexName = "Part0"},
			{Name = "Part1Internal", ValueType = {Name = "Instance", Category = "Class"}, IndexName = "Part1"}
		},
		["Lighting"] = {
			{Name = "Technology", ValueType = {Category = "Enum"}, Special = "NotScriptable"}
		},
		["LocalizationTable"] = {
			{Name = "Contents", ValueType = {Name = "string"}, Special = "NotScriptable"}
		},
		["Script"] = {
			{Name = "Source", ValueType = {Name = "ProtectedString"}, Special = "Decompile"}
		},
		["ModuleScript"] = {
			{Name = "Source", ValueType = {Name = "ProtectedString"}, Special = "Decompile"}
		},
		["PackageLink"] = {
			{Name = "PackageIdSerialize", ValueType = {Name = "Content"}, IndexName = "PackageId"},
			{Name = "VersionIdSerialize", ValueType = {Name = "int64"}, IndexName = "VersionNumber"}
		}
	}
	]]

	local readMeStart = [==[--[[

    ____             ____  ______   _____           _       ___
   / __ \___  _  __ / __ \/ ____/  / ___/___  _____(_)___ _/ (_)___  ___  _____
  / / / / _ \| |/_// /_/ / __/     \__ \/ _ \/ ___/ / __ `/ / /_  / / _ \/ ___/
 / /_/ /  __/>  < / _, _/ /___    ___/ /  __/ /  / / /_/ / / / / /_/  __/ /
/_____/\___/_/|_|/_/ |_/_____/   /____/\___/_/  /_/\__,_/_/_/ /___/\___/_/

	
	Thank you for using DexRE's Serializer!

	-- Saved with https://github.com/Tesker-103/DexRecontinued/
	-- Originally made by Moon, Fixed and Improved for DexREContinued
	
	IMPORTANT NOTES:
	- Save your game immediately (Use File > Save As) to take advantage of the chosen format.
	- If your player cannot spawn, move scripts in StarterPlayer to another location (done by default).
	- If chat doesn't work, delete everything in Chat service via:
	  game:GetService("Chat"):ClearAllChildren()
	
	FOR PHYSICS/COLLISION ISSUES (UnionOperation & MeshPart):
	Run this in Studio command bar:
	local list = {}
	for i,v in pairs(game:GetDescendants()) do
		local s,e = pcall(function()
			return v:IsA("UnionOperation") or v:IsA("MeshPart")
		end)
		if s and e then list[#list+1] = v end
	end
	game.Selection:Set(list)
	
	Then go to Properties and change CollisionFidelity from "Box" to "Default". (if you want proper collision, set it to PreciseConvexDecomposition, studio may freeze depending on the number of meshes you have, don't click on it, or windows will think its not responding.)
	
	SETTINGS USED FOR THIS SAVE:
	
]==]

	local function getSaveProps(obj,class)
		local result = {}
		local count = 1

		local curClass = API.Classes[class]
		while curClass do
			local curClassName = curClass.Name
			local cacheProps = saveProps[curClassName]
			if cacheProps then
				tblmove(cacheProps,1,#cacheProps,#result+1,result)
				break
			end

			local props = curClass.Properties
			for i = 1,#props do
				local prop = props[i]
				local propName = prop.Name
				--if (prop.Serialization.CanSave and not prop.Tags.NotScriptable) or (propBypass[curClassName] and propBypass[curClassName][propName]) then
				if prop.Serialization.CanSave or (propBypass[curClassName] and propBypass[curClassName][propName]) then
					if not propFilter[curClassName] or not propFilter[curClassName][propName] then
						-- Check for existence in current engine version
						if prop.Tags and prop.Tags.NotScriptable then
							local s,ret1,ret2 = pcall(getnspval,obj,propName)
							if s and type(ret2) ~= "string" then
								result[count] = prop
								count = count + 1
							end
						else
							local s,e = pcall(function() return obj[propName] end)
							if s then
								result[count] = prop
								count = count + 1
							end
						end
					end
				end
			end

			-- Special props may also contain alternate defs for filtered props
			local specialProps = specialProps[curClassName]
			if specialProps then
				tblmove(specialProps,1,#specialProps,#result+1,result)
				count = #result+1
			end

			curClass = curClass.Superclass
		end

		tblsort(result,function(a,b) return a.Name < b.Name end)
		return result
	end

	local function getTestInst(class)
		local s,inst = pcall(Instance.new,class)
		if not s then return {} end

		local defaultProps = {}

		local props = saveProps[class]
		for i = 1,#props do
			local prop = props[i]
			if not prop.Special and not (prop.Tags and prop.Tags.NotScriptable) then
				local propName = prop.IndexName or prop.Name
				defaultProps[propName] = inst[propName]
			end
		end

		return defaultProps
	end

	local function doDecompile(scr,saveSettings)
		local thread = coroutine.running()
		local finished = false

		if elysianexecute then
			local s,e = decompile(scr,function(src,err)
				if not finished then
					finished = true
					coroutine.resume(thread,src,err)
				end
			end,saveSettings.DecompileTimeout)

			if not s then return nil, e end
		else
			return decompile(scr,nil,saveSettings.DecompileTimeout)
		end

		-- extra measures because windows sucks
		task.spawn(function()
			task.wait(saveSettings.DecompileTimeout + 1)
			if not finished then
				finished = true
				coroutine.resume(thread, nil, "decompile failed: decompiler timed out")
			end
		end)

		return coroutine.yield()
	end

	local function createStatusText()
		local StatusGui = Instance.new("ScreenGui")
		StatusGui.Parent = (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
		StatusGui.DisplayOrder = 2000000000
	
		pcall(function()
			StatusGui.OnTopOfCoreBlur = true
		end)

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Name = "StatusLabel"
		TextLabel.Text = "Saving Object(s), Please wait..."
		TextLabel.BackgroundTransparency = 1
		TextLabel.Font = Enum.Font.Code
		TextLabel.Size = UDim2.new(1, 0, 0, 40)
		TextLabel.Position = UDim2.new(0, 0, 0, 50)
		TextLabel.TextColor3 = Color3.new(1, 1, 1)
		TextLabel.TextSize = 24
		TextLabel.TextStrokeTransparency = 0.5
		TextLabel.TextXAlignment = Enum.TextXAlignment.Center
		TextLabel.TextYAlignment = Enum.TextYAlignment.Center
		TextLabel.Parent = StatusGui

		local StartTime = os.clock()

		local LastUpdate = 0

		local function updateStatus(text)
			if not text then
				TextLabel.Text = ""
			else
				local Now = os.clock()
				if Now - LastUpdate >= 0.01 or text:find("Saved") then
					LastUpdate = Now
					local Elapsed = Now - StartTime
					local TimeStr = string.format("%.1fs", Elapsed)
					TextLabel.Text = text .. " [" .. TimeStr .. "]"
				end
			end
		end

		local function removeStatus()
			pcall(StatusGui.Destroy, StatusGui)
		end

		task.wait(0.011311) -- to let the ui render

		return {Update = updateStatus, Remove = removeStatus}
	end

	local function predecompile(root,statusText,saveSettings)
		if not saveSettings.Decompile then return {} end

		local scripts,sources,checked = {},{},{}
		local ignoredServices
		local scriptCount,totalScripts = 1,0

		if root == game and saveSettings.DecompileIgnore then
			ignoredServices = {}
			for i,v in saveSettings.DecompileIgnore do
				ignoredServices[i] = game:GetService(v)
			end
		end

		local isTable = type(root) == "table"
		local Objs = isTable and root or {root}
		local maxThreads = saveSettings.MaxThreads or 3
		local isDescendantOf = game.IsDescendantOf

		if saveSettings.NilInstances and root == game and getnilinstances then
			local nilInsts = getnilinstances()
			tblmove(nilInsts,1,#nilInsts,#Objs+1,Objs)
		end

		for I = 1, #Objs do
			local NextRoot = Objs[I]
			local Descs = NextRoot:GetDescendants()
	
			local function ProcessElement(Obj)
				if (isa(Obj, "LocalScript") or isa(Obj, "ModuleScript") or isa(Obj, "Script")) and not checked[Obj] then
					local Ignored = false
					if ignoredServices then
						for j = 1, #ignoredServices do
							if isDescendantOf(Obj, ignoredServices[j]) then
								Ignored = true
								break
							end
						end
					end

					if not Ignored then
						scripts[scriptCount] = Obj
						scriptCount = scriptCount + 1
					end

					checked[Obj] = true
				end
			end
			ProcessElement(NextRoot)
			for J = 1, #Descs do
				ProcessElement(Descs[J])
			end
		end
		totalScripts = scriptCount - 1

		local BytecodeHashCache = {}
		local GetScriptBytecode = getscriptbytecode or get_script_bytecode

		if saveSettings.SaveScriptCache and env.isfile and env.readfile and env.isfile("ScriptCache.json") then
			local ok, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, env.readfile("ScriptCache.json"))
			if ok and type(decoded) == "table" then
				BytecodeHashCache = decoded
			end
		end

		local left = totalScripts
		for I = 1, maxThreads do
			task.spawn(function()
				while true do
					local NextScript = table.remove(scripts)
					if not NextScript then break end
	
					local ScriptName
					pcall(function() ScriptName = NextScript:GetFullName() end)
					if statusText then
						statusText.Update("Decompiling " .. (ScriptName or "<unknown>") .. " (" .. (totalScripts - left + 1) .. "/" .. totalScripts .. ")")
					end
	
					local BytecodeHash
					if GetScriptBytecode and hashmd5 then
						local Ok, Bytecode = pcall(GetScriptBytecode, NextScript)
						if Ok and Bytecode then
							BytecodeHash = hashmd5(Bytecode)
						end
					end

					local Source
					if BytecodeHash and BytecodeHashCache[BytecodeHash] then
						Source = BytecodeHashCache[BytecodeHash]
					else
						local Ok, Res = pcall(function() return doDecompile(NextScript, saveSettings) end)
						if Ok and Res then
							Source = Res
							if BytecodeHash then
								BytecodeHashCache[BytecodeHash] = Source
							end
						else
							Source = nil
						end
					end

					local mrk = "-- Saved with DexRESerializer (https://github.com/Tesker-103/DexRecontinued/)\n\n"
					if saveSettings.SaveBytecode and GetScriptBytecode then
						local ok, bytecode = pcall(GetScriptBytecode, NextScript)
						if ok and bytecode then
							local b64 = env.encodeBase64(bytecode)
							if b64 then
								Source = "-- Bytecode (Base64):\n-- " .. b64 .. "\n\n" .. (Source or "")
							end
						end
					end

					if Source then
						sources[NextScript] = mrk .. Source
					else
						sources[NextScript] = mrk .. "-- This script could not be decompiled"
					end

					left = left - 1
					if statusText then
						statusText.Update("Decompiling scripts... (" .. (totalScripts - left) .. "/" .. totalScripts .. ")")
					end
				end
			end)
		end

		local decompTimeout = saveSettings.DecompileTimeout or DefaultSettings.Serializer.DecompileTimeout or 10
		local maxWait = os.clock() + math.max(60, (decompTimeout * math.max(1, totalScripts)) / math.max(1, maxThreads) * 4)
		while left > 0 do
			if os.clock() > maxWait then
				if statusText then statusText.Update("Decompilation timed out; aborting remaining scripts") end
				break
			end
			task.wait()
		end

		if saveSettings.SaveScriptCache and env.writefile then
			pcall(env.writefile, "ScriptCache.json", service.HttpService:JSONEncode(BytecodeHashCache))
		end

		return sources
	end

	local function serializeBinary(root,filename,saveSettings)
		local mainBuf = {}

		local header = {"\60\114\111\98\108\111\120\33\137\255\13\10\26\10\0\0","","","\0\0\0\0\0\0\0\0"}
		local metaBuf = {"\77\69\84\65\36\0\0\0\34\0\0\0\0\0\0\0\240\19\1\0\0\0\18\0\0\0\69\120\112\108\105\99\105\116\65\117\116\111\74\111\105\110\116\115\4\0\0\0\116\114\117\101"}
		local sstrBuf = {}
		local instBuf,instBufCount = {},1
		local propBuf,propBufCount = {},1
		local prntBuf = {}
		local endBuf = {"\69\78\68\0\0\0\0\0\9\0\0\0\0\0\0\0\60\47\114\111\98\108\111\120\62"}

		local instTypeCount = 0
		local instCount = 0
		local refCount = 0
		local sharedStringCount = 0

		local isGame = root == game
		local isTable = type(root) == "table"

		local classList = {}
		local hashs = {}
		local sharedStrings = {}
		local filter = {}
		local refs = {}
		local parents = {}
		local orderedInstList = {}
		local nilBlacklist = {[game] = true}
		local folderClasses = {["Player"] = true, ["PlayerScripts"] = true, ["PlayerGui"] = true, ["ScriptDebugger"] = true, ["Breakpoints"] = true, ["DebuggerWatch"] = true}
		local savingDefaultProps = not saveSettings.IgnoreDefaultProps
		local decompileEnabled = saveSettings.Decompile

		if isTable and not root[1] then error("Empty Table") end

		if isGame then
			for i,v in service.Players:GetPlayers() do
				if not saveSettings.SavePlayers then
					filter[v] = true
				end

				if saveSettings.RemovePlayerCharacters and v.Character then
					filter[v.Character] = true
				end
			end
		end

		if saveSettings.IsolateStarterPlayer then
			folderClasses["StarterPlayer"] = true
			folderClasses["StarterCharacterScripts"] = true
			folderClasses["StarterPlayerScripts"] = true
		end

		if not filename or filename == "" then
			local clean = function(s) return (string.gsub(string.gsub(s or "Game", "[^%w%s-_]", ""), "%s+", "_")) end
			if isGame then
				local ok, info = pcall(service.MarketplaceService.GetProductInfoAsync, service.MarketplaceService, game.PlaceId)
				filename = "Place_" .. game.PlaceId .. "_" .. (ok and info and clean(info.Name) or "Game") .. ".rbxl"
			else
				local inst = isTable and root[1] or root
				filename = "Model_" .. game.PlaceId .. "_" .. clean(inst.Name) .. "_" .. string.sub(inst:GetDebugId(), 1, 8) .. ".rbxm"
			end
		else
			filename = filename:match(isGame and "%.rbxlx?$" or "%.rbxmx?$") and filename or filename .. (isGame and ".rbxl" or ".rbxm")
		end

		if saveSettings.AvoidFileOverwrite and env.isfile and env.isfile(filename) then
			local base, ext = filename:match("^(.-)(%.[^%.]+)$")
			base = base or filename
			ext = ext or ""
			local counter = 1
			while env.isfile(filename) do
				filename = base .. " (" .. counter .. ")" .. ext
				counter += 1
			end
		end

		local startB = os.clock()

		if not saveSettings.Clipboard and not saveSettings.Callback then
			env.writefile(filename,"")
		end

		local statusText = saveSettings.ShowStatus and createStatusText()
		local sources = predecompile(root,statusText,saveSettings)

		-- Count instances and instance types
		local function recur(obj)
			if filter[obj] then return end

			local class = oldIndex and oldIndex(obj,"ClassName") or obj.ClassName
			if folderClasses[class] then
				class = "Folder"
				if not saveProps["Folder"] then saveProps["Folder"] = getSaveProps(Instance.new("Folder"),"Folder") end
			end

			if not saveProps[class] then saveProps[class] = getSaveProps(obj,class) end

			if not testInsts[class] then testInsts[class] = (not savingDefaultProps and getTestInst(class) or {}) end

			local ch = getChildren(obj)
			local szCh = #ch
			if szCh > 0 then
				for i = 1,szCh do
					local chObj = ch[i]
					parents[chObj] = obj
					recur(chObj)
				end
			end

			if not refs[obj] then
				instCount = instCount + 1
				orderedInstList[instCount] = obj

				local cList = classList[class]
				if not cList then
					cList = {}
					classList[class] = cList
					instTypeCount = instTypeCount + 1
				end
				cList[#cList+1] = obj

				refs[obj] = refCount
				refCount = refCount + 1
			end
		end

		if isGame then
			local gameCh = getChildren(root)
			for i = 1,#gameCh do
				local obj = gameCh[i]
				if not serviceBlacklist[obj.ClassName] then
					recur(obj)
				end
			end

			if saveSettings.IsolateLocalPlayer then
				local lp = service.Players.LocalPlayer
				if lp then
					local LpFolder = Instance.new("Folder")
					LpFolder.Name = "LocalPlayer"
					nilBlacklist[LpFolder] = true
					recur(LpFolder)
					for _, child in lp:GetChildren() do
						if child.ClassName == "PlayerGui" or child.ClassName == "PlayerScripts" or child.ClassName == "StarterGear" then
							parents[child] = LpFolder
							recur(child)
						end
					end
				end
			end

			local message = readMeStart

			for i, v in next, saveSettings do
				if type(v) == "table" then -- assume array
					local strings = {}
					for j, k in next, v do
						strings[#strings+1] = type(k) == "string" and ("\"" .. tostring(k) .. "\"") or tostring(v)
					end
					message = message .. "\t" .. tostring(i) .. " = { " .. tblconcat(strings, ", ") .. " }\n"
				elseif i ~= "_Recurse" then
					message = message .. "\t" .. tostring(i) .. " = " .. tostring(v) .. "\n"
				end
			end

			message = message .. "]]"

			local readmeScript = Instance.new("Script")
			readmeScript.Name = "README"
			nilBlacklist[readmeScript] = true
			sources[readmeScript] = message
			recur(readmeScript)
		elseif isTable then
			for i = 1,#root do
				recur(root[i])
			end
		else
			recur(root)
		end

		-- Nil Instances
		if saveSettings.NilInstances and root == game and getnilinstances then
			local nilFolder = Instance.new("Folder")
			nilFolder.Name = "Nil Instances"
			nilBlacklist[nilFolder] = true
			recur(nilFolder)

			local classes = API.Classes
			local nilInsts = getnilinstances()
			for i = 1,#nilInsts do
				local obj = nilInsts[i]
				local class = oldIndex and oldIndex(obj,"ClassName") or obj.ClassName
				if classes[class] and not classes[class].Tags.Service and not classes[class].Tags.NotCreatable and not nilBlacklist[obj] then
					local parentClass = nilClassParents[class]
					if parentClass then
						local parentObj = Instance.new(parentClass)
						parentObj.Name = class.." Class"
						recur(parentObj)
						parents[parentObj] = nilFolder

						recur(obj)
						parents[obj] = parentObj
					else
						local isNilSafe = nilSafe[class]
						if isNilSafe == nil then
							isNilSafe = true
							local folder = Instance.new("Folder")
							local s,inst = pcall(Instance.new,class)
							if s and not pcall(function() inst.Parent = folder end) then
								isNilSafe = false
							end
							nilSafe[class] = isNilSafe
						end
						if isNilSafe then
							recur(obj)
							parents[obj] = nilFolder
						end
					end
				end
			end
		end

		-- Special Handlers
		local refPropHandler = function(Objs, Name, Func)
		local SzObjs = #Objs
		local Writer = BufferWriter.New(4 * SzObjs)
		Writer:Skip(4 * SzObjs)
	
		local LastRef
		for I = 1, SzObjs do
			local Val = Func and Func(Objs[I], Name) or (oldIndex and oldIndex(Objs[I], Name) or Objs[I][Name])
			local Ref = refs[Val] or -1
			local AccRef = LastRef and (Ref - LastRef) or Ref
			LastRef = Ref
	
			local Transformed = AccRef < 0 and (2 * -AccRef - 1) or (2 * AccRef)
			Writer:WriteInterleavedUInt32(0, I - 1, SzObjs, Transformed)
		end
		return Writer:ToString()
	end

	local sharedStringHandler = function(Objs, Name, Func)
		if not gethiddenprop then return end

		if sharedStringCount == 0 then
			sharedStringCount += 1
			local MD5Buf = b_create(16)
			b_writeu8(MD5Buf, 15, 1) -- Set final LSB to 1
			sharedStrings[1] = {b_tostring(MD5Buf), ""}
		end

		local SzObjs = #Objs
		local Buf = b_create(4 * SzObjs)
	
		for I = 1, SzObjs do
			local Content = gethiddenprop(Objs[I], Name)
			if Content and #Content > 0 then
				local Index = hashs[Content]
				if not Index then
					Index = sharedStringCount
					hashs[Content] = Index
					sharedStringCount += 1
	
					local MD5Buf = b_create(16)
					b_writeu8(MD5Buf, 12, b32_extract(Index, 24, 8))
					b_writeu8(MD5Buf, 13, b32_extract(Index, 16, 8))
					b_writeu8(MD5Buf, 14, b32_extract(Index, 8, 8))
					b_writeu8(MD5Buf, 15, b32_extract(Index, 0, 8))
	
					sharedStrings[sharedStringCount] = {b_tostring(MD5Buf), Content}
				end
	
				local Base = I - 1
				b_writeu8(Buf, Base, b32_extract(Index, 24, 8))
				b_writeu8(Buf, Base + SzObjs, b32_extract(Index, 16, 8))
				b_writeu8(Buf, Base + SzObjs * 2, b32_extract(Index, 8, 8))
				b_writeu8(Buf, Base + SzObjs * 3, b32_extract(Index, 0, 8))
			end
		end
		return b_tostring(Buf)
	end

	local protectedStringHandler = function(Objs, Name, Func)
		local SzObjs = #Objs
		local TotalBytes = 0
		local Values = tableCreate(SzObjs)
	
		for I = 1, SzObjs do
			local Val
			local Obj = Objs[I]
			if sources[Obj] then
				Val = sources[Obj]
			elseif not decompileEnabled then
				Val = "-- Decompiling is disabled"
			else
				Val = "-- Script failed to decompile or ignored"
			end
			Values[I] = Val
			TotalBytes = TotalBytes + 4 + #Val
		end
	
		local Writer = BufferWriter.New(TotalBytes)
		for I = 1, SzObjs do
			Writer:WriteSizedStringLE(Values[I])
		end
		return Writer:ToString()
	end

		local function CreateChunk(Mbyte, Data)
			local DecompressedSize = #Data
			local CompressedSize = 0
			local ChunkData = Data
	
			if lz4compress then
				local Compressed = lz4compress(Data)
				if Compressed then
					CompressedSize = #Compressed
					ChunkData = Compressed
				end
			end
	
			local HeaderBuf = b_create(16)
			b_writestring(HeaderBuf, 0, Mbyte, 4)
			b_writeu32(HeaderBuf, 4, CompressedSize)
			b_writeu32(HeaderBuf, 8, DecompressedSize)
			b_writeu32(HeaderBuf, 12, 0)
	
			return b_tostring(HeaderBuf) .. ChunkData
		end

		-- Make INST chunks
		local TypeId = 0
		for Class, Objs in classList do
			local IsService = API.Classes[Class] and API.Classes[Class].Tags.Service
			local NumObjs = #Objs
	
			local InstChunkSize = 4 + #Class + 4 + 1 + 4 + (4 * NumObjs) + (IsService and NumObjs or 0)
			local ChunkBuf = b_create(InstChunkSize)
			local Offset = 0
	
			b_writeu32(ChunkBuf, Offset, TypeId); Offset += 4
			b_writeu32(ChunkBuf, Offset, #Class); Offset += 4
			b_writestring(ChunkBuf, Offset, Class, #Class); Offset += #Class
			b_writeu8(ChunkBuf, Offset, IsService and 1 or 0); Offset += 1
			b_writeu32(ChunkBuf, Offset, NumObjs); Offset += 4
	
			local RefStart = Offset
			Offset += 4 * NumObjs
	
			local LastRef
			for I = 1, NumObjs do
				local Obj = Objs[I]
				local Ref = refs[Obj]
				local AccRef = LastRef and (Ref - LastRef) or Ref
				LastRef = Ref
	
				local Transformed = AccRef < 0 and (2 * -AccRef - 1) or (2 * AccRef)
				local Base = RefStart + (I - 1)
	
				b_writeu8(ChunkBuf, Base, b32_extract(Transformed, 24, 8))
				b_writeu8(ChunkBuf, Base + NumObjs, b32_extract(Transformed, 16, 8))
				b_writeu8(ChunkBuf, Base + NumObjs * 2, b32_extract(Transformed, 8, 8))
				b_writeu8(ChunkBuf, Base + NumObjs * 3, b32_extract(Transformed, 0, 8))
			end
	
			if IsService then
				for I = 1, NumObjs do
					b_writeu8(ChunkBuf, Offset, 1)
					Offset += 1
				end
			end
	
			instBuf[instBufCount] = CreateChunk("INST", b_tostring(ChunkBuf))
			instBufCount += 1

			-- Make PROP chunks
			local Props = saveProps[Class]
			local DefaultTable = testInsts[Class]

			for PropInd = 1, #Props do
				local Prop = Props[PropInd]
				local PropName = Prop.Name
				local IndexName = Prop.IndexName or PropName
				local TypeData = Prop.ValueType
				local PropTypeCategory = TypeData.Category
				local PropType = TypeData.Name

				local Handler
				local PropTypeByte
				if PropTypeCategory == "Primitive" or PropTypeCategory == "DataType" then
					Handler = binaryPropHandlers[PropType]
					PropTypeByte = binaryDataTypes[PropType]

					if not Handler then
						if PropType == "SharedString" then
							Handler = sharedStringHandler
						elseif PropType == "ProtectedString" then
							Handler = protectedStringHandler
							PropTypeByte = binaryDataTypes.string
						end
					end
				elseif PropTypeCategory == "Enum" then
					Handler = binaryPropHandlers.Enum
					PropTypeByte = binaryDataTypes.Enum
				else -- Assume Class referent
					Handler = refPropHandler
					PropTypeByte = binaryDataTypes.Referent
				end

				if Handler and PropTypeByte then
					local Func
					local Special = Prop.Special

					if Prop.Tags and Prop.Tags.NotScriptable then
						if getnspval then
							Func = getnspval
						else
							continue
						end
					end

					if Special then
						if Special == "NotScriptable" then
							if getnspval then
								Func = getnspval
							else
								continue
							end
						elseif Special == "Func" then
							Func = Prop.Func
						end
					end

					if not savingDefaultProps and DefaultTable then
						local DefaultVal = DefaultTable[IndexName]
						if DefaultVal ~= nil then
							local AllDefault = true
							local Reader = Func or (oldIndex and _oldIndexReader) or _fallbackReader
							for I = 1, NumObjs do
								if Reader(Objs[I], IndexName) ~= DefaultVal then
									AllDefault = false
									break
								end
							end
							if AllDefault then
								continue
							end
						end
					end

					local PropData = Handler(Objs, IndexName, Func)
					if not PropData then continue end

					local PropChunkSize = 4 + #PropName + 4 + 1 + #PropData
					local PChunkBuf = b_create(PropChunkSize)
					local POffset = 0
	
					b_writeu32(PChunkBuf, POffset, TypeId); POffset += 4
					b_writeu32(PChunkBuf, POffset, #PropName); POffset += 4
					b_writestring(PChunkBuf, POffset, PropName, #PropName); POffset += #PropName
					b_writeu8(PChunkBuf, POffset, string.byte(PropTypeByte)); POffset += 1
					b_writestring(PChunkBuf, POffset, PropData, #PropData)

					propBuf[propBufCount] = CreateChunk("PROP", b_tostring(PChunkBuf))
					propBufCount += 1
				end
			end

			TypeId += 1
		end


		-- Make SSTR chunk
		if sharedStringCount > 0 then
			local SstrBufObj = b_create(8)
			b_writeu32(SstrBufObj, 0, 0) -- Version/Reserved
			b_writeu32(SstrBufObj, 4, sharedStringCount)
	
			local SstrParts = {b_tostring(SstrBufObj)}
			for I = 1, #sharedStrings do
				local Data = sharedStrings[I]
				local Hash, Content = Data[1], Data[2]
	
				local ItemBuf = b_create(16 + 4 + #Content)
				b_writestring(ItemBuf, 0, Hash, 16)
				b_writeu32(ItemBuf, 16, #Content)
				b_writestring(ItemBuf, 20, Content, #Content)
	
				SstrParts[#SstrParts + 1] = b_tostring(ItemBuf)
			end
	
			sstrBuf[1] = CreateChunk("SSTR", tblconcat(SstrParts))
		end

		-- Make PRNT chunk
		local function MakePRNT()
			local prntHeader = {"PRNT","\0\0\0\0","","\0\0\0\0"}
			local buf = b_create(5 + 8 * instCount)
	
			b_writeu8(buf, 0, 0)
			b_writeu32(buf, 1, instCount)
	
			local obj_start = 5
			local par_start = 5 + 4 * instCount
	
			local lastObjRef, lastParRef
			for i = 1, instCount do
				local obj = orderedInstList[i]
				local ref = refs[obj]
				local par = parents[obj]
				local parRef = refs[par] or -1
	
				local accObjRef = lastObjRef and (ref - lastObjRef) or ref
				lastObjRef = ref
				local accParRef = lastParRef and (parRef - lastParRef) or parRef
				lastParRef = parRef
	
				local oTrans = (accObjRef < 0 and 2 * -accObjRef - 1 or 2 * accObjRef)
				local pTrans = (accParRef < 0 and 2 * -accParRef - 1 or 2 * accParRef)
	
				local base = i - 1
				b_writeu8(buf, obj_start + base, b32_extract(oTrans, 24, 8))
				b_writeu8(buf, obj_start + base + instCount, b32_extract(oTrans, 16, 8))
				b_writeu8(buf, obj_start + base + instCount * 2, b32_extract(oTrans, 8, 8))
				b_writeu8(buf, obj_start + base + instCount * 3, b32_extract(oTrans, 0, 8))
	
				b_writeu8(buf, par_start + base, b32_extract(pTrans, 24, 8))
				b_writeu8(buf, par_start + base + instCount, b32_extract(pTrans, 16, 8))
				b_writeu8(buf, par_start + base + instCount * 2, b32_extract(pTrans, 8, 8))
				b_writeu8(buf, par_start + base + instCount * 3, b32_extract(pTrans, 0, 8))
			end
	
			local prntChunkData = b_tostring(buf)
			prntHeader[3] = s_pack("<I4", #prntChunkData)
			if lz4compress then
				prntChunkData = lz4compress(prntChunkData)
				prntHeader[2] = s_pack("<I4", #prntChunkData)
			end
	
			prntBuf[1] = tblconcat(prntHeader)
			prntBuf[2] = prntChunkData
		end
		MakePRNT()

		-- Wrap up and compile global file header
		local HeaderWriter = BufferWriter.New(32)
		HeaderWriter:WriteRawString("<roblox!\137\255\13\10\26\10\0\0")
		HeaderWriter:WriteInt32LE(instTypeCount)
		HeaderWriter:WriteInt32LE(instCount)
		HeaderWriter:WriteUInt32LE(0)
		HeaderWriter:WriteUInt32LE(0)
	
		local BuiltHeader = HeaderWriter:ToString()
		local BuiltMeta = "\77\69\84\65\36\0\0\0\34\0\0\0\0\0\0\0\240\19\1\0\0\0\18\0\0\0\69\120\112\108\105\99\105\116\65\117\116\111\74\111\105\110\116\115\4\0\0\0\116\114\117\101"
		local BuiltEnd = "\69\78\68\0\0\0\0\0\9\0\0\0\0\0\0\0\60\47\114\111\98\108\111\120\62"

		local FinalChunks = {BuiltHeader, BuiltMeta}
		local count = 3

		local SstrLen = #sstrBuf
		if SstrLen > 0 then
			tblmove(sstrBuf, 1, SstrLen, count, FinalChunks)
			count = count + SstrLen
		end

		local InstLen = #instBuf
		if InstLen > 0 then
			tblmove(instBuf, 1, InstLen, count, FinalChunks)
			count = count + InstLen
		end

		local PropLen = #propBuf
		if PropLen > 0 then
			tblmove(propBuf, 1,PropLen, count, FinalChunks)
			count = count + PropLen
		end

		local PrntLen = #prntBuf
		if PrntLen > 0 then
			tblmove(prntBuf, 1, PrntLen, count, FinalChunks)
			count = count + PrntLen
		end

		FinalChunks[count] = BuiltEnd
		local FinalBuffer = tblconcat(FinalChunks)

		if not saveSettings.Clipboard and not saveSettings.Callback then
			env.writefile(filename, FinalBuffer)

			if statusText then
				statusText.Update("Saved to the file "..filename.." in "..string.format("%.3f", os.clock() - startB).." secs")
				delay(5,statusText.Remove)
			end
		else
			if saveSettings.Clipboard then
				if setrbxclipboard then
					setrbxclipboard(FinalBuffer)
				end
			elseif saveSettings.Callback and type(saveSettings.Callback) == "function" then
				task.spawn(saveSettings.Callback, FinalBuffer)
			end
		end
	end

	

	local function serializeXML(root,filename,saveSettings)
		local isGame = root == game
		local isTable = type(root) == "table"
		if isTable and not root[1] then error("Empty Table") end

		if not filename or filename == "" then
			local clean = function(s) return (string.gsub(string.gsub(s or "Game", "[^%w%s-_]", ""), "%s+", "_")) end
			if isGame then
				local ok, info = pcall(service.MarketplaceService.GetProductInfoAsync, service.MarketplaceService, game.PlaceId)
				filename = "Place_" .. game.PlaceId .. "_" .. (ok and info and clean(info.Name) or "Game") .. ".rbxlx"
			else
				local inst = isTable and root[1] or root
				filename = "Model_" .. game.PlaceId .. "_" .. clean(inst.Name) .. "_" .. string.sub(inst:GetDebugId(), 1, 8) .. ".rbxmx"
			end
		else
			filename = filename:match(isGame and "%.rbxlx?$" or "%.rbxmx?$") and filename or filename .. (isGame and ".rbxlx" or ".rbxmx")
		end

		if saveSettings.AvoidFileOverwrite and env.isfile and env.isfile(filename) then
			local base, ext = filename:match("^(.-)(%.[^%.]+)$")
			base = base or filename
			ext = ext or ""
			local counter = 1
			while env.isfile(filename) do
				filename = base .. " (" .. counter .. ")" .. ext
				counter += 1
			end
		end

		env.writefile(filename,"")

		local startB = os.clock()
		local folderClasses = {["Player"] = true, ["PlayerScripts"] = true, ["PlayerGui"] = true, ["ScriptDebugger"] = true, ["Breakpoints"] = true, ["DebuggerWatch"] = true}
		local insts = {}
		local refs = setmetatable({}, { __mode = "k" })
		local refCount = 1
		local depths = {}
		local filter = {}
		local parents = {}
		local hashs = {}
		local sharedStrings = {}
		local savingDefaultProps = not saveSettings.IgnoreDefaultProps
		local decompileEnabled = saveSettings.Decompile
		local statusText = saveSettings.ShowStatus and createStatusText()
		local sources = predecompile(root,statusText,saveSettings)

		-- Set up filter
		if isGame then
			for i,v in service.Players:GetPlayers() do
				if not saveSettings.SavePlayers then
					filter[v] = true
				end

				if saveSettings.RemovePlayerCharacters and v.Character then
					filter[v.Character] = true
				end
			end
		end

		if saveSettings.IsolateStarterPlayer then
			folderClasses["StarterPlayer"] = true
			folderClasses["StarterCharacterScripts"] = true
			folderClasses["StarterPlayerScripts"] = true
		end

		local OutputArray = tableCreate(100000)
		OutputArray[1] = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n<Meta name="ExplicitAutoJoints">true</Meta>\n<External>null</External>\n<External>nil</External>'
		local OutCount = 2

		local function recur(obj)
			if filter[obj] then return end

			local class = oldIndex and oldIndex(obj,"ClassName") or obj.ClassName
			if folderClasses[class] then
				class = "Folder"
				if not saveProps["Folder"] then saveProps["Folder"] = getSaveProps(Instance.new("Folder"),"Folder") end
			end

			local ref = refs[obj]
			if not ref then ref = refCount refs[obj] = ref refCount = refCount + 1 end

			local props = saveProps[class]
			if not props then props = getSaveProps(obj,class) saveProps[class] = props end

			local testInst = testInsts[class]
			if not testInst then testInst = (not savingDefaultProps and getTestInst(class) or {}) testInsts[class] = testInst end

			OutputArray[OutCount] = format('\n<Item class="%s" referent="RBX%d">\n<Properties>',class,ref)
			OutCount = OutCount + 1

			for I = 1, #props do
				local Prop = props[I]
				local PropName = Prop.Name
				local IndexName = Prop.IndexName or PropName
				local PropVal

				local Special = Prop.Special
				if Special then
					if Special == "NotScriptable" then
						PropVal = getnspval and getnspval(obj,IndexName)
					elseif Special == "BinaryString" then
						PropVal = getbspval and getbspval(obj,IndexName,true)
					elseif Special == "SharedString" and gethiddenprop and hashmd5 then
						local Content = gethiddenprop(obj,IndexName)
						if Content and #Content > 0 then
							local Hash = hashs[Content]
							if not Hash then
								local RawHash = hashmd5(Content)
								local NewHash = ""
								for j = 1,#RawHash,2 do
									NewHash = NewHash..string.char(tonumber(RawHash:sub(j,j+1),16))
								end
								Hash = encodeBase64(NewHash)
								hashs[Content] = Hash
							end

							if not sharedStrings[Hash] then
								sharedStrings[Hash] = encodeBase64(Content)
							end
							PropVal = Hash
						end
					elseif Special == "Func" then
						PropVal = Prop.Func(obj)
					elseif Special == "Decompile" then
						if sources[obj] then
							PropVal = sources[obj]
						elseif not decompileEnabled then
							PropVal = "-- Decompiling is disabled"
						else
							PropVal = "-- Script failed to decompile or ignored"
						end
					end
				else
					if oldIndex then PropVal = oldIndex(obj,IndexName) else PropVal = obj[IndexName] end
				end

				if testInst[IndexName] ~= PropVal or (savingDefaultProps and PropVal ~= nil) then
					local TypeData = Prop.ValueType
					local PropType = TypeData.Name

					local ConvertFunc = valueConverters[PropType]
					if ConvertFunc then
						OutputArray[OutCount] = ConvertFunc(PropName,PropVal)
					elseif TypeData.Category == "Enum" then
						OutputArray[OutCount] = format('\n<token name="%s">%d</token>',PropName,PropVal.Value)
					elseif classes[PropType] and PropVal then
						local Ref = refs[PropVal]
						if not Ref then Ref = refCount refs[PropVal] = Ref refCount = refCount + 1 end
						OutputArray[OutCount] = format('\n<Ref name="%s">RBX%d</Ref>',PropName,Ref)
					else
						OutputArray[OutCount] = ""
					end
					OutCount = OutCount + 1
				end
			end

			OutputArray[OutCount] = '\n</Properties>'
			OutCount = OutCount + 1

			local Ch = getChildren(obj)
			local SzCh = #Ch
			if SzCh > 0 then
				for I = 1, SzCh do
					recur(Ch[I])
				end
			end

			OutputArray[OutCount] = '\n</Item>'
			OutCount = OutCount + 1
		end

		if isGame then
			local gameCh = getChildren(root)
			for i = 1,#gameCh do
				local obj = gameCh[i]
				if not serviceBlacklist[obj.ClassName] then
					recur(obj)
				end
			end
	
			if saveSettings.IsolateLocalPlayer then
				local lp = service.Players.LocalPlayer
				if lp then
					local LpFolder = Instance.new("Folder")
					LpFolder.Name = "LocalPlayer"
					nilBlacklist[LpFolder] = true
					recur(LpFolder)
					for _, child in lp:GetChildren() do
						if child.ClassName == "PlayerGui" or child.ClassName == "PlayerScripts" or child.ClassName == "StarterGear" then
							parents[child] = LpFolder
							recur(child)
						end
					end
				end
			end

			local message = readMeStart

			for i, v in next, saveSettings do
				if type(v) == "table" then
					local strings = {}
					for j, k in next, v do
						strings[#strings+1] = type(k) == "string" and ("\"" .. tostring(k) .. "\"") or tostring(v)
					end
					message = message .. "\t" .. tostring(i) .. " = { " .. tblconcat(strings, ", ") .. " }\n"
				elseif i ~= "_Recurse" then
					message = message .. "\t" .. tostring(i) .. " = " .. tostring(v) .. "\n"
				end
			end

			message = message .. "]]"

			OutputArray[OutCount] = [==[

<Item class="Script" referent="RBX999999999">
<Properties>
<string name="Name">README</string>
<ProtectedString name="Source">]==]..gsub(message, xmlReplacePattern, xmlReplace)..[==[</ProtectedString>
</Properties>
</Item>]==]
			OutCount = OutCount + 1
		elseif isTable then
			for i = 1,#root do
				recur(root[i])
			end
		else
			recur(root)
		end

		-- Nil Instances
		if saveSettings.NilInstances and root == game and getnilinstances then
			local folderRef = refCount
			refCount = refCount + 1
			OutputArray[OutCount] = '\n<Item class="Folder" referent="RBX'..folderRef..'">\n<Properties>\n<string name="Name">Nil Instances</string>\n</Properties>'
			OutCount = OutCount + 1

			local classes = API.Classes
			local nilInsts = getnilinstances()
			for i = 1,#nilInsts do
				local obj = nilInsts[i]
				local class = oldIndex and oldIndex(obj,"ClassName") or obj.ClassName
				if classes[class] and not classes[class].Tags.Service and not classes[class].Tags.NotCreatable and obj ~= game then
					local parentClass = nilClassParents[class]
					if parentClass then
						local parentRef = refCount
						refCount = refCount + 1
						OutputArray[OutCount] = format('\n<Item class="%s" referent="RBX%d">\n<Properties>\n<string name="Name">%s Class</string>\n</Properties>',parentClass,parentRef,class)
						OutCount = OutCount + 1
						recur(obj)
						OutputArray[OutCount] = "\n</Item>"
						OutCount = OutCount + 1
					else
						local isNilSafe = nilSafe[class]
						if isNilSafe == nil then
							isNilSafe = true
							local folder = Instance.new("Folder")
							local s,inst = pcall(Instance.new,class)
							if s and not pcall(function() inst.Parent = folder end) then
								isNilSafe = false
							end
							nilSafe[class] = isNilSafe
						end
						if isNilSafe then recur(obj) end
					end
				end
			end
			OutputArray[OutCount] = "\n</Item>"
			OutCount = OutCount + 1
		end

		-- SharedStrings
		OutputArray[OutCount] = "\n<SharedStrings>"
		OutCount = OutCount + 1
		for hash,content in next,sharedStrings do
			OutputArray[OutCount] = '\n<SharedString md5="'..hash..'">'..content..'</SharedString>'
			OutCount = OutCount + 1
		end

		OutputArray[OutCount] = "\n</SharedStrings>\n</roblox>"
	
		env.writefile(filename, tblconcat(OutputArray))
	
		table.clear(OutputArray)
		table.clear(hashs)
		table.clear(sharedStrings)

		if statusText then
			statusText.Update("Saved to the file "..filename.." in "..(os.clock() - startB).." secs")
			delay(5,statusText.Remove)
		end
	end

	Serializer.SaveInstance = function(root,filename,opts)
		if not gameId then gameId = game.GameId end
		local saveSettings = {}
		for set,val in Settings.Serializer do
			if opts and opts[set] ~= nil then
				saveSettings[set] = opts[set]
			else
				saveSettings[set] = val
			end
		end
		if not filename or filename == "" then
			filename = saveSettings.FilePath
		end
		if saveSettings.DecompileMode and saveSettings.DecompileMode > 0 then saveSettings.Decompile = true end

		-- Activate safety features
		if saveSettings.SafeMode then
			ActivateSafeMode()
			ksscripts()
			-- SafeMode also enables these protections
			saveSettings.BoostFPS = true
			saveSettings.KillAllScripts = true
		end
		if saveSettings.BoostFPS then BoostFPS() end
		if saveSettings.AntiIdle then AntiIdle() end
		if saveSettings.Anonymous then cleanAnonymousData(root, saveSettings) end

		-- Handle different modes
		local mode = (saveSettings.Mode or "full"):lower()
		if mode == "scripts" then
			saveSettings.Decompile = true
			saveSettings.NilInstances = false
		elseif mode == "models" then
			saveSettings.Decompile = false
		end

		local ok, statusText
		if saveSettings.Binary then
			ok, statusText = serializeBinary(root,filename,saveSettings)
		else
			ok, statusText = serializeXML(root,filename,saveSettings)
		end

		-- Cleanup
		if antiAfkCon then pcall(function() antiAfkCon:Disconnect() end) end
		if statusText and type(statusText.Remove) == "function" then
			pcall(statusText.Remove)
		end

		return ok, statusText
	end

	Serializer.Init = function(oldInd)
		oldIndex = oldInd

		gethiddenprop = env.gethiddenprop or env.getnspval
		getnspval = gethiddenprop
		getbspval = env.getbspval
		getnilinstances = env.getnilinstances
		getpcd = env.getpcd
		encodeBase64 = env.encodeBase64
		lz4compress = env.lz4compress
		classes = API.Classes
		hashmd5 = env.hashmd5

		if not getbspval and gethiddenprop and encodeBase64 then
			getbspval = function(obj,prop,enc)
				local binary = gethiddenprop(obj,prop) or ""
				if #binary == 0 then return nil end
				return enc and encodeBase64(binary) or binary
			end
		end
	end

	return Serializer
end)()

Main = (function()
	local Main = {}

	Main.FetchAPI = function()
		--local robloxVer = game:HttpGet("http://setup.roblox.com/versionQTStudio")
		local rawAPI
	
		if game:GetService("RunService"):IsStudio() then
			rawAPI = require(game.ReplicatedStorage.FullAPI)
		else
			rawAPI = game:HttpGet("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/Full-API-Dump.json")
		end
	
		local api = service.HttpService:JSONDecode(rawAPI)
		local classes,enums = {},{}

		for _,class in api.Classes do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = classes[class.Superclass]
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then for c,tag in class.Tags do newClass.Tags[tag] = true end end

			for __,member in class.Members do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Tags = {}
				if member.Tags then for c,tag in member.Tags do newMember.Tags[tag] = true end end

				local mType = member.MemberType
				if mType == "Property" then
					local vt = member.ValueType
					if type(vt) == "string" then
						vt = { Name = vt }
					elseif type(vt) == "table" and vt.Name == nil then
						for k,v in vt do
							if type(v) == "string" then vt.Name = v; break end
						end
					end
					newMember.ValueType = vt
					newMember.Category = member.Category
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties,newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType.Name
					for c,param in member.Parameters do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c,param in member.Parameters do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,enum in api.Enums do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in enum.Tags do newEnum.Tags[tag] = true end end
			for __,item in enum.Items do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items,newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class,member)
			if not classes[class] or not classes[class][member] then return end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _,entry in currentClass[member] do
					result[#result+1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result,function(a,b) return a.Name < b.Name end)
			return result
		end

		return {
			Classes = classes,
			Enums = enums,
			GetMember = getMember
		}
	end

	Main.ResetSettings = function()
		local function recur(t)
			local res = {}
			for set,val in t do
				if type(val) == "table" and val._Recurse then
					res[set] = recur(val)
				else
					res[set] = val
				end
			end
			return res
		end
		Settings = recur(DefaultSettings)
	end

	return Main
end)()

return {
	Init = function(oldindex)
		local api, e = Main.FetchAPI() -- TODO: only request new api on roblox updates?
		if not api then
			return nil, "FetchAPI failed (" .. tostring(e) .. ")"
		end
		API = api

		env = {}
		env.writefile = writefile
		env.appendfile = appendfile
		env.readfile = readfile or read_file
		env.isfile = isfile or is_file
		env.getnilinstances = getnilinstances or get_nil_instances
		env.gethiddenprop = gethiddenproperty or gethiddenprop
		env.getnspval = getnspval
		env.getbspval = getbspval
		env.getpcd = getpcd or getpcdprop
		env.encodeBase64 = (syn and syn.crypt.base64.encode) or base64encode or (crypt and crypt.base64encode)
		env.lz4compress = lz4compress or (syn and syn.crypt.lz4.compress)
		env.hashmd5 = (syn and function(s) return syn.crypt.custom.hash("md5",s) end) or (crypt and function(s) return crypt.hash(s,"md5") end)

		local missing = {}
		if type(env.writefile) ~= "function" then table.insert(missing, "writefile") end
		if type(env.appendfile) ~= "function" then table.insert(missing, "appendfile") end
		if #missing > 0 then
			return nil, "Missing environment functions: " .. table.concat(missing, ", ")
		end

		Main.ResetSettings()
		Serializer.Init(oldindex)

		return true
	end,

	Save = function(object, filename, options)
		return Serializer.SaveInstance(object, filename, options)
	end
}
