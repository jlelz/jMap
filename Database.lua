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

function jMap:Reset()
    if( not self.db ) then
        return;
    end
    self.db:ResetDB();
end

function jMap:GetPersistence()
    if( not self.db ) then
        return;
    end
    local Player = UnitName( 'player' );
    local Realm = GetRealmName();
    local PlayerRealm = Player..'-'..Realm;

    self.persistence = self.db.global;
    if( not self.persistence ) then
        return;
    end
    return self.persistence;
end

function jMap:RefreshDB( Event,Database,NewProfileKey )
    Addon.FRAMES:Notify( 'Profile changed to: ',NewProfileKey );
    jMap:Refresh();
end

function jMap:InitializeDB()
    self.Defaults = {
        MapPoint = 'TOPLEFT',
        MapRelativeTo = 'UIParent',
        MapRelativePoint = nil,
        MapXPos = 15.480,
        MapYPos = -48.181,
        MapScale = 0.866,
        MapAlpha = 0.2,
        MapFade = false,

        MiniRotate = true,

        PinAnimDuration = 10,
        PinAnimScale = 1.5,
        PinPing = true,
        PinPingSeconds = 10,
        SkullMyAss = 'Pink',
        MatchWorldScale = true,
        ClassColors = false,
        AlwaysShow = true,
        PanelColapsed = true,
        StopReading = true,
        SitBehind = false,
        UpdateWorldMapFrameZone = true,
        ScrollScale = true,
        Debug = false,
    };

    self.db = LibStub( 'AceDB-3.0' ):New( self:GetName(),{ global = self.Defaults },true );

    self.db.RegisterCallback( self,'OnProfileChanged',jMap.RefreshDB );
    self.db.RegisterCallback( self,'OnProfileCopied',jMap.RefreshDB );
    self.db.RegisterCallback( self,'OnProfileReset',jMap.RefreshDB );
end