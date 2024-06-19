local addonName = "Dynamic Light Controller - Entities"
local IsValid, GetClass
do
	local _obj_0 = FindMetaTable("Entity")
	IsValid, GetClass = _obj_0.IsValid, _obj_0.GetClass
end
local PRE_HOOK = PRE_HOOK or HOOK_MONITOR_HIGH
local CreateClientConVar = CreateClientConVar
local entities = list.GetForEdit(addonName)
local CreateClientside = ents.CreateClientside
local TraceLine = util.TraceLine
local Simple = timer.Simple
local Add = hook.Add
local traceResult = { }
local trace = {
	output = traceResult
}
local blacklist = { }
do
	local fileName = "dlight_controller_entities_blacklist.json"
	if not file.Exists(fileName, "DATA") then
		file.Write(fileName, util.TableToJSON({
			"example_entity_class1",
			"example_entity_class2"
		}, true))
	end
	file.AsyncRead(fileName, "DATA", function(_, __, status, data)
		if status ~= FSASYNC_OK then
			return
		end
		local tbl = util.JSONToTable(data)
		if tbl == nil then
			return
		end
		for _index_0 = 1, #tbl do
			local className = tbl[_index_0]
			blacklist[className] = true
		end
	end)
end
do
	local dlight_controllers_entities = CreateClientConVar("dlight_controllers_entities", "1", true, false, "Enables creation dynamic light emitters for game entities.", 0, 1)
	local isfunction = isfunction
	Add("NotifyShouldTransmit", addonName, function(entity, shouldtransmit)
		if shouldtransmit and dlight_controllers_entities:GetBool() and not entity.DLightController then
			local dlight = entity.__dlight
			if dlight and IsValid(dlight) then
				return
			end
			local className = GetClass(entity)
			if blacklist[className] then
				return
			end
			local func = entities[className]
			if not (func and isfunction(func)) then
				return
			end
			dlight = CreateClientside("dlight_controller")
			if not (dlight and IsValid(dlight)) then
				return
			end
			dlight:SetEnabled(true)
			if func(entity, dlight) == false then
				dlight:Remove()
				return
			end
			entity.__dlight = dlight
			dlight:Spawn()
			return
		end
		local dlight = entity.__dlight
		if dlight and IsValid(dlight) then
			return dlight:Remove()
		end
	end, PRE_HOOK)
	Add("OnEntityCreated", addonName, function(entity)
		if not dlight_controllers_entities:GetBool() or entity.DLightController then
			return
		end
		local dlight = entity.__dlight
		if dlight and IsValid(dlight) then
			return
		end
		local className = GetClass(entity)
		if blacklist[className] then
			return
		end
		local func = entities[className]
		if not (func and isfunction(func)) then
			return
		end
		dlight = CreateClientside("dlight_controller")
		if not (dlight and IsValid(dlight)) then
			return
		end
		dlight:SetEnabled(true)
		if func(entity, dlight) == false then
			dlight:Remove()
			return
		end
		entity.__dlight = dlight
		dlight:Spawn()
		return
	end, PRE_HOOK)
	Add("PlayerSwitchWeapon", addonName, function(_, old, new)
		local dlight = old.__beam_dlight
		if dlight and IsValid(dlight) then
			dlight:Remove()
		end
		dlight = old.__dlight
		if dlight and IsValid(dlight) then
			dlight:Remove()
		end
		dlight = new.__dlight
		if dlight and IsValid(dlight) then
			dlight:Remove()
		end
		if not (dlight_controllers_entities:GetBool() and IsValid(new)) then
			return
		end
		local className = GetClass(new)
		if blacklist[className] then
			return
		end
		local func = entities[className]
		if not (func and isfunction(func)) then
			return
		end
		dlight = CreateClientside("dlight_controller")
		if not (dlight and IsValid(dlight)) then
			return
		end
		dlight:SetEnabled(true)
		if func(new, dlight) == false then
			dlight:Remove()
			return
		end
		new.__dlight = dlight
		dlight:Spawn()
		return
	end, PRE_HOOK)
end
Add("EntityRemoved", addonName, function(entity, fullUpdate)
	local dlight = entity.__dlight
	if dlight then
		if IsValid(dlight) then
			dlight:Remove()
		end
		entity.__dlight = nil
	end
	dlight = entity.m_eFireDLight
	if dlight then
		if IsValid(dlight) then
			dlight:Remove()
		end
		entity.m_eFireDLight = nil
	end
	dlight = entity.__beam_dlight
	if dlight then
		if IsValid(dlight) then
			dlight:Remove()
		end
		entity.__beam_dlight = nil
	end
end, PRE_HOOK)
do
	local physgun_maxrange = GetConVar("physgun_maxrange")
	Add("DrawPhysgunBeam", addonName .. " - Physgun", function(ply, wep, enabled, entity, physBone, localPos)
		local bdlight = wep.__beam_dlight
		if not (bdlight and IsValid(bdlight)) then
			return
		end
		bdlight:SetEnabled(enabled)
		if not enabled then
			return
		end
		bdlight:SetLightColor(ply:GetWeaponColor())
		if not IsValid(entity) then
			trace.start = ply:GetShootPos()
			trace.endpos = trace.start + ply:GetAimVector() * physgun_maxrange:GetInt()
			trace.filter = ply
			TraceLine(trace)
			bdlight:SetPos(traceResult.HitPos + traceResult.HitNormal)
			return
		end
		if physBone ~= 0 then
			local matrix = entity:GetBoneMatrix(entity:TranslatePhysBoneToBone(physBone))
			if matrix then
				bdlight:SetPos(LocalToWorld(localPos, angle_zero, matrix:GetTranslation(), matrix:GetAngles()))
				return
			end
		end
		bdlight:SetPos(entity:LocalToWorld(localPos))
		return
	end)
end
do
	local dlight_controllers_env_fire = CreateClientConVar("dlight_controllers_env_fire", "0", true, false, "Enables creation dynamic light emitters for env_fire.", 0, 1)
	entities["env_fire"] = function(entity, dlight)
		if not dlight_controllers_env_fire:GetBool() then
			return false
		end
		dlight:SetSprite("sprites/gmdm_pickups/light")
		dlight:SetLightColor(255, 100, 0)
		dlight:SetSpriteAlpha(255)
		dlight:SetSpriteScale(0.5)
		dlight:SetBrightness(1)
		dlight:SetRadius(256)
		dlight:SetStyle(5)
		dlight.LightThink = function()
			if IsValid(entity) then
				return dlight:SetPos(entity:GetPos())
			end
		end
		return true
	end
end
do
	local offset = Vector(3, 0, 6)
	entities["item_battery"] = function(entity, dlight)
		dlight:SetRadius(32)
		dlight:SetParent(entity)
		dlight:SetBrightness(0.5)
		dlight:SetSpriteAlpha(5)
		dlight:SetLightColor(0, 255, 255)
		dlight:SetLocalPos(offset)
		dlight:SetSprite("sprites/gmdm_pickups/light")
		return true
	end
end
do
	local offset = Vector(-10, 0, 0)
	entities["hunter_flechette"] = function(entity, dlight)
		dlight:SetRadius(48)
		dlight:SetParent(entity)
		dlight:SetBrightness(0.5)
		dlight:SetLightColor(0, 255, 255)
		dlight:SetLocalPos(offset)
		return true
	end
end
do
	local offset = Vector(4, 4, 4)
	entities["item_healthkit"] = function(entity, dlight)
		dlight:SetRadius(48)
		dlight:SetParent(entity)
		dlight:SetSpriteAlpha(15)
		dlight:SetBrightness(0.25)
		dlight:SetLightColor(60, 255, 0)
		dlight:SetLocalPos(offset)
		dlight:SetSprite("sprites/gmdm_pickups/light")
		return true
	end
end
entities["item_healthvial"] = function(entity, dlight)
	dlight:SetRadius(32)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetSpriteAlpha(25)
	dlight:SetLightColor(60, 255, 0)
	dlight:SetLocalPos(entity:OBBCenter())
	dlight:SetSprite("sprites/gmdm_pickups/light")
	return true
end
entities["item_ammo_ar2"] = function(entity, dlight)
	dlight:SetRadius(32)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetLightColor(0, 255, 255)
	dlight:SetLocalPos(entity:OBBCenter())
	return true
end
entities["item_ammo_ar2_large"] = function(entity, dlight)
	dlight:SetRadius(32)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetLightColor(0, 255, 255)
	dlight:SetLocalPos(entity:OBBCenter())
	return true
end
entities["npc_rollermine"] = function(entity, dlight)
	dlight:SetRadius(32)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetLightColor(0, 255, 255)
	dlight:SetLocalPos(entity:OBBCenter())
	return true
end
entities["weapon_striderbuster"] = function(entity, dlight)
	dlight:SetStyle(12)
	dlight:SetRadius(48)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.25)
	dlight:SetSpriteAlpha(100)
	dlight:SetLightColor(0, 255, 255)
	dlight:SetLocalPos(entity:OBBCenter())
	dlight:SetSprite("sprites/gmdm_pickups/light")
	return true
end
entities["grenade_helicopter"] = function(entity, dlight)
	dlight:SetRadius(64)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetSpriteAlpha(100)
	dlight:SetLightColor(255, 0, 0)
	dlight:SetLocalPos(entity:OBBCenter())
	dlight:SetSprite("sprites/gmdm_pickups/light")
	return true
end
entities["env_rockettrail"] = function(entity, dlight)
	dlight:SetRadius(256)
	dlight:SetBrightness(2)
	dlight:SetParent(entity)
	dlight:SetLightColor(255, 100, 0)
	dlight:SetLocalPos(entity:OBBCenter())
	return true
end
entities["item_ammo_ar2_altfire"] = function(entity, dlight)
	dlight:SetStyle(5)
	dlight:SetRadius(32)
	dlight:SetParent(entity)
	dlight:SetBrightness(0.5)
	dlight:SetSpriteAlpha(50)
	dlight:SetLightColor(255, 200, 0)
	dlight:SetLocalPos(entity:OBBCenter())
	dlight:SetSprite("sprites/gmdm_pickups/light")
	return true
end
entities["prop_combine_ball"] = function(entity, dlight)
	dlight:SetStyle(5)
	dlight:SetRadius(512)
	dlight:SetParent(entity)
	dlight:SetBrightness(2)
	dlight:SetSpriteScale(0.15)
	dlight:SetLightColor(255, 240, 150)
	dlight:SetLocalPos(entity:OBBCenter())
	dlight:SetSprite("sprites/gmdm_pickups/light")
	return true
end
do
	local ceil = math.ceil
	entities["sent_ball"] = function(entity, dlight)
		dlight:SetRadius(32)
		dlight:SetBrightness(2)
		dlight:SetParent(entity)
		dlight:SetLocalPos(entity:OBBCenter())
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			dlight:SetRadius(ceil(entity:GetBallSize() * 1.5))
			return dlight:SetLightColor(entity:GetBallColor())
		end
		return true
	end
end
entities["env_sprite"] = function(entity, dlight)
	local parent = entity:GetParent()
	if not (parent and IsValid(parent)) then
		return false
	end
	local old = parent.__dlight
	if old and IsValid(old) then
		old:Remove()
	end
	parent.__dlight = dlight
	dlight:SetParent(entity)
	local offset = entity:OBBCenter()
	local className = GetClass(parent)
	if blacklist[className] then
		return false
	end
	if className == "crossbow_bolt" then
		dlight:SetLightColor(255, 100, 0)
		dlight:SetBrightness(0.25)
		dlight:SetRadius(32)
	elseif className == "combine_mine" then
		dlight:SetLightColor(entity:GetColor())
		dlight:SetBrightness(1)
		dlight:SetRadius(32)
		local _update_0 = 3
		offset[_update_0] = offset[_update_0] + 2
	elseif className == "npc_grenade_frag" then
		dlight:SetLightColor(255, 0, 0)
		dlight:SetBrightness(1)
		dlight:SetRadius(32)
	elseif className == "npc_manhack" then
		dlight:SetLightColor(255, 0, 0)
		dlight:SetBrightness(0.25)
		dlight:SetRadius(48)
	elseif className == "npc_cscanner" then
		dlight:SetLightColor(255, 255, 255)
		dlight:SetBrightness(0.5)
		dlight:SetRadius(64)
	elseif className == "npc_satchel" then
		dlight:SetSprite("sprites/gmdm_pickups/light")
		dlight:SetLightColor(255, 0, 0)
		dlight:SetSpriteAlpha(50)
		dlight:SetBrightness(0.5)
		dlight:SetRadius(32)
	else
		dlight:SetLightColor(entity:GetColor())
		dlight:SetBrightness(1)
		dlight:SetRadius(32)
	end
	dlight:SetLocalPos(offset)
	return true
end
do
	local dlight_controllers_bullets = CreateClientConVar("dlight_controllers_bullets", "1", true, false, "Enables creation of dynamic light emitters when entities fire bullets.", 0, 1)
	local dlight_controllers_bullets_brightness = CreateClientConVar("dlight_controllers_bullets_brightness", "0.1", true, false, "", 0, 10)
	local dlight_controllers_bullets_lifetime = CreateClientConVar("dlight_controllers_bullets_lifetime", "0.2", true, false, "", 0, 5)
	local dlight_controllers_bullets_radius = CreateClientConVar("dlight_controllers_bullets_radius", "64", true, false, "", 16, 4096)
	local dlight_controllers_bullets_color = CreateClientConVar("dlight_controllers_bullets_color", "255 100 0", true, false, "")
	local r, g, b = unpack(string.Split(dlight_controllers_bullets_color:GetString(), " "), nil)
	cvars.AddChangeCallback(dlight_controllers_bullets_color:GetName(), function(_, __, value)
		r, g, b = unpack(string.Split(value, " "), nil)
	end, addonName)
	Add("EntityFireBullets", addonName, function(self, data)
		if not dlight_controllers_bullets:GetBool() then
			return
		end
		Simple(0, function()
			trace.start = data.Src
			trace.endpos = data.Src + data.Dir * data.Distance
			trace.filter = data.Entity
			TraceLine(trace)
			local dlight = CreateClientside("dlight_controller")
			if not (dlight and IsValid(dlight)) then
				return
			end
			dlight:SetLifetime(dlight_controllers_bullets_lifetime:GetFloat())
			dlight:SetPos(traceResult.HitPos + traceResult.HitNormal * 2)
			dlight:SetLightColor(r or 255, g or 100, b or 0)
			dlight:SetParent(traceResult.Entity)
			dlight:SetBrightness(0.1)
			dlight:SetEnabled(true)
			dlight:SetRadius(16)
			dlight:Spawn()
			return
		end)
		local dlight = CreateClientside("dlight_controller")
		if not (dlight and IsValid(dlight)) then
			return
		end
		dlight:SetBrightness(dlight_controllers_bullets_brightness:GetFloat())
		dlight:SetLifetime(dlight_controllers_bullets_lifetime:GetFloat())
		dlight:SetRadius(dlight_controllers_bullets_radius:GetInt())
		dlight:SetLightColor(r or 255, g or 100, b or 0)
		dlight:SetEnabled(true)
		dlight:SetPos(data.Src)
		dlight:SetParent(self)
		dlight:Spawn()
		return
	end, PRE_HOOK)
end
do
	local Iterator = ents.Iterator
	hook.Add("Think", addonName, function()
		for _, entity in Iterator() do
			if not IsValid(entity) then
				return
			end
			if entity:IsOnFire() then
				local dlight = entity.m_eFireDLight
				if dlight and IsValid(dlight) then
					goto _continue_0
				end
				dlight = CreateClientside("dlight_controller")
				if not (dlight and IsValid(dlight)) then
					return
				end
				entity.m_eFireDLight = dlight
				dlight:SetStyle(5)
				dlight:SetRadius(128)
				dlight:SetBrightness(0.5)
				dlight:SetEnabled(true)
				dlight:SetParent(entity)
				dlight:SetLightColor(255, 100, 0)
				dlight:SetLocalPos(entity:OBBCenter())
				dlight:Spawn()
				goto _continue_0
			end
			local dlight = entity.m_eFireDLight
			if dlight then
				if IsValid(dlight) then
					dlight:Remove()
				end
				dlight.m_eFireDLight = nil
			end
			::_continue_0::
		end
	end)
end
do
	local dlight_controllers_explosions = CreateClientConVar("dlight_controllers_explosions", "1", true, false, "Enables creation of dynamic light emitters when something explode.", 0, 1)
	local dlight_controllers_explosions_brightness = CreateClientConVar("dlight_controllers_explosions_brightness", "2", true, false, "", 0, 10)
	local dlight_controllers_explosions_lifetime = CreateClientConVar("dlight_controllers_explosions_lifetime", "0.2", true, false, "", 0, 5)
	local dlight_controllers_explosions_radius = CreateClientConVar("dlight_controllers_explosions_radius", "512", true, false, "", 16, 4096)
	local dlight_controllers_explosions_color = CreateClientConVar("dlight_controllers_explosions_color", "255 100 0", true, false, "")
	local r, g, b = unpack(string.Split(dlight_controllers_explosions_color:GetString(), " "))
	cvars.AddChangeCallback(dlight_controllers_explosions_color:GetName(), function(_, __, value)
		r, g, b = unpack(string.Split(value, " "))
	end, addonName)
	Add("EntityEmitSound", addonName, function(data)
		if not (data.OriginalSoundName == "BaseExplosionEffect.Sound" and dlight_controllers_explosions:GetBool()) then
			return
		end
		local dlight = CreateClientside("dlight_controller")
		if not (dlight and IsValid(dlight)) then
			return
		end
		dlight:SetBrightness(dlight_controllers_explosions_brightness:GetFloat())
		dlight:SetLifetime(dlight_controllers_explosions_lifetime:GetFloat())
		dlight:SetRadius(dlight_controllers_explosions_radius:GetInt())
		dlight:SetLightColor(r, g, b)
		dlight:SetPos(data.Pos)
		dlight:SetEnabled(true)
		dlight:Spawn()
		return
	end, PRE_HOOK)
end
do
	local offset = Vector(16, -3, 5)
	local LocalToWorld = LocalToWorld
	local angle_zero = angle_zero
	local attachmentID = 0
	entities["weapon_physgun"] = function(entity, dlight)
		local bdlight = CreateClientside("dlight_controller")
		entity.__beam_dlight = bdlight
		bdlight:SetBrightness(0.01)
		bdlight:SetRadius(128)
		bdlight:SetStyle(5)
		bdlight:Spawn()
		dlight:SetLightColor(Vector(cvars.String("cl_weaponcolor")))
		dlight:SetBrightness(0.5)
		dlight:SetRadius(64)
		dlight:SetStyle(5)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			local owner = entity:GetOwner()
			if not (owner and IsValid(owner) and owner:IsPlayer()) then
				dlight:SetPos(entity:WorldSpaceCenter())
				dlight:SetEnabled(true)
				return
			end
			dlight:SetEnabled(owner:GetActiveWeapon() == entity)
			dlight:SetLightColor(owner:GetWeaponColor())
			attachmentID = owner:LookupAttachment("anim_attachment_RH")
			if attachmentID > 0 then
				local attachment = owner:GetAttachment(attachmentID)
				return dlight:SetPos(LocalToWorld(offset, angle_zero, attachment.Pos, attachment.Ang))
			else
				return dlight:SetPos(owner:GetShootPos())
			end
		end
		return true
	end
	entities["weapon_physcannon"] = function(entity, dlight)
		dlight:SetLightColor(255, 200, 0)
		dlight:SetBrightness(0.5)
		dlight:SetRadius(64)
		dlight:SetStyle(5)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			local owner = entity:GetOwner()
			if not (owner and IsValid(owner) and owner:IsPlayer()) then
				dlight:SetPos(entity:WorldSpaceCenter())
				dlight:SetEnabled(true)
				return
			end
			dlight:SetEnabled(owner:GetActiveWeapon() == entity)
			attachmentID = owner:LookupAttachment("anim_attachment_RH")
			if attachmentID > 0 then
				local attachment = owner:GetAttachment(attachmentID)
				return dlight:SetPos(LocalToWorld(offset, angle_zero, attachment.Pos, attachment.Ang))
			else
				return dlight:SetPos(owner:GetShootPos())
			end
		end
		return true
	end
	entities["weapon_crossbow"] = function(entity, dlight)
		dlight:SetLightColor(255, 200, 0)
		dlight:SetBrightness(0.5)
		dlight:SetRadius(32)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			local owner = entity:GetOwner()
			if not (owner and IsValid(owner) and owner:IsPlayer()) then
				dlight:SetPos(entity:WorldSpaceCenter())
				dlight:SetEnabled(true)
				return
			end
			dlight:SetEnabled(owner:GetActiveWeapon() == entity)
			attachmentID = owner:LookupAttachment("anim_attachment_RH")
			if attachmentID > 0 then
				local attachment = owner:GetAttachment(attachmentID)
				dlight:SetPos(LocalToWorld(offset, angle_zero, attachment.Pos, attachment.Ang))
			else
				dlight:SetPos(owner:GetShootPos())
			end
			local r, g = dlight:GetRed(), dlight:GetGreen()
			if entity:Clip1() == 0 then
				if r ~= 0 then
					dlight:SetRed(0)
				end
				if g ~= 0 then
					dlight:SetGreen(0)
				end
				return
			end
			if r ~= 255 then
				dlight:SetRed(255)
			end
			if g ~= 200 then
				return dlight:SetGreen(200)
			end
		end
		return true
	end
	entities["weapon_medkit"] = function(entity, dlight)
		dlight:SetLightColor(60, 255, 0)
		dlight:SetBrightness(1)
		dlight:SetRadius(48)
		dlight:SetStyle(5)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			local owner = entity:GetOwner()
			if not (owner and IsValid(owner) and owner:IsPlayer()) then
				dlight:SetPos(entity:WorldSpaceCenter())
				dlight:SetEnabled(true)
				return
			end
			dlight:SetEnabled(owner:GetActiveWeapon() == entity)
			attachmentID = owner:LookupAttachment("anim_attachment_RH")
			if attachmentID > 0 then
				local attachment = owner:GetAttachment(attachmentID)
				dlight:SetPos(LocalToWorld(offset, angle_zero, attachment.Pos, attachment.Ang))
			else
				dlight:SetPos(owner:GetShootPos())
			end
			local fraction = entity:Clip1() / entity:GetMaxClip1()
			dlight:SetRed(Lerp(fraction, 0, 60))
			return dlight:SetGreen(Lerp(fraction, 0, 255))
		end
		return true
	end
end
do
	local offset1 = Vector(8, -3, 6)
	local offset2 = Vector(8, -2, 2)
	local frac = 0
	entities["item_suitcharger"] = function(entity, dlight)
		dlight:SetRadius(32)
		dlight:SetParent(entity)
		dlight:SetBrightness(0.5)
		dlight:SetLightColor(255, 200, 0)
		dlight:SetLocalPos(offset1)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			frac = 1 - entity:GetCycle()
			return dlight:SetLightColor(255 * frac, 200 * frac, 0)
		end
		return true
	end
	entities["item_healthcharger"] = function(entity, dlight)
		dlight:SetRadius(32)
		dlight:SetParent(entity)
		dlight:SetBrightness(0.5)
		dlight:SetLightColor(0, 255, 255)
		dlight:SetLocalPos(offset2)
		dlight.LightThink = function()
			if not IsValid(entity) then
				dlight:Remove()
				return
			end
			frac = 1 - entity:GetCycle()
			return dlight:SetLightColor(0, 255 * frac, 255 * frac)
		end
		return true
	end
end
