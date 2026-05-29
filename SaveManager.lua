local httpService = game:GetService('HttpService')
local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Library = nil
	SaveManager.Ignore = {}

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName"
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {self.Folder, self.Folder .. '/settings'}
		for _, path in ipairs(paths) do
			if not isfolder(path) then
				makefolder(path)
			end
		end
	end

	function SaveManager:Save(name)
		if not name or name:gsub("%s+", "") == "" then
			return self.Library:Notify('Invalid config name', 3)
		end

		local data = { objects = {} }

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, { type = 'Toggle', idx = idx, value = toggle.Value })
		end

		for idx, option in next, Options do
			if self.Ignore[idx] then continue end
			if option.Type == 'Slider' then
				table.insert(data.objects, { type = 'Slider', idx = idx, value = option.Value })
			elseif option.Type == 'Dropdown' then
				table.insert(data.objects, { type = 'Dropdown', idx = idx, value = option.Value })
			elseif option.Type == 'ColorPicker' then
				table.insert(data.objects, { type = 'ColorPicker', idx = idx, value = option.Value:ToHex(), transparency = option.Transparency })
			elseif option.Type == 'KeyPicker' then
				table.insert(data.objects, { type = 'KeyPicker', idx = idx, key = option.Value, mode = option.Mode })
			elseif option.Type == 'Input' then
				table.insert(data.objects, { type = 'Input', idx = idx, text = option.Value })
			end
		end

		writefile(self.Folder .. '/settings/' .. name .. '.json', httpService:JSONEncode(data))
		self.Library:Notify('Saved config: ' .. name, 3)
	end

	function SaveManager:Load(name)
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then 
			return self.Library:Notify('Config not found', 3) 
		end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then 
			return self.Library:Notify('Failed to load config', 3) 
		end

		for _, obj in next, decoded.objects do
			task.spawn(function()
				if obj.type == 'Toggle' and Toggles[obj.idx] then
					Toggles[obj.idx]:SetValue(obj.value)
				elseif obj.type == 'Slider' and Options[obj.idx] then
					Options[obj.idx]:SetValue(obj.value)
				elseif obj.type == 'Dropdown' and Options[obj.idx] then
					Options[obj.idx]:SetValue(obj.value)
				elseif obj.type == 'ColorPicker' and Options[obj.idx] then
					Options[obj.idx]:SetValueRGB(Color3.fromHex(obj.value), obj.transparency)
				elseif obj.type == 'KeyPicker' and Options[obj.idx] then
					Options[obj.idx]:SetValue({ obj.key, obj.mode })
				elseif obj.type == 'Input' and Options[obj.idx] then
					Options[obj.idx]:SetValue(obj.text)
				end
			end)
		end

		self.Library:Notify('Loaded config: ' .. name, 3)
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')
		local out = {}
		for _, file in ipairs(list) do
			if file:sub(-5) == '.json' then
				local name = file:match("([^/\\]+)%.json$")
				if name then table.insert(out, name) end
			end
		end
		return out
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		section:AddButton('Create / Save', function()
			local name = Options.SaveManager_ConfigName.Value
			if name:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid name', 2)
			end
			self:Save(name)
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
		end)

		section:AddButton('Load', function()
			local name = Options.SaveManager_ConfigList.Value
			if name then self:Load(name) end
		end)

		section:AddButton('Refresh List', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
		end)

		section:AddButton('Set as Autoload', function()
			local name = Options.SaveManager_ConfigList.Value
			if name then
				writefile(self.Folder .. '/settings/autoload.txt', name)
				self.Library:Notify('Autoload set to: ' .. name, 3)
			end
		end)
	end

	function SaveManager:LoadAutoloadConfig()
		local path = self.Folder .. '/settings/autoload.txt'
		if isfile(path) then
			local name = readfile(path)
			if name and isfile(self.Folder .. '/settings/' .. name .. '.json') then
				self:Load(name)
			end
		end
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
