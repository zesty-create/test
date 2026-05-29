local httpService = game:GetService('HttpService')
local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Library = nil
	SaveManager.Options = {}
	SaveManager.IgnoredIndexes = {}

	function SaveManager:SetLibrary(lib)
		self.Library = lib
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetIgnoreIndexes(indexes)
		self.IgnoredIndexes = indexes
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

		local config = {}
		for i, v in next, self.Options do
			if not table.find(self.IgnoredIndexes, i) then
				config[i] = v.Value
			end
		end

		writefile(self.Folder .. '/settings/' .. name .. '.json', httpService:JSONEncode(config))
		self.Library:Notify('Saved config: ' .. name, 3)
	end

	function SaveManager:Load(name)
		local path = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(path) then
			return self.Library:Notify('Config not found', 3)
		end

		local content = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, content)
		if not success then
			return self.Library:Notify('Failed to decode config', 3)
		end

		for i, v in next, decoded do
			if self.Options[i] then
				self.Options[i]:SetValue(v)
			end
		end

		self.Library:Notify('Loaded config: ' .. name, 3)
	end

	function SaveManager:Delete(name)
		local path = self.Folder .. '/settings/' .. name .. '.json'
		if isfile(path) then
			delfile(path)
			self.Library:Notify('Deleted config: ' .. name, 3)
		end
	end

	function SaveManager:RefreshConfigs()
		local configs = {}
		local files = listfiles(self.Folder .. '/settings')
		for _, file in ipairs(files) do
			if file:sub(-5) == '.json' then
				local name = file:match("([^/\\]+)%.json$")
				if name then
					table.insert(configs, name)
				end
			end
		end
		return configs
	end

	function SaveManager:CreateConfigManager(groupbox)
		groupbox:AddDropdown('ConfigManager_List', {Text = 'Configs', Values = self:RefreshConfigs(), AllowNull = true})

		groupbox:AddInput('ConfigManager_Name', {Text = 'Config Name'})

		groupbox:AddButton('Save', function()
			self:Save(Options.ConfigManager_Name.Value)
			Options.ConfigManager_List:SetValues(self:RefreshConfigs())
		end)

		groupbox:AddButton('Load', function()
			self:Load(Options.ConfigManager_List.Value)
		end)

		groupbox:AddButton('Delete', function()
			self:Delete(Options.ConfigManager_List.Value)
			Options.ConfigManager_List:SetValues(self:RefreshConfigs())
		end)

		groupbox:AddButton('Refresh', function()
			Options.ConfigManager_List:SetValues(self:RefreshConfigs())
		end)
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library first!')
		local groupbox = tab:AddRightGroupbox('Config Manager')
		self:CreateConfigManager(groupbox)
	end

	function SaveManager:LoadAutoloadConfig()
		local path = self.Folder .. '/settings/autoload.txt'
		local autoload = isfile(path) and readfile(path)
		if autoload and isfile(self.Folder .. '/settings/' .. autoload .. '.json') then
			self:Load(autoload)
		end
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
