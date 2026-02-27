local _,Addon = ...;
local jMap = LibStub( 'AceAddon-3.0' ):NewAddon( 'jMap','AceEvent-3.0','AceHook-3.0','AceConsole-3.0' );

function jMap:SetValue( Index,Value )
    return self:SetDBValue( Index,Value );
end

function jMap:GetValue( Index )
    return self:GetDBValue( Index );
end

function jMap:WorldMapFrameSynchronizeDisplayState()
    if( self:GetValue( 'Debug' ) ) then
        Addon.FRAMES:Debug( 'WorldMapFrame','SynchronizeDisplayState' );
    end
    if( not( WorldMapFrame:IsMaximized() ) ) then
        self:WorldMapSetPosition();
    end

    if( WorldMapFrame:IsMaximized() ) then
        self:WorldMapFrameSetScale();
    end 
end

function jMap:WorldMapFrameSynchronizeSizes( Map )
    local scale = self.WorldMapUnitPin:GetMap():GetCanvasScale();
    for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
        if( Addon:IsClassic() and unit == 'player' ) then
            size = size+10;
            --self:SetFrameStrata( 'TOOLTIP' );
        end
        if self.dataProvider:ShouldShowUnit(unit) then
            self.WorldMapUnitPin:SetPinSize(unit, size / scale);
        end
    end
    self.WorldMapUnitPin:SetPlayerPingScale( self:GetValue( 'PinAnimScale' ) / scale);
end

function jMap:WorldMapFrameOnShow()
    local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
    if( PreviousZone ) then
        self.PreviousZone = PreviousZone;
    end
    self:WorldMapSetPosition();
    self:UpdateWorldMapFrameZone();
    local function OnUpdate( self,Elapsed )
        local FadeOut = not WorldMapFrame:IsMouseOver();
        local Setting = {
            MinAlpha = Addon.APP:GetValue( 'MapAlpha' ),
            MaxAlpha = 1,
            TimeToMax = .1,
        };
        WorldMapFrame:SetAlpha( DeltaLerp( WorldMapFrame:GetAlpha(),FadeOut and Setting.MinAlpha or Setting.MaxAlpha,Setting.TimeToMax,Elapsed ) );
    end
    FrameFaderDriver = CreateFrame( 'FRAME',nil,Map );
    FrameFaderDriver:HookScript( 'OnUpdate',OnUpdate );
    PlayerMovementFrameFader.RemoveFrame( WorldMapFrame );
end

function jMap:WorldMapFrameCheckShown()
    if( self:HasMap() ) then
        if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
            if( not self.WorldMapFrameClosed ) then
                WorldMapFrame:Show();
            end
        end
    else
        WorldMapFrame:Hide();
    end
end

function jMap:WorldMapFrameSetScale()
    WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
end

function jMap:WorldMapFrameOnMouseWheel( Value )
    if( not self:GetValue( 'ScrollScale' ) ) then
        return;
    end
    local CurrentValue = self:GetValue( SliderData.Name );
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
        self:SetValue( SliderData.Name,NewValue );
        self:WorldMapFrameSetScale();
    end
end

function jMap:WorldMapFrameStopMoving()
    WorldMapFrame:StopMovingOrSizing();
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
        if( MapXPos ~= nil and MapYPos ~= nil ) then
            self:SetValue( 'MapPoint',MapPoint );
            self:SetValue( 'MapRelativeTo',MapRelativeTo );
            self:SetValue( 'MapRelativePoint',MapRelativePoint );
            self:SetValue( 'MapXPos',MapXPos );
            self:SetValue( 'MapYPos',MapYPos );

            if( self:GetValue( 'Debug' ) ) then
                Addon:Dump( {
                    Action = 'Saving',
                    MapPoint = self:GetValue( 'MapPoint' ),
                    MapRelativeTo = self:GetValue( 'MapRelativeTo' ), 
                    MapRelativePoint = self:GetValue( 'MapRelativePoint' ), 
                    MapXPos = self:GetValue( 'MapXPos' ), 
                    MapYPos = self:GetValue( 'MapYPos' ), 
                } );

                Addon.FRAMES:Debug( 'WorldMapFrameStopMoving' );
            end
        end
    end
    WorldMapFrame:SetUserPlaced( true );
end

function jMap:WorldMapFrameStartMoving()
    if( not WorldMapFrame:IsMaximized() ) then
        WorldMapFrame:StartMoving();
    end
end

function jMap:WorldMapSetPosition()
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
        if( MapXPos ~= nil and MapYPos ~= nil ) then

            if( self:GetValue( 'Debug' ) ) then
                Addon:Dump( {
                    Action = 'Loading',
                    MapPoint = MapPoint,
                    MapRelativeTo = MapRelativeTo, 
                    MapRelativePoint = MapRelativePoint, 
                    MapXPos = MapXPos, 
                    MapYPos = MapYPos, 
                } );

                Addon.FRAMES:Debug( 'WorldMapSetPosition' );
            end
            
            WorldMapFrame:ClearAllPoints();
            WorldMapFrame:SetPoint( MapPoint,MapXPos,MapYPos );
            self:WorldMapFrameSetScale();
        end
    end
end

function jMap:SetCVars()
    SetCVar('questLogOpen',Addon:BoolToInt( not self:GetValue( 'PanelColapsed' ) ) );

    SetCVar( 'mapFade',Addon:BoolToInt( self:GetValue( 'MapFade' ) ) );

    SetCVar( 'rotateMinimap',Addon:BoolToInt( self:GetValue( 'MiniRotate' ) ) );
end

function jMap:WorldMapFrameUpdatePinColor()
    if( self:GetValue( 'Debug' ) ) then
        Addon.FRAMES:Debug( 'WorldMapFrameUpdatePinColor' );
    end

    local PinColor = self:GetValue( 'SkullMyAss' );
    if( PinColor == 'Pink' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
    elseif( PinColor == 'Blue' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Blue' );
    elseif( PinColor == 'Yellow' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64' );
    elseif( PinColor == 'Green' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Green' );
    elseif( PinColor == 'Grey' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64grey' );
    elseif( PinColor == 'Red' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Red' );
    elseif( PinColor == 'Normal' ) then
        self.WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\WorldMapArrow' );
    end
    local PingWidth,PingHeight = 75,75;

    if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
        self.WorldMapUnitPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
    end
    --self.WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
    --self.WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
    --self.WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
    --self.WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );

    if( self:GetValue( 'ClassColors' ) ) then
        self.WorldMapUnitPin:SetUseClassColor( 'party',true );
        self.WorldMapUnitPin:SetUseClassColor( 'raid',true );
    else
        self.WorldMapUnitPin:SetUseClassColor( 'party',false );
        self.WorldMapUnitPin:SetUseClassColor( 'raid',false );
    end
end

function jMap:WorldMapFramePing()
    if( self:GetValue( 'PinPing' ) ) then
        self.WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
    else
        self.WorldMapUnitPin:StartPlayerPing( 1,0 );
        self.WorldMapUnitPin:StopPlayerPing();
    end
end

function jMap:HasMap()
    if( Addon:IsVanilla() ) then
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

function jMap:UpdateWorldMapFrameZone()
    if( not self:GetValue( 'UpdateWorldMapFrameZone' ) ) then
        return;
    end
    local NewPosition = WorldMapFrame.mapID;
    local CurrentZone = C_Map.GetBestMapForUnit( 'player' );

    if( CurrentZone ) then
        WorldMapFrame:SetMapID( CurrentZone );
    end
    --WorldMapFrame:ResetZoom();
end

function jMap:OnZoneChanged()
    self:UpdateWorldMapFrameZone();
end

function jMap:OnCombatChanged( Event )
    if( Event  == 'PLAYER_REGEN_DISABLED' ) then
        WorldMapFrame:Hide();
        self.WorldMapFrameClosed = true;
    else
        self.WorldMapFrameClosed = false;
    end
end

function jMap:Refresh()
    if( not WorldMapFrame ) then
        return;
    end
    
    Addon.FRAMES:Notify( 'Refreshing all settings...' );

    -- Map Scale
    self:WorldMapFrameSetScale();

    -- Map Strata
    local DefaultStrata = WorldMapFrame:GetFrameStrata();
    if( self:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
        WorldMapFrame:SetFrameStrata( 'MEDIUM' );
    else
        WorldMapFrame:SetFrameStrata( DefaultStrata );
    end

    -- Map Show
    self:WorldMapFrameCheckShown();

    -- Map Zone
    self:UpdateWorldMapFrameZone();

    -- CVars
    self:SetCVars();

    -- Pin Size
    self.WorldMapUnitPin:WorldMapFrameSynchronizeSizes();

    -- Pin Color
    self:WorldMapFrameUpdatePinColor();

    -- Pin Ping
    self:WorldMapFramePing();

    -- Continuous
    if( self.Ticker ) then
        self.Ticker:Cancel();
    end
    self.Ticker = C_Timer.NewTicker( self:GetValue( 'PinPingSeconds' ),function()
        -- Map Show
        self:WorldMapFrameCheckShown();

        -- Continue Ping
        self:WorldMapFramePing();
    end );

    Addon.FRAMES:Notify( 'Done' );
end

function jMap:OnEnable()
    if( not WorldMapFrame ) then
        return;
    end
    WorldMapFrame:SetMovable( true );
    WorldMapFrame:RegisterForDrag( 'LeftButton' );

    -- Events
    self:RegisterEvent( 'ZONE_CHANGED_NEW_AREA','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED_INDOORS','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED','OnZoneChanged' );

    self:RegisterEvent( 'PLAYER_REGEN_DISABLED','OnCombatChanged' );
    self:RegisterEvent( 'PLAYER_REGEN_ENABLED','OnCombatChanged' );

    -- Pins
    self.WorldMapUnitPin = nil;
    for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
        self.WorldMapUnitPin = pin
        break;
    end

    -- Hooks
    self:SecureHook( WorldMapFrame,'SynchronizeDisplayState','WorldMapFrameSynchronizeDisplayState' );
    self:SecureHook( self.WorldMapUnitPin,'SynchronizePinSizes','WorldMapFrameSynchronizeSizes' );
    self:SecureHook( WorldMapFrame,'OnShow','WorldMapFrameOnShow' );
    self:SecureHook( self.WorldMapUnitPin,'OnAcquired',function()
        print( 'here' )
    end );

    hooksecurefunc( 'MoveForwardStart',function()
        self:UpdateWorldMapFrameZone();
    end );

    -- Position
    WorldMapFrame:HookScript( 'OnDragStart',self.WorldMapFrameStartMoving );
    WorldMapFrame:HookScript( 'OnDragStop',self.WorldMapFrameStopMoving );

    -- Scaling
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
    local RangeSlider = Addon.FRAMES:AddRange( SliderData,WorldMapFrame,{
        -- AddRange initialization calls this
        Get = function( Index )
            return self:GetValue( 'MapScale' );
        end,
        -- AddRange:OnValueChanged calls this
        Set = function( Index,Value )
            print( 'Set',Index,Value)
            --return self:SetValue( 'MapScale',Value );
        end,
    },Addon.Theme.Text.Colors.Default );

    -- Emotes
    if( C_ChatInfo and C_ChatInfo.PerformEmote ) then
        hooksecurefunc( C_ChatInfo,'PerformEmote',function( Emote )
            if( Emote == 'READ' and WorldMapFrame:IsShown() ) then
                if( self:GetValue( 'StopReading' ) ) then
                    C_ChatInfo.CancelEmote();
                end
            end
        end );
    else
        hooksecurefunc( 'DoEmote',function( Emote )
            if( Emote == 'READ' and WorldMapFrame:IsShown() ) then
                if( self:GetValue( 'StopReading' ) ) then
                    CancelEmote();
                end
            end
       end );
    end
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