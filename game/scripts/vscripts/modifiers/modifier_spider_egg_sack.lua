modifier_spider_egg_sack = class( ModifierBaseClass )

-------------------------------------------------------------------

function modifier_spider_egg_sack:IsHidden()
	return true
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:CheckState()
	local state =
	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = false,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
	return state
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:OnCreated( kv )
	if IsServer() then
		self.spider_min = self:GetAbility():GetSpecialValueFor( "spider_min" )
		self.spider_max = self:GetAbility():GetSpecialValueFor( "spider_max" )
		self.trigger_radius = self:GetAbility():GetSpecialValueFor( "trigger_radius" )
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
		self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
		self.egg_spider_lifetime = self:GetAbility():GetSpecialValueFor( "egg_spider_lifetime" )

		self.bBurst = false
		self.bTriggered = false
		self:StartIntervalThink( 0.25 )

	end
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:OnDeath( params )
	if IsServer() then
		if params.unit == self:GetParent() then
			self:Burst( nil )
		end
	end
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:OnIntervalThink()
	if IsServer() then
		if self.bTriggered == false then
			local enemies = FindUnitsInRadius( self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), self:GetParent(), self.trigger_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			if #enemies > 0 then
				self.bTriggered = true
				return
			end
		else
			self:Burst( nil )
			self:StartIntervalThink( -1 )
		end
	end
end

-------------------------------------------------------------------

function modifier_spider_egg_sack:Burst( hHero )
	if IsServer() then
		if self.bBurst == true then
			return
		end

		local hTarget = hHero
		if hHero == nil then
			hTarget = self:GetParent()
		end

		for i=0,RandomInt( self.spider_min, self.spider_max ) do
			local hUnit = CreateUnitByName( "npc_dota_creature_spider_small", self:GetParent():GetOrigin(), true, self:GetParent(), self:GetParent(), self:GetParent():GetTeamNumber() )
      hUnit:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = self.egg_spider_lifetime })
			if hUnit ~= nil and self:GetParent().zone ~= nil then
				self:GetParent().zone:AddEnemyToZone( hUnit )
			end
		end
		self.bBurst = true

		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.radius / 2, 0.4, self.radius ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		local enemies = FindUnitsInRadius( self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), self:GetParent(), self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
		for _,enemy in pairs ( enemies ) do
			if enemy ~= nil and enemy:IsInvulnerable() == false and enemy:IsMagicImmune() == false then
				--print( "Add modifier for " .. self.duration )
				enemy:AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_venomancer_poison_nova", { duration = self.duration } )
			end
		end

		EmitSoundOn( "Broodmother.LarvalParasite.Burst", self:GetParent() )
		EmitSoundOn( "EggSack.Burst", self:GetParent() )
		self:GetParent():AddEffects( EF_NODRAW )
		self:GetParent():ForceKill( false )
	end
end

