local _,Library = ...;
local jMap = LibStub( 'AceAddon-3.0' ):GetAddon( 'jMap' );

function jMap:GetSettings()
    local GetMiniMap = function()
        local Order = 1;
        local Settings = {
            MiniMap = {
                type = 'header',
                order = Order,
                name = 'Mini Map',
            },
        };
        Order = Order+1;
        Settings.MiniRotate = {
            order = Order,
            type = 'toggle',
            name = 'Rotate Mini Map',
            desc = 'If the minimap should rotate based on your movement',
            arg = 'MiniRotate',
        };

        return Settings;
    end
    local GetMainMap = function()
        local Order = 1;
        local Settings = {
            MainMap = {
                type = 'header',
                order = Order,
                name = 'Main Map',
            },
        };
        Order = Order+1;
        Settings.AlwaysShow = {
            order = Order,
            type = 'toggle',
            name = 'Always Show Map',
            desc = 'Whether or not the map should remain open at all times',
            arg = 'AlwaysShow',
        };
        Order = Order+1;
        Settings.MapAlpha = {
            order = Order,
            type = 'range',
            name = 'Map Alpha',
            desc = 'Map transparency/how well you can see behind the map while open',
            min = 0.1, max = 1, step = 0.1,
            arg = 'MapAlpha',
        };
        Order = Order+1;
        Settings.SitBehind = {
            order = Order,
            type = 'toggle',
            name = 'Sit Behind Windows',
            desc = 'If the map should sit behind other windows',
            arg = 'SitBehind',
        };
        Order = Order+1;
        Settings.UpdateWorldMapFrameZone = {
            order = Order,
            type = 'toggle',
            name = 'Auto Update Zone',
            desc = 'Attempt to transition map to new zone automatically. Retail has known issues with this, as it seems to cause some errors',
            arg = 'UpdateWorldMapFrameZone',
        };
        Order = Order+1;
        Settings.StopReading = {
            order = Order,
            type = 'toggle',
            name = 'Stop Reading Emote',
            desc = 'If your character should /read while the map is open',
            arg = 'StopReading',
        };
        if( Library:IsRetail() ) then
            Order = Order+1;
            Settings.PanelColapsed = {
                order = Order,
                type = 'toggle',
                name = 'Quest Panel Closed',
                desc = 'Whether or not the map should expand the quest list',
                arg = 'PanelColapsed',
            };
        end
        Order = Order+1;
        Settings.MapScale = {
            order = Order,
            type = 'range',
            name = 'Map Scale',
            desc = 'The size of the map in scale',
            min = .1, max = 3, step = .1,
            arg = 'MapScale',
        };
        Order = Order+1;
        Settings.ScrollScale = {
            order = Order,
            type = 'toggle',
            name = 'Allow Scroll Scaling',
            desc = 'If scrolling inside the map scrollwindow should cause the map to scale',
            arg = 'ScrollScale',
        };
        Order = Order+1;
        Settings.Debug = {
            order = Order,
            type = 'toggle',
            name = 'Debug',
            desc = 'Development debugging',
            arg = 'Debug',
        };

        return Settings;
    end
    local GetPins = function()
        local Order = 1;
        local Settings = {
            General = {
                type = 'header',
                order = Order,
                name = 'Pins',
            },
        };
        Order = Order+1;
        Settings.PinPing = {
            order = Order,
            type = 'toggle',
            name = 'Animation',
            desc = 'Pin animation',
            arg = 'PinPing',
        };
        Order = Order+1;
        Settings.PinAnimDuration = {
            order = Order,
            type = 'range',
            name = 'Animation Duration',
            desc = 'Pin ping animation duration',
            min = 1, max = 10, step = 0.5,
            arg = 'PinAnimDuration',
        };
        Order = Order+1;
        Settings.SkullMyAss = {
            order = Order,
            type = 'select',
            name = 'Pin',
            desc = 'Your player icon on the map',
            values = {
                Pink = 'Pink',
                Blue = 'Blue',
                Yellow = 'Yellow',
                Green = 'Green',
                Grey = 'Grey',
                Red = 'Red',
                Normal = 'Normal', 
            },
            arg = 'SkullMyAss',
        };
        Order = Order+1;
        Settings.ClassColors = {
            order = Order,
            type = 'toggle',
            name = 'Class Colors',
            desc = 'If group members should show on the map with their respective class colors',
            arg = 'ClassColors',
        };
        Order = Order+1;
        Settings.PinAnimScale = {
            order = Order,
            type = 'range',
            name = 'Animation Scale',
            desc = 'Pin animation scale',
            min = 1, max = 3, step = 0.5,
            arg = 'PinAnimScale',
        };
        -- /Interface/FrameXML/UnitPositionFrameTemplates.lua
        return Settings;
    end

    local Settings = {
        type = 'group',
        get = function( Info )
            if( self:GetPersistence()[ Info.arg ] ~= nil ) then
                return self:GetPersistence()[ Info.arg ];
            end
        end,
        set = function( Info,Value )
            if( self:GetPersistence()[ Info.arg ] ~= nil ) then
                self:GetPersistence()[ Info.arg ] = Value;
                if( jMap.Refresh ) then
                    jMap:Refresh();
                end
            end
        end,
        name = 'jMap Settings',
        childGroups = 'tab',
        args = {},
    };

    -- Main Map
    local Order = 0;
    Settings.args[ 'tab'..Order ] = {
        type = 'group',
        name = 'Main Map',
        width = 'full',
        order = Order,
        args = GetMainMap(),
    };

    -- Mini Map
    Order = Order+1;
    Settings.args[ 'tab'..Order ] = {
        type = 'group',
        name = 'Mini Map',
        width = 'full',
        order = Order,
        args = GetMiniMap(),
    };

    -- Map Pins
    Order = Order+1;
    Settings.args[ 'tab'..Order ] = {
        type = 'group',
        name = 'Pins',
        width = 'full',
        order = Order,
        args = GetPins(),
    };

    Settings.args.profiles = LibStub( 'AceDBOptions-3.0' ):GetOptionsTable( self.db );

    return Settings;
end

function jMap:RegisterSettings()
    LibStub( 'AceConfig-3.0' ):RegisterOptionsTable( self:GetName(),self:GetSettings() );
end

function jMap:AddToBlizOptions()
    _,self.CategoryID = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( self:GetName(),self:GetName() );
end

function jMap:InitializeConfig()
    self:RegisterSettings();
    self:AddToBlizOptions();
end