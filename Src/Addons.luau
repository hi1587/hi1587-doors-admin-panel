-- Addons
if getgenv().admin_disable_addons or getgenv().admin_addons_activated then 
    return {}
end

task.spawn(function()
    if not wax.shared.ExecutorSupport["_SupportsFileSystem"] then
        warn("[admin] Your executor doesn't support the FileSystem API. Addons will not work.")
        return
    end

    getgenv().admin_addons_activated = true

    if not isfolder("hi1587s admin panel/addons") then
        print("[admin] Addons folder doesn't exist. Creating...")
        makefolder("hi1587s admin panel/addons")
        return
    end
    
    repeat task.wait() until getgenv().admin_loaded == true
    print("[admin] Loading addons...")
    
    local function AddAddonElement(LinoriaElement, AddonName, Element)
        if not LinoriaElement then
            warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid Linoria element.")
            return
        end

        if typeof(Element) ~= "table" then
            warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid data.")
            return
        end 

        if typeof(Element.Type) ~= "string" then 
            warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid name.")
            return 
        end

        if typeof(AddonName) ~= "string" then 
            warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid addon name.")
            return 
        end

        
        if Element.Type:sub(1, 3) == "Add" then Element.Type = Element.Type:sub(4) end

        -- Elements with no Arguments
        if Element.Type == "Divider" then
            return LinoriaElement:AddDivider()
        end

        if Element.Type == "DependencyBox" then
            return LinoriaElement:AddDependencyBox()
        end

        if typeof(Element.Name) ~= "string" then 
            warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid name.")
            return 
        end

        -- Elements with Arguments
        if typeof(Element.Arguments) == "table" then
            if Element.Type == "Label" then
                return LinoriaElement:AddLabel(table.unpack(Element.Arguments))
            end

            if Element.Type == "Toggle" then
                return LinoriaElement:AddToggle(AddonName .. "_" .. Element.Name, Element.Arguments)
            end
            
            if Element.Type == "Button" then
                return LinoriaElement:AddButton(Element.Arguments)
            end
            
            if Element.Type == "Slider" then
                return LinoriaElement:AddSlider(AddonName .. "_" .. Element.Name, Element.Arguments)
            end
            
            if Element.Type == "Input" then
                return LinoriaElement:AddInput(AddonName .. "_" .. Element.Name, Element.Arguments)
            end
            
            if Element.Type == "Dropdown" then
                return LinoriaElement:AddInput(AddonName .. "_" .. Element.Name, Element.Arguments)
            end
            
            if Element.Type == "ColorPicker" then
                return LinoriaElement:AddColorPicker(AddonName .. "_" .. Element.Name, Element.Arguments)        
            end
            
            if Element.Type == "KeyPicker" then
                return LinoriaElement:AddKeyPicker(AddonName .. "_" .. Element.Name, Element.Arguments)
            end
        end

        warn("[admin] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid element type.")
        return
    end
    
    local AddonTab, LastGroupbox = nil, "Right"
    
    local function createAddonTab(hasAddons: boolean)
        if not AddonTab then
            AddonTab = shared.Window:AddTab("Addons [BETA]")
        end
        
        AddonTab:UpdateWarningBox({
            Visible = true,
            Title = "WARNING",
            Text =  (if not hasAddons then "Your addons FOLDER is empty!" else "This tab is for UN-OFFICIAL addons made for admin. We are not responsible for what addons you will use. You are putting yourself AT RISK since you are executing third-party scripts.")
        })
    end

    local containAddonsLoaded = false
    createAddonTab(false)
    
    for _, file in pairs(listfiles("hi1587s admin panel/addons")) do
        print("[admin] Loading addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "'...")
        if file:sub(#file - 3) ~= ".lua" and file:sub(#file - 4) ~= ".luau" and file:sub(#file - 7) ~= ".lua.txt" then continue end
        
        local success, errorMessage = pcall(function()
            local fileContent = readfile(file)
            local addon = loadstring(fileContent)()

            if typeof(addon.Name) ~= "string" or typeof(addon.Elements) ~= "table" then
                warn("Addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "' didn't load: Invalid Name/Elements.")
                return 
            end

            if typeof(addon.Game) == "string" then
                if string.lower(addon.Game) ~= string.lower(shared.ScriptLoader) and addon.Game ~= "*" then
                    warn("Addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "' didn't load: Wrong game.")
                    return
                end
            elseif typeof(addon.Game) == "table" then
                for i, addonGame in pairs(addon.Game) do
                    addon.Game[i] = string.lower(addonGame)
                end

                if not table.find(addon.Game, string.lower(shared.ScriptLoader)) then
                    warn("Addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "' didn't load: Wrong game.")
                    return
                end
            else
                warn("Addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "' didn't load: Invalid GameId.")
                return
            end

            addon.Name = addon.Name:gsub("%s+", "")
            if typeof(addon.Title) ~= "string" then
                addon.Title = addon.Name
            end

            if not AddonTab then createAddonTab(true) end
            
            local AddonGroupbox = if LastGroupbox == "Right" then AddonTab:AddLeftGroupbox(addon.Title) else AddonTab:AddRightGroupbox(addon.Title)
            LastGroupbox = if LastGroupbox == "Right" then "Left" else "Right"
            if typeof(addon.Description) == "string" then
                AddonGroupbox:AddLabel(addon.Description, true)
            end

            local function loadElements(linoriaMainElement, elements)
                if not elements or typeof(elements) ~= "table" then return end

                for _, element in pairs(elements) do                      
                    local linoriaElement = AddAddonElement(linoriaMainElement, addon.Name, element)
                    
                    loadElements(linoriaElement, element.Elements)
                end
            end

            loadElements(AddonGroupbox, addon.Elements)
        end)

        if not success then
            warn("[admin] Failed to load addon '" .. string.gsub(file, "hi1587s admin panel/addons/", "") .. "':", errorMessage)
        else
            containAddonsLoaded = true
        end
    end
    
    createAddonTab(containAddonsLoaded)
end)

return {}
