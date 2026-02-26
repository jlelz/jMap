local _, Addon = ...;

Addon.APP = CreateFrame( 'Frame' );
Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jMap' ) then
        local WorldMapUnitPin;

        --
        --  Set value
        --
        --  @param  string  Index
        --  @param  mixed   Value
        --  @return bool
        Addon.APP.SetValue = function( self,Index,Value )
            return Addon.DB:SetValue( Index,Value );
        end

        --
        --  Get value
        --
        --  @return mixed
        Addon.APP.GetValue = function( self,Index )
            return Addon.DB:GetValue( Index );
        end

        --
        --  Create module config frames
        --
        --  @return void
        Addon.APP.CreateFrames = function( self )
            self.Events = CreateFrame( 'Frame' );
            self.Events:RegisterEvent( 'ZONE_CHANGED_NEW_AREA' );
            self.Events:RegisterEvent( 'ZONE_CHANGED' );
            self.Events:RegisterEvent( 'ZONE_CHANGED_INDOORS' );
            self.Events:HookScript( 'OnEvent',function( self,Event,... )
                if( not Event ) then
                    return;
                end
                Addon.APP:UpdateWorldMapFrameZone();
            end );

            -- Display
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapFrame,'SynchronizeDisplayState',function()
                if( not( WorldMapFrame:IsMaximized() ) ) then
                    self:WorldMapSetPosition();
                end

                if( WorldMapFrame:IsMaximized() ) then
                    self:WorldMapFrameSetScale();
                end 

                if( self:GetValue( 'Debug' ) ) then
                    Addon.FRAMES:Debug( 'WorldMapFrame','SynchronizeDisplayState' );
                end
            end );

            -- Show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map )
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
                self:WorldMapSetPosition();
                self:UpdateWorldMapFrameZone();

                local function OnUpdate( self,Elapsed )
                    local FadeOut = not Map:IsMouseOver();
                    local Setting = {
                        MinAlpha = Addon.APP:GetValue( 'MapAlpha' ),
                        MaxAlpha = 1,
                        TimeToMax = .1,
                    };
                    Map:SetAlpha( DeltaLerp( Map:GetAlpha(),FadeOut and Setting.MinAlpha or Setting.MaxAlpha,Setting.TimeToMax,Elapsed ) );
                end
                FrameFaderDriver = CreateFrame( 'FRAME',nil,Map );
                FrameFaderDriver:HookScript( 'OnUpdate',OnUpdate );
                PlayerMovementFrameFader.RemoveFrame( WorldMapFrame );
            end );

            --[[
            if( not WorldMapFrame.NavBar ) then
                WorldMapFrame.Nav = CreateFrame( 'Frame',AddonName..'Nav',WorldMapFrame.ScrollContainer.Child );
                WorldMapFrame.Nav:SetSize( WorldMapFrame.ScrollContainer.Child:GetWidth(),60 );
                WorldMapFrame.Nav:SetPoint( 'topleft',WorldMapFrame.ScrollContainer.Child,'topleft',0,0 );

                local BGTheme = Addon.Theme.Background;
                local r,g,b,a = BGTheme.r,BGTheme.g,BGTheme.b,0.9;

                WorldMapFrame.Nav.Texture = WorldMapFrame.Nav:CreateTexture();
                WorldMapFrame.Nav.Texture:SetAllPoints( WorldMapFrame.Nav );
                WorldMapFrame.Nav.Texture:SetColorTexture( r,g,b,a );
            end
            ]]

            -- Zooming/Scaling
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
            -- Cause map zooming to control the slider
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame.ScrollContainer,'OnMouseWheel',function( self,Value )
                if( not Addon.APP:GetValue( 'ScrollScale' ) ) then
                    return;
                end
                local CurrentValue = Addon.APP:GetValue( SliderData.Name );
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
                    Addon.APP:SetValue( SliderData.Name,NewValue );
                    Addon.APP:WorldMapFrameSetScale();
                end
            end );

            --WorldMapUnitPin:SetFrameStrata( 'TOOLTIP' );
            
            -- Interface/AddOns/Blizzard_SharedMapDataProviders/GroupMembersDataProvider.lua
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function( self )
                local scale = self:GetMap():GetCanvasScale();
                for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
                    if( Addon:IsClassic() and unit == 'player' ) then
                        size = size+10;
                        --self:SetFrameStrata( 'TOOLTIP' );
                    end
                    if self.dataProvider:ShouldShowUnit(unit) then
                        self:SetPinSize(unit, size / scale);
                    end
                end
                self:SetPlayerPingScale( Addon.APP:GetValue( 'PinAnimScale' ) / scale);
            end );
        end

        --
        --  Map stop moving
        --
        --  @return void
        Addon.APP.WorldMapFrameStopMoving = function( self )
            WorldMapFrame:StopMovingOrSizing();
            if( not( WorldMapFrame:IsMaximized() ) ) then
                local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
                if( MapXPos ~= nil and MapYPos ~= nil ) then
                    Addon.APP:SetValue( 'MapPoint',MapPoint );
                    Addon.APP:SetValue( 'MapRelativeTo',MapRelativeTo );
                    Addon.APP:SetValue( 'MapRelativePoint',MapRelativePoint );
                    Addon.APP:SetValue( 'MapXPos',MapXPos );
                    Addon.APP:SetValue( 'MapYPos',MapYPos );

                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        Addon:Dump( {
                            Action = 'Saving',
                            MapPoint = Addon.APP:GetValue( 'MapPoint' ),
                            MapRelativeTo = Addon.APP:GetValue( 'MapRelativeTo' ), 
                            MapRelativePoint = Addon.APP:GetValue( 'MapRelativePoint' ), 
                            MapXPos = Addon.APP:GetValue( 'MapXPos' ), 
                            MapYPos = Addon.APP:GetValue( 'MapYPos' ), 
                        } );

                        Addon.FRAMES:Debug( 'Addon.APP','WorldMapFrameStopMoving' );
                    end
                end
            end
            WorldMapFrame:SetUserPlaced( true );
        end

        --
        --  Map start moving
        --
        --  @return void
        Addon.APP.WorldMapFrameStartMoving = function( self )
            if( not WorldMapFrame:IsMaximized() ) then
                WorldMapFrame:StartMoving();
            end
        end

        Addon.APP.WorldMapFrameCheckShown = function( self )
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

        --
        --  Map save position
        --
        --  @return void
        Addon.APP.WorldMapSetPosition = function( self )
            if( not( WorldMapFrame:IsMaximized() ) ) then
                local MapPoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
                if( MapXPos ~= nil and MapYPos ~= nil ) then

                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        Addon:Dump( {
                            Action = 'Loading',
                            MapPoint = MapPoint,
                            MapRelativeTo = MapRelativeTo, 
                            MapRelativePoint = MapRelativePoint, 
                            MapXPos = MapXPos, 
                            MapYPos = MapYPos, 
                        } );

                        Addon.FRAMES:Debug( 'Addon.APP','WorldMapSetPosition' );
                    end
                    
                    WorldMapFrame:ClearAllPoints();
                    WorldMapFrame:SetPoint( MapPoint,MapXPos,MapYPos );
                    self:WorldMapFrameSetScale();
                end
            end
        end

        Addon.APP.SetCVars = function( self )
            SetCVar('questLogOpen',Addon:BoolToInt( not self:GetValue( 'PanelColapsed' ) ) );

            SetCVar( 'mapFade',Addon:BoolToInt( self:GetValue( 'MapFade' ) ) );

            SetCVar( 'rotateMinimap',Addon:BoolToInt( self:GetValue( 'MiniRotate' ) ) );
        end

        --
        --  Map save scale
        --
        --  @return void
        Addon.APP.WorldMapFrameSetScale = function( self )
            WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
        end

        --
        -- Update Map Unit Pin Colors
        --
        -- @return  mixed
        Addon.APP.UpdateWorldMapFramePinColors = function( self )
            if( Addon.APP:GetValue( 'Debug' ) ) then
                Addon.FRAMES:Debug( 'UpdateWorldMapFramePinColors call' );
            end

            local PinColor = self:GetValue( 'SkullMyAss' );
            if( PinColor == 'Pink' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
            elseif( PinColor == 'Blue' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Blue' );
            elseif( PinColor == 'Yellow' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64' );
            elseif( PinColor == 'Green' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Green' );
            elseif( PinColor == 'Grey' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64grey' );
            elseif( PinColor == 'Red' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Red' );
            elseif( PinColor == 'Normal' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\WorldMapArrow' );
            end
            local PingWidth,PingHeight = 75,75;

            if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
                WorldMapUnitPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
            end
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
            --WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );

            if( Addon.APP:GetValue( 'ClassColors' ) ) then
                WorldMapUnitPin:SetUseClassColor( 'party',true );
                WorldMapUnitPin:SetUseClassColor( 'raid',true );
            else
                WorldMapUnitPin:SetUseClassColor( 'party',false );
                WorldMapUnitPin:SetUseClassColor( 'raid',false );
            end
        end

        --
        -- Animate Map Unit Pin
        --
        -- @return  void
        Addon.APP.WorldMapFramePing = function( self )
            if( Addon.APP:GetValue( 'PinPing' ) ) then
                WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
            else
                WorldMapUnitPin:StartPlayerPing( 1,0 );
                WorldMapUnitPin:StopPlayerPing();
            end
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.APP.UpdateWorldMapFrameZone = function( self )
            if( not Addon.APP:GetValue( 'UpdateWorldMapFrameZone' ) ) then
                return;
            end
            -- Verify
            if( not WorldMapFrame ) then
                return;
            end
            local NewPosition = WorldMapFrame.mapID;
            local CurrentZone = C_Map.GetBestMapForUnit( 'player' );

            if( CurrentZone ) then
                WorldMapFrame:SetMapID( CurrentZone );
            end

            --WorldMapFrame:ResetZoom();
        end

        Addon.APP.HasMap = function( self )
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

        --
        --  Module refresh
        --
        --  @return void
        Addon.APP.Refresh = function( self )
            if( not WorldMapFrame ) then
                return;
            end
            
            Addon.FRAMES:Notify( 'Refreshing all settings...' );

            -- Map Scale
            self:WorldMapFrameSetScale();

            -- Map Strata
            local DefaultStrata = WorldMapFrame:GetFrameStrata();
            if( Addon.APP:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
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

            -- Player Pin
            if( not WorldMapUnitPin ) then
                return;
            end

            -- Pin Size
            WorldMapUnitPin:SynchronizePinSizes();

            -- Pin Color
            self:UpdateWorldMapFramePinColors();

            -- Pin Ping
            self:WorldMapFramePing();

            -- Continuous
            if( self.Ticker ) then
                self.Ticker:Cancel();
            end
            self.Ticker = C_Timer.NewTicker( Addon.APP:GetValue( 'PinPingSeconds' ),function()
                -- Map Show
                self:WorldMapFrameCheckShown();

                -- Continue Ping
                self:WorldMapFramePing();
            end );

            Addon.FRAMES:Notify( 'Done' );
        end

        --
        --  Module init
        --
        --  @return void
        Addon.APP.Init = function( self )
            if( not WorldMapFrame ) then
                return;
            end

            -- Position
            WorldMapFrame:SetMovable( true );
            WorldMapFrame:RegisterForDrag( 'LeftButton' );
            WorldMapFrame:HookScript( 'OnDragStart',self.WorldMapFrameStartMoving );
            WorldMapFrame:HookScript( 'OnDragStop',self.WorldMapFrameStopMoving );

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

            hooksecurefunc( 'MoveForwardStart',function()
                self:UpdateWorldMapFrameZone();
            end );

            -- Pins
            for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
                WorldMapUnitPin = pin
                break;
            end
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'OnAcquired',function()
                print( 'here' )
            end );

            local FuckBlizzTaints = CreateFrame( 'Frame' );
            FuckBlizzTaints:RegisterEvent( 'PLAYER_REGEN_DISABLED' );
            FuckBlizzTaints:RegisterEvent( 'PLAYER_REGEN_ENABLED' );
            FuckBlizzTaints:SetScript( 'OnEvent',function( _,Event )
                if( Event  == 'PLAYER_REGEN_DISABLED' ) then
                    WorldMapFrame:Hide();
                    self.WorldMapFrameClosed = true;
                else
                    self.WorldMapFrameClosed = false;
                end
            end );
        end

        Addon.DB:Init();
        Addon.CONFIG:Init();

        self:Init();
        self:CreateFrames();
        self:Refresh();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );