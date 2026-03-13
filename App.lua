local _,Library = ...;
local jMap = LibStub( 'AceAddon-3.0' ):NewAddon( 'jMap','AceEvent-3.0','AceHook-3.0','AceConsole-3.0' );
if( not WorldMapFrame ) then
    return;
end
local MainMapPlayerPin;
for Pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
    MainMapPlayerPin = Pin;
    break;
end 
if( not MainMapPlayerPin ) then
    return;
end

function jMap:SetValue( Index,Value )
    self:SetDBValue( Index,Value );
end

function jMap:GetValue( Index )
    return self:GetDBValue( Index );
end

function jMap:MainMapFrameSetPingSize()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( MainMapPlayerPin.SetPlayerPingScale ) then
        MainMapPlayerPin:SetPlayerPingScale( jMap:GetValue( 'PinAnimScale' )/WorldMapFrame:GetCanvasScale() );
    end
end

function jMap:MainMapFrameSetPinTextures()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end

    -- Pin Texture
    if( MainMapPlayerPin.SetPinTexture ) then
        local SkullPins = {
            Pink = 'Interface\\WorldMap\\Glowskull_64purple',
            Blue = 'Interface\\WorldMap\\Glowskull_64blue',
            Yellow = 'Interface\\WorldMap\\Glowskull_64',
            Green = 'Interface\\WorldMap\\Glowskull_64green',
            Grey = 'Interface\\WorldMap\\Glowskull_64grey',
            Red = 'Interface\\WorldMap\\Glowskull_64red',
            Normal = 'Interface\\WorldMap\\WorldMapArrow',
        };
        MainMapPlayerPin:SetPinTexture( 'player',SkullPins[ jMap:GetValue( 'PinColor' ) ] );
    end

    -- Ping Texture
    local PingWidth,PingHeight = 75,75;
    if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
        if( MainMapPlayerPin.SetPlayerPingTexture ) then
            MainMapPlayerPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
        end
    end
end

function jMap:MainMapFrameSetPartyColors()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( self:GetValue( 'ClassColors' ) ) then
        MainMapPlayerPin:SetUseClassColor( 'party',true );
        MainMapPlayerPin:SetUseClassColor( 'raid',true );
    else
        MainMapPlayerPin:SetUseClassColor( 'party',false );
        MainMapPlayerPin:SetUseClassColor( 'raid',false );
    end
end

function jMap:MainMapFramePing()
    if( self.PingTicker ) then
        self.PingTicker:Cancel();
    end
    local function PingMap()
        if( ( Library:IsRetail() and InCombatLockdown() ) ) then
            return;
        end
        if( WorldMapFrame:IsShown() ) then
            if( self:GetValue( 'PinPing' ) ) then
                MainMapPlayerPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
            else
                MainMapPlayerPin:StartPlayerPing( 1,0 );
                MainMapPlayerPin:StopPlayerPing();
            end
        end
    end
    local PingInterval = self:GetValue( 'PinPingSeconds' );
    self.PingTicker = C_Timer.NewTicker( PingInterval,function()
        securecall( function()
            PingMap();
        end );
    end );
    PingMap();
end

function jMap:MainMapFrameFade()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end

    -- Map Fade
    local function OnUpdate()
        local Setting = {
            MinAlpha = jMap:GetValue( 'MapMinAlpha' ),
            MaxAlpha = jMap:GetValue( 'MapMaxAlpha' ),
            TimeToMax = 0.1,
        };
        if( WorldMapFrame:IsMouseOver() ) then
            WorldMapFrame:SetAlpha( Setting.MaxAlpha );
        else
            WorldMapFrame:SetAlpha( Setting.MinAlpha );
        end
    end
    FrameFaderDriver = CreateFrame( 'FRAME',nil,WorldMapFrame );
    FrameFaderDriver:HookScript( 'OnUpdate',OnUpdate );
    PlayerMovementFrameFader.RemoveFrame( WorldMapFrame );
end

function jMap:MainMapFrameCheckShown()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( self:GetValue( 'AlwaysShow' ) ) then
        if( self:HasMap() ) then
            if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
                if( not self.WorldMapFrameClosed ) then
                    WorldMapFrame:Show();
                end
            end
        else
            WorldMapFrame:Hide();
        end
    else
        WorldMapFrame:Hide();
    end
end

function jMap:MainMapFrameMouseWheel( self,Value )
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( not jMap:GetValue( 'ScrollScale' ) ) then
        return;
    end
    local SliderData = {
        Name = 'MapScale',
        Step = .1,
        KeyPairs = {
            Low = {
                Value = .3,
                Description = 'Low',
            },
            High = {
                Value = 2,
                Description = 'High',
            },
        },
    };
    local RangeSlider = Library.FRAMES:AddRange( SliderData,WorldMapFrame,{
        -- AddRange initialization calls this
        Get = function( Index )
            return jMap:GetValue( 'MapScale' );
        end,
        -- AddRange:OnValueChanged calls this
        Set = function( Index,Value )
            print( 'Set',Index,Value)
            --return jMap:SetValue( 'MapScale',Value );
        end,
    },Library.Theme.Text.Colors.Default );

    local CurrentValue = jMap:GetValue( SliderData.Name );
    local ScrollDirection;
    if Value > 0 then
        ScrollDirection = 'up';
    else
        ScrollDirection = 'down';
    end

    local MaxValue;
    local MinValue;
    local NewValue;

    if ScrollDirection == 'up' then
        MaxValue = SliderData.KeyPairs.High.Value;
        NewValue = CurrentValue + SliderData.Step;
        if NewValue > MaxValue then
            return;
        end
    elseif ScrollDirection == 'down' then
        MinValue = SliderData.KeyPairs.Low.Value;
        NewValue = CurrentValue - SliderData.Step;
        if NewValue < MinValue then
            return;
        end
    end

    if( NewValue ~= nil ) then
        RangeSlider.EditBox:SetText( NewValue );
        jMap:SetValue( SliderData.Name,NewValue );
        jMap:MainMapFrameSetScale();
    end
end

function jMap:MainMapFrameStopMoving()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    WorldMapFrame:StopMovingOrSizing();
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
        if( MapXPos ~= nil and MapYPos ~= nil ) then
            jMap:SetValue( 'MapPoint',MapPoint );
            jMap:SetValue( 'MapRelativeTo',MapRelativeTo );
            jMap:SetValue( 'MapRelativePoint',MapRelativePoint );
            jMap:SetValue( 'MapXPos',MapXPos );
            jMap:SetValue( 'MapYPos',MapYPos );
        end
    end
    WorldMapFrame:SetUserPlaced( true );
end

function jMap:MainMapFrameStartMoving()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( not WorldMapFrame:IsMaximized() ) then
        WorldMapFrame:StartMoving();
    end
end

function jMap:MainMapFrameSetPosition()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
        if( MapXPos ~= nil and MapYPos ~= nil ) then
            WorldMapFrame:ClearAllPoints();
            WorldMapFrame:SetPoint( MapPoint,MapXPos,MapYPos );
        end
    end
end

function jMap:MainMapFrameEmote()
    if( C_ChatInfo and C_ChatInfo.PerformEmote ) then
        hooksecurefunc( C_ChatInfo,'PerformEmote',function( Emote )
            if( self:GetValue( 'StopReading' ) ) then
                C_ChatInfo.CancelEmote();
            end
        end );
    else
        hooksecurefunc( 'DoEmote',function( Emote )
            if( self:GetValue( 'StopReading' ) ) then
                CancelEmote();
            end
       end );
    end
end

function jMap:MainMapFrameSetStrata()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    local CurrentStrata = WorldMapFrame:GetFrameStrata();
    if( self:GetValue( 'SitBehind' ) and CurrentStrata ~= 'MEDIUM' ) then
        WorldMapFrame:SetFrameStrata( 'MEDIUM' );
    end
end

function jMap:MainMapFrameSetScale()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( not( WorldMapFrame:IsMaximized() ) ) then
        WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
    end
end

function jMap:MapsSetCVars()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    SetCVar('questLogOpen',Library:BoolToInt( not self:GetValue( 'PanelColapsed' ) ) );

    SetCVar( 'mapFade',Library:BoolToInt( self:GetValue( 'MapFade' ) ) );

    SetCVar( 'rotateMinimap',Library:BoolToInt( self:GetValue( 'MiniRotate' ) ) );
end

function jMap:HasMap()
    if( Library:IsVanilla() ) then
        local Instanced,InstanceType = IsInInstance();
        if( Instanced ) then
            return false;
        end
    end
    if( C_Housing and C_Housing.IsInsideHouse() ) then
        return false;
    end
    return true;
end

function jMap:MainMapFrameZoneChanged()
    if( ( Library:IsRetail() and InCombatLockdown() ) ) then
        return;
    end
    if( not self:GetValue( 'UpdateWorldMapFrameZone' ) ) then
        return;
    end
    local NewPosition = WorldMapFrame.mapID;
    local CurrentZone = C_Map.GetBestMapForUnit( 'player' );

    if( CurrentZone ) then
        WorldMapFrame:SetMapID( CurrentZone );
    end
    
    -- Map Show
    self:MainMapFrameCheckShown();
end

function jMap:Refresh()
    -- Map Scale
    self:MainMapFrameSetScale();

    -- Map Ping Pin
    self:MainMapFrameSetPingSize();

    -- Map Player Pin
    self:MainMapFrameSetPinTextures();

    -- Map Party Pin
    self:MainMapFrameSetPartyColors();

    -- Map Strata
    self:MainMapFrameSetStrata();
    
    -- Map Settings
    self:MapsSetCVars();

    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'Done' );
    end
end

function jMap:OnEnable()
    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'Prepping...please wait' );
    end
    WorldMapFrame:SetMovable( true );
    WorldMapFrame:RegisterForDrag( 'LeftButton' );

    -- Events
    self:RegisterEvent( 'ZONE_CHANGED_NEW_AREA','MainMapFrameZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED_INDOORS','MainMapFrameZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED','MainMapFrameZoneChanged' );
    self:RegisterEvent( 'PLAYER_REGEN_ENABLED','MainMapFrameCheckShown' );
    self:RegisterEvent( 'PLAYER_REGEN_DISABLED',function( Event )
        if( Event == 'PLAYER_REGEN_DISABLED' ) then
            if( WorldMapFrame:IsShown() ) then
                WorldMapFrame:Hide();
            end
        end
    end );

    -- Hooks
    self:SecureHook( WorldMapFrame,'SynchronizeDisplayState',function()
        -- Map Scale
        self:MainMapFrameSetScale();

        -- Map Position
        self:MainMapFrameSetPosition();

        -- Map Zone
        self:MainMapFrameZoneChanged();

        -- Map Emote
        self:MainMapFrameEmote();
    end );
    self:SecureHookScript( WorldMapFrame.ScrollContainer,'OnMouseWheel','MainMapFrameMouseWheel' );
    self:SecureHook( MainMapPlayerPin,'SynchronizePinSizes','MainMapFrameSetPingSize' );
    self:SecureHookScript( WorldMapFrame,'OnShow',function()
        -- Map Fade
        self:MainMapFrameFade();

        -- Map Ping
        self:MainMapFramePing();
    end );
    WorldMapFrame:HookScript( 'OnDragStart',self.MainMapFrameStartMoving );
    WorldMapFrame:HookScript( 'OnDragStop',self.MainMapFrameStopMoving );

    -- Map Refresh
    self:Refresh();

    -- Map Show
    self:MainMapFrameCheckShown();
end

function jMap:ConfigOpen( Input )
    if( not Input or Input:trim() == "" ) then

        if( InterfaceOptionsFrame_OpenToCategory ) then
            InterfaceOptionsFrame_OpenToCategory( self.CategoryID );
        else
            Settings.OpenToCategory( self.CategoryID );
        end
    else
        self:Print( 'Command:',Input );
    end
end

function jMap:OnInitialize()
    self:InitializeDB();
    self:InitializeConfig();
    self:RegisterChatCommand( 'jm','ConfigOpen' );
end