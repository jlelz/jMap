local _,Library = ...;
local jMap = LibStub( 'AceAddon-3.0' ):GetAddon( 'jMap' );

function jMap:SetDBValue( Index,Value )
    if( self:GetPersistence()[ Index ] ~= nil ) then
        self:GetPersistence()[ Index ] = Value;
    end
end

function jMap:GetDBValue( Index )
    if( self:GetPersistence()[ Index ] ~= nil ) then
        return self:GetPersistence()[ Index ];
    end
end

function jMap:GetPersistence()
    return self.db.global;
end

function jMap:Reset()
    -- Wipe Database
    wipe( self.db.global ); 

    -- Reset Profile
    self.db:ResetProfile();

    -- Refresh Settings
    if( C_UI and C_UI.Reload ) then
        C_UI.Reload();
    else
        ReloadUI();
    end
end

function jMap:InitializeDB()
    local Defaults = {
        global = {
            MapPoint = 'TOPLEFT',
            MapRelativeTo = 'UIParent',
            MapRelativePoint = nil,
            MapXPos = 4.584,
            MapYPos = -6.965,
            MapScale = 0.866,
            MapAlpha = 0.2,
            MapFade = false,

            MiniRotate = true,

            PinAnimDuration = 10,
            PinAnimScale = 1.5,
            PinPing = true,
            PinPingSeconds = 10,
            SkullMyAss = 'Pink',
            ClassColors = false,
            AlwaysShow = true,
            PanelColapsed = true,
            StopReading = true,
            SitBehind = false,
            UpdateWorldMapFrameZone = true,
            ScrollScale = true,
            Debug = false,
        },
    };

    self.db = LibStub( 'AceDB-3.0' ):New( self:GetName(),Defaults,'global' );

    self.db.RegisterCallback( self,'OnProfileChanged','Reset' );
    self.db.RegisterCallback( self,'OnProfileCopied','Reset' );
    self.db.RegisterCallback( self,'OnProfileReset','Reset' );
end