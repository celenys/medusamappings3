local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1
L0_1 = GetResourceState
L1_1 = "ox_lib"
L0_1 = L0_1(L1_1)
L0_1 = "started" == L0_1
if L0_1 then
  L1_1 = LoadResourceFile
  L2_1 = "ox_lib"
  L3_1 = "init.lua"
  L1_1 = L1_1(L2_1, L3_1)
  if L1_1 then
    L2_1 = load
    L3_1 = L1_1
    L4_1 = "@ox_lib/init.lua"
    L2_1 = L2_1(L3_1, L4_1)
    L2_1()
  else
    L0_1 = false
    L2_1 = print
    L3_1 = "[REPAIR SHOPS] ox_lib resource is started but init.lua could not be loaded"
    L2_1(L3_1)
  end
end
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  function L0_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = GetInteriorAtCoords
    L3_3 = A0_3.x
    L4_3 = A0_3.y
    L5_3 = A0_3.z
    L2_3 = L2_3(L3_3, L4_3, L5_3)
    if 0 == L2_3 then
      L3_3 = print
      L4_3 = string
      L4_3 = L4_3.format
      L5_3 = "[REPAIR SHOPS] Warning: No interior found at coordinates for location '%s' (%.2f, %.2f, %.2f)"
      L6_3 = A1_3
      L7_3 = A0_3.x
      L8_3 = A0_3.y
      L9_3 = A0_3.z
      L4_3, L5_3, L6_3, L7_3, L8_3, L9_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
      L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
      L3_3 = false
      return L3_3
    end
    L3_3 = Config
    L3_3 = L3_3.InteriorEntitySets
    L3_3 = L3_3[A1_3]
    if L3_3 then
      L4_3 = ActivateInteriorEntitySet
      L5_3 = L2_3
      L6_3 = L3_3
      L4_3(L5_3, L6_3)
      L4_3 = print
      L5_3 = string
      L5_3 = L5_3.format
      L6_3 = "[REPAIR SHOPS] Activated entity set '%s' for interior %d at location '%s'"
      L7_3 = L3_3
      L8_3 = L2_3
      L9_3 = A1_3
      L5_3, L6_3, L7_3, L8_3, L9_3 = L5_3(L6_3, L7_3, L8_3, L9_3)
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    else
      L4_3 = print
      L5_3 = string
      L5_3 = L5_3.format
      L6_3 = "[REPAIR SHOPS] Warning: No entity set configured for location '%s'"
      L7_3 = A1_3
      L5_3, L6_3, L7_3, L8_3, L9_3 = L5_3(L6_3, L7_3)
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    end
    L4_3 = ActivateInteriorEntitySet
    L5_3 = L2_3
    L6_3 = "lift"
    L4_3(L5_3, L6_3)
    L4_3 = print
    L5_3 = string
    L5_3 = L5_3.format
    L6_3 = "[REPAIR SHOPS] Activated 'lift' entity set for interior %d at location '%s'"
    L7_3 = L2_3
    L8_3 = A1_3
    L5_3, L6_3, L7_3, L8_3, L9_3 = L5_3(L6_3, L7_3, L8_3)
    L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    L4_3 = RefreshInterior
    L5_3 = L2_3
    L4_3(L5_3)
    L4_3 = true
    return L4_3
  end
  L1_2 = Wait
  L2_2 = 2000
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = pairs
  L3_2 = Config
  L3_2 = L3_2.Props
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.location
    L8_2 = L1_2[L8_2]
    if not L8_2 then
      L8_2 = L7_2.location
      L1_2[L8_2] = true
      L8_2 = L0_2
      L9_2 = L7_2.coords
      L10_2 = L7_2.location
      L8_2(L9_2, L10_2)
    end
  end
end
if L0_1 then
  L2_1 = Config
  L2_1 = L2_1.EnableAnimatedProps
  if L2_1 then
    goto lbl_40
  end
end
L2_1 = L1_1
L2_1()
L2_1 = print
L3_1 = "[REPAIR SHOPS ANIMS DISABLED - ox_lib not found or Config.EnableAnimatedProps is false]"
L2_1(L3_1)
do return end
::lbl_40::
function L2_1(A0_2)
  local L1_2
  L1_2 = GlobalState
  L1_2 = L1_2.repair_shops_enabledLocations
  L1_2 = not A0_2 or L1_2
  return L1_2
end
L3_1 = {}
L4_1 = {}
L5_1 = {}
L6_1 = nil
L7_1 = false
L8_1 = {}
L9_1 = {}
L10_1 = GetResourceState
L11_1 = "ox_target"
L10_1 = L10_1(L11_1)
L10_1 = "started" == L10_1
L11_1 = L10_1 or L11_1
if L10_1 then
  L11_1 = Config
  L11_1 = L11_1.UseOxTarget
end
function L12_1()
  local L0_2, L1_2
  L0_2 = Config
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.InteractionControl
    if L0_2 then
      goto lbl_9
    end
  end
  L0_2 = 47
  ::lbl_9::
  return L0_2
end
function L13_1()
  local L0_2, L1_2
  L0_2 = Config
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.InteractionKeyLabel
    if L0_2 then
      goto lbl_9
    end
  end
  L0_2 = "G"
  ::lbl_9::
  return L0_2
end
function L14_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Config
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Messages
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Messages
      L3_2 = L3_2.textUI
    end
  end
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 or "" == L3_2 then
    L3_2 = "[{key}] {action} {label}"
  end
  L4_2 = L3_2
  L6_2 = L4_2
  L5_2 = L4_2.gsub
  L7_2 = "%{key%}"
  L8_2 = L13_1
  L8_2 = L8_2()
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L5_2
  L6_2 = L4_2
  L5_2 = L4_2.gsub
  L7_2 = "%{action%}"
  L8_2 = A0_2 or L8_2
  if not A0_2 then
    L8_2 = ""
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L5_2
  L6_2 = L4_2
  L5_2 = L4_2.gsub
  L7_2 = "%{name%}"
  L8_2 = A1_2 or L8_2
  if not A1_2 then
    L8_2 = ""
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L5_2
  L6_2 = L4_2
  L5_2 = L4_2.gsub
  L7_2 = "%{label%}"
  L8_2 = A2_2 or L8_2
  L8_2 = A1_2 or L8_2
  if not A2_2 and not A1_2 then
    L8_2 = ""
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2 = L5_2
  return L4_2
end
function L15_1()
  local L0_2, L1_2, L2_2
  L0_2 = GlobalState
  L0_2 = L0_2.repair_shops
  if not L0_2 then
    L0_2 = TriggerServerEvent
    L1_2 = "repair_shops_anims:initializeState"
    L2_2 = {}
    L0_2(L1_2, L2_2)
  end
end
function L16_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if not A0_2 or not A1_2 then
    L5_2 = nil
    return L5_2
  end
  L5_2 = lib
  L5_2 = L5_2.requestModel
  L6_2 = A0_2
  L5_2(L6_2)
  L5_2 = CreateObjectNoOffset
  L6_2 = joaat
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L7_2 = A1_2.x
  L8_2 = A1_2.y
  L9_2 = A1_2.z
  L10_2 = false
  L11_2 = false
  L12_2 = A3_2 or L12_2
  if not A3_2 then
    L12_2 = false
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  if not L5_2 or 0 == L5_2 then
    L6_2 = nil
    return L6_2
  end
  L6_2 = SetEntityRotation
  L7_2 = L5_2
  L8_2 = A2_2.x
  L9_2 = A2_2.y
  L10_2 = A2_2.z
  L11_2 = 2
  L12_2 = true
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = FreezeEntityPosition
  L7_2 = L5_2
  L8_2 = true
  L6_2(L7_2, L8_2)
  if A3_2 then
    L6_2 = SetEntityCollision
    L7_2 = L5_2
    L8_2 = true
    L9_2 = true
    L6_2(L7_2, L8_2, L9_2)
    if A4_2 then
      L6_2 = FreezeEntityPosition
      L7_2 = L5_2
      L8_2 = true
      L6_2(L7_2, L8_2)
    end
    L6_2 = SetEntityVisible
    L7_2 = L5_2
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
  L6_2 = SetModelAsNoLongerNeeded
  L7_2 = A0_2
  L6_2(L7_2)
  return L5_2
end
function L17_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = A0_2.name
  L1_2 = L3_1
  L1_2 = L1_2[L2_2]
  if L1_2 then
    L2_2 = A0_2.name
    L1_2 = L3_1
    L1_2 = L1_2[L2_2]
    return L1_2
  end
  L1_2 = L16_1
  L2_2 = A0_2.model
  L3_2 = A0_2.coords
  L4_2 = A0_2.rotation
  L5_2 = false
  L6_2 = false
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  if not L1_2 then
    L2_2 = nil
    return L2_2
  end
  L3_2 = A0_2.name
  L2_2 = L3_1
  L2_2[L3_2] = L1_2
  L2_2 = A0_2.collision
  if L2_2 then
    L2_2 = createCollision
    L3_2 = A0_2
    L2_2(L3_2)
  end
  L2_2 = A0_2.linkedProps
  if L2_2 then
    L2_2 = ipairs
    L3_2 = A0_2.linkedProps
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
      L8_2 = createLinkedProp
      L9_2 = L7_2
      L10_2 = A0_2.name
      L8_2(L9_2, L10_2)
    end
  end
  L2_2 = GlobalState
  L2_2 = L2_2.repair_shops
  if L2_2 then
    L2_2 = GlobalState
    L2_2 = L2_2.repair_shops
    L3_2 = A0_2.name
    L2_2 = L2_2[L3_2]
    if nil ~= L2_2 then
      L2_2 = SetTimeout
      L3_2 = 100
      function L4_2()
        local L0_3, L1_3, L2_3, L3_3, L4_3
        L0_3 = animateProp
        L1_3 = A0_2.name
        L2_3 = GlobalState
        L2_3 = L2_3.repair_shops
        L3_3 = A0_2.name
        L2_3 = L2_3[L3_3]
        L3_3 = true
        L4_3 = true
        L0_3(L1_3, L2_3, L3_3, L4_3)
      end
      L2_2(L3_2, L4_2)
  end
  else
    L2_2 = A0_2.animations
    if L2_2 then
      L2_2 = A0_2.animations
      L2_2 = L2_2.static
      if L2_2 then
        L2_2 = SetTimeout
        L3_2 = 100
        function L4_2()
          local L0_3, L1_3, L2_3
          L0_3 = playStaticAnimation
          L1_3 = L1_2
          L2_3 = A0_2
          L0_3(L1_3, L2_3)
        end
        L2_2(L3_2, L4_2)
      end
    end
  end
  return L1_2
end
createProp = L17_1
function L17_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = A0_2.collision
  if L1_2 then
    L1_2 = A0_2.collision
    L2_2 = L1_2.name
    L1_2 = L4_1
    L1_2 = L1_2[L2_2]
    if not L1_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L1_2 = A0_2.collision
  L1_2 = L1_2.coords
  L2_2 = A0_2.collision
  L2_2 = L2_2.rotation
  L3_2 = GlobalState
  L3_2 = L3_2.repair_shops
  if L3_2 then
    L3_2 = GlobalState
    L3_2 = L3_2.repair_shops
    L4_2 = A0_2.name
    L3_2 = L3_2[L4_2]
  end
  L4_2 = A0_2.collision
  L4_2 = L4_2.moveType
  if "coords" == L4_2 and nil ~= L3_2 then
    if L3_2 then
      L4_2 = A0_2.collision
      L4_2 = L4_2.endCoords
      L1_2 = L4_2 or L1_2
    end
    if not L4_2 then
      L4_2 = A0_2.collision
      L1_2 = L4_2.startCoords
    end
  else
    L4_2 = A0_2.collision
    L4_2 = L4_2.moveType
    if "rotation" == L4_2 and nil ~= L3_2 then
      if L3_2 then
        L4_2 = A0_2.collision
        L4_2 = L4_2.endRotation
        if L4_2 then
          goto lbl_52
          L2_2 = L4_2 or L2_2
        end
      end
      L4_2 = A0_2.collision
      L2_2 = L4_2.startRotation
    end
  end
  ::lbl_52::
  L4_2 = L16_1
  L5_2 = A0_2.collision
  L5_2 = L5_2.model
  L6_2 = L1_2
  L7_2 = L2_2
  L8_2 = true
  L9_2 = true
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  if L4_2 then
    L5_2 = A0_2.collision
    L6_2 = L5_2.name
    L5_2 = L4_1
    L5_2[L6_2] = L4_2
  end
  return L4_2
end
createCollision = L17_1
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = A0_2.name
  L2_2 = L5_1
  L2_2 = L2_2[L3_2]
  if L2_2 then
    L3_2 = A0_2.name
    L2_2 = L5_1
    L2_2 = L2_2[L3_2]
    return L2_2
  end
  L2_2 = L16_1
  L3_2 = A0_2.model
  L4_2 = A0_2.coords
  L5_2 = A0_2.rotation
  L6_2 = false
  L7_2 = false
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  if L2_2 then
    L4_2 = A0_2.name
    L3_2 = L5_1
    L5_2 = {}
    L5_2.entity = L2_2
    L5_2.parent = A1_2
    L3_2[L4_2] = L5_2
  end
  return L2_2
end
createLinkedProp = L17_1
function L17_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if A0_2 then
    L8_2 = DoesEntityExist
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L8_2 = lib
  L8_2 = L8_2.requestAnimDict
  L9_2 = A1_2
  L8_2(L9_2)
  L8_2 = PlayEntityAnim
  L9_2 = A0_2
  L10_2 = A2_2
  L11_2 = A1_2
  L12_2 = 8.0
  L13_2 = A4_2 or L13_2
  if not A4_2 then
    L13_2 = false
  end
  L14_2 = A5_2 or L14_2
  if not A5_2 then
    L14_2 = true
  end
  L15_2 = false
  L16_2 = A6_2 or L16_2
  if not A6_2 then
    L16_2 = 0.0
  end
  L17_2 = A7_2 or L17_2
  if not A7_2 then
    L17_2 = 0
  end
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L8_2 = RemoveAnimDict
  L9_2 = A1_2
  L8_2(L9_2)
end
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  if A0_2 then
    L2_2 = DoesEntityExist
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = A1_2.animations
      if L2_2 then
        L2_2 = A1_2.animations
        L2_2 = L2_2.static
        if L2_2 then
          goto lbl_16
        end
      end
    end
  end
  do return end
  ::lbl_16::
  L2_2 = A1_2.animations
  L2_2 = L2_2.dict
  L3_2 = A1_2.animations
  L3_2 = L3_2.static
  L4_2 = L17_1
  L5_2 = A0_2
  L6_2 = L2_2
  L7_2 = L3_2
  L8_2 = 0
  L9_2 = false
  L10_2 = true
  L11_2 = 0.0
  L12_2 = 0
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_2 = A1_2.linkedProps
  if L4_2 then
    L4_2 = A1_2.animations
    L4_2 = L4_2.linkedAnims
    if L4_2 then
      L4_2 = ipairs
      L5_2 = A1_2.linkedProps
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
        L11_2 = L9_2.name
        L10_2 = L5_1
        L10_2 = L10_2[L11_2]
        if L10_2 then
          L11_2 = L10_2.entity
          if L11_2 then
            L11_2 = A1_2.animations
            L11_2 = L11_2.linkedAnims
            L11_2 = L11_2[L8_2]
            L11_2 = L11_2.static
            if L11_2 then
              L12_2 = L17_1
              L13_2 = L10_2.entity
              L14_2 = L2_2
              L15_2 = L11_2
              L16_2 = 0
              L17_2 = false
              L18_2 = true
              L19_2 = 0.0
              L20_2 = 0
              L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
            end
          end
        end
      end
    end
  end
end
playStaticAnimation = L18_1
function L18_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if not A5_2 then
    A5_2 = 1
  end
  L6_2 = #A0_2
  if A5_2 > L6_2 then
    return
  end
  L6_2 = A0_2[A5_2]
  L8_2 = L6_2.name
  L7_2 = L5_1
  L7_2 = L7_2[L8_2]
  if L7_2 then
    L8_2 = L7_2.entity
    if L8_2 then
      if A3_2 then
        L8_2 = A1_2[A5_2]
        L8_2 = L8_2.open
        if L8_2 then
          goto lbl_25
        end
      end
      L8_2 = A1_2[A5_2]
      L8_2 = L8_2.close
      ::lbl_25::
      L9_2 = L17_1
      L10_2 = L7_2.entity
      L11_2 = A2_2
      L12_2 = L8_2
      L13_2 = A4_2
      L14_2 = false
      L15_2 = true
      L16_2 = 0.0
      L17_2 = 0
      L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    end
  end
  L8_2 = L18_1
  L9_2 = A0_2
  L10_2 = A1_2
  L11_2 = A2_2
  L12_2 = A3_2
  L13_2 = A4_2
  L14_2 = A5_2 + 1
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
end
function L19_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L4_2 = nil
  L5_2 = pairs
  L6_2 = Config
  L6_2 = L6_2.Props
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = L10_2.name
    if L11_2 == A0_2 then
      L4_2 = L10_2
      break
    end
  end
  if L4_2 then
    L5_2 = L3_1
    L5_2 = L5_2[A0_2]
    if L5_2 then
      goto lbl_22
    end
  end
  do return end
  ::lbl_22::
  L5_2 = L3_1
  L5_2 = L5_2[A0_2]
  L6_2 = L4_2.animations
  L6_2 = L6_2.dict
  if A1_2 then
    L7_2 = L4_2.animations
    L7_2 = L7_2.open
    if L7_2 then
      goto lbl_34
    end
  end
  L7_2 = L4_2.animations
  L7_2 = L7_2.close
  ::lbl_34::
  L8_2 = lib
  L8_2 = L8_2.requestAnimDict
  L9_2 = L6_2
  L8_2(L9_2)
  L8_2 = GetAnimDuration
  L9_2 = L6_2
  L10_2 = L7_2
  L8_2 = L8_2(L9_2, L10_2)
  L8_2 = L8_2 * 1000
  L9_2 = L8_2 or L9_2
  if not (L8_2 > 0) or not L8_2 then
    L9_2 = L4_2.animations
    L9_2 = L9_2.duration
  end
  L10_2 = L4_2.playerAnimation
  if L10_2 and not A3_2 then
    if A1_2 then
      L10_2 = L4_2.playerAnimation
      L10_2 = L10_2.name
      if L10_2 then
        goto lbl_67
      end
    end
    L10_2 = L4_2.playerAnimation
    L10_2 = L10_2.closeName
    if not L10_2 then
      L10_2 = L4_2.playerAnimation
      L10_2 = L10_2.name
    end
    ::lbl_67::
    L11_2 = DoesEntityExist
    L12_2 = L5_2
    L11_2 = L11_2(L12_2)
    if not L11_2 then
      L11_2 = print
      L12_2 = "Error: The prop does not exist to animate"
      L11_2(L12_2)
      L11_2 = false
      return L11_2
    end
    L11_2 = TriggerServerEvent
    L12_2 = "repair_shops_anims:requestPlayerAnimation"
    L13_2 = {}
    L14_2 = L4_2.playerAnimation
    L14_2 = L14_2.dict
    L13_2.dict = L14_2
    L13_2.anim = L10_2
    L14_2 = type
    L15_2 = L4_2.playerAnimation
    L15_2 = L15_2.position
    L14_2 = L14_2(L15_2)
    if "table" == L14_2 then
      L14_2 = L4_2.playerAnimation
      L14_2 = L14_2.position
      L14_2 = L14_2[L10_2]
      if L14_2 then
        goto lbl_98
      end
    end
    L14_2 = L4_2.playerAnimation
    L14_2 = L14_2.position
    ::lbl_98::
    L13_2.position = L14_2
    L14_2 = type
    L15_2 = L4_2.playerAnimation
    L15_2 = L15_2.heading
    L14_2 = L14_2(L15_2)
    if "table" == L14_2 then
      L14_2 = L4_2.playerAnimation
      L14_2 = L14_2.heading
      L14_2 = L14_2[L10_2]
      if L14_2 then
        goto lbl_112
      end
    end
    L14_2 = L4_2.playerAnimation
    L14_2 = L14_2.heading
    ::lbl_112::
    L13_2.heading = L14_2
    L13_2.propName = A0_2
    L13_2.state = A1_2
    L11_2(L12_2, L13_2)
  else
    L10_2 = animatePropObject
    L11_2 = L4_2
    L12_2 = L5_2
    L13_2 = A1_2
    L14_2 = L6_2
    L15_2 = L7_2
    L16_2 = L9_2
    L17_2 = A2_2
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  L10_2 = true
  return L10_2
end
animateProp = L19_1
function L19_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L7_2 = L17_1
  L8_2 = A1_2
  L9_2 = A3_2
  L10_2 = A4_2
  L11_2 = A5_2
  L12_2 = false
  L13_2 = true
  L14_2 = 0.0
  L15_2 = 0
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if not A6_2 then
    L7_2 = TriggerEvent
    L8_2 = "prompt_repair_shops:liftStateChanged"
    L9_2 = A0_2.name
    L10_2 = A2_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L7_2 = A0_2.linkedProps
  if L7_2 then
    L7_2 = A0_2.animations
    L7_2 = L7_2.linkedAnims
    if L7_2 then
      L7_2 = L18_1
      L8_2 = A0_2.linkedProps
      L9_2 = A0_2.animations
      L9_2 = L9_2.linkedAnims
      L10_2 = A3_2
      L11_2 = A2_2
      L12_2 = A5_2
      L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
    end
  end
  L7_2 = A0_2.collision
  if L7_2 then
    L7_2 = A0_2.collision
    L8_2 = L7_2.name
    L7_2 = L4_1
    L7_2 = L7_2[L8_2]
    if L7_2 then
      L8_2 = A0_2.collision
      L8_2 = L8_2.moveType
      if "coords" == L8_2 then
        if A2_2 then
          L8_2 = A0_2.collision
          L8_2 = L8_2.startCoords
          if L8_2 then
            goto lbl_54
          end
        end
        L8_2 = A0_2.collision
        L8_2 = L8_2.endCoords
        ::lbl_54::
        if A2_2 then
          L9_2 = A0_2.collision
          L9_2 = L9_2.endCoords
          if L9_2 then
            goto lbl_62
          end
        end
        L9_2 = A0_2.collision
        L9_2 = L9_2.startCoords
        ::lbl_62::
        L10_2 = A5_2
        L11_2 = 0
        L12_2 = "easeInOut"
        L13_2 = A0_2.collision
        L13_2 = L13_2.liftSettings
        if L13_2 then
          if A2_2 then
            L13_2 = A0_2.collision
            L13_2 = L13_2.liftSettings
            L13_2 = L13_2.upDelay
            L11_2 = L13_2 or L11_2
            if not L13_2 then
              L11_2 = 200
            end
            L13_2 = A0_2.collision
            L13_2 = L13_2.liftSettings
            L13_2 = L13_2.upSpeedFactor
            if not L13_2 then
              L13_2 = 0.8
            end
            L10_2 = A5_2 * L13_2
            L13_2 = A0_2.collision
            L13_2 = L13_2.liftSettings
            L13_2 = L13_2.upCurve
            L12_2 = L13_2 or L12_2
            if not L13_2 then
              L12_2 = "easeInOutQuad"
            end
          else
            L13_2 = A0_2.collision
            L13_2 = L13_2.liftSettings
            L13_2 = L13_2.downSpeedFactor
            if not L13_2 then
              L13_2 = 1.2
            end
            L10_2 = A5_2 * L13_2
            L13_2 = A0_2.collision
            L13_2 = L13_2.liftSettings
            L13_2 = L13_2.downCurve
            L12_2 = L13_2 or L12_2
            if not L13_2 then
              L12_2 = "easeOutCubic"
            end
          end
        else
          L13_2 = A0_2.name
          if "prompt_sandy_is_lift" == L13_2 then
            if A2_2 then
              L11_2 = 200
              L10_2 = A5_2 * 0.8
              L12_2 = "easeInOutQuad"
            else
              L10_2 = A5_2 * 1.2
              L12_2 = "easeOutCubic"
            end
          end
        end
        if A2_2 then
          L13_2 = A0_2.collision
          L13_2 = L13_2.openDelay
          if L13_2 then
            goto lbl_132
          end
        end
        if not A2_2 then
          L13_2 = A0_2.collision
          L13_2 = L13_2.closeDelay
          ::lbl_132::
          if L13_2 then
            if A2_2 then
              L13_2 = A0_2.collision
              L13_2 = L13_2.openDelay
              if L13_2 then
                goto lbl_140
              end
            end
            L13_2 = A0_2.collision
            L13_2 = L13_2.closeDelay
            ::lbl_140::
            L14_2 = SetTimeout
            L15_2 = L13_2
            function L16_2()
              local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
              L0_3 = AnimateObjectCoords
              L1_3 = L7_2
              L2_3 = L8_2
              L3_3 = L9_2
              L4_3 = L10_2
              L5_3 = L12_2
              L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
            end
            L14_2(L15_2, L16_2)
        end
        elseif L11_2 > 0 then
          L13_2 = SetTimeout
          L14_2 = L11_2
          function L15_2()
            local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
            L0_3 = AnimateObjectCoords
            L1_3 = L7_2
            L2_3 = L8_2
            L3_3 = L9_2
            L4_3 = L10_2
            L5_3 = L12_2
            L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
          end
          L13_2(L14_2, L15_2)
        else
          L13_2 = AnimateObjectCoords
          L14_2 = L7_2
          L15_2 = L8_2
          L16_2 = L9_2
          L17_2 = L10_2
          L18_2 = L12_2
          L13_2(L14_2, L15_2, L16_2, L17_2, L18_2)
        end
      else
        L8_2 = A0_2.collision
        L8_2 = L8_2.moveType
        if "rotation" == L8_2 then
          if A2_2 then
            L8_2 = A0_2.collision
            L8_2 = L8_2.startRotation
            if L8_2 then
              goto lbl_173
            end
          end
          L8_2 = A0_2.collision
          L8_2 = L8_2.endRotation
          ::lbl_173::
          if A2_2 then
            L9_2 = A0_2.collision
            L9_2 = L9_2.endRotation
            if L9_2 then
              goto lbl_181
            end
          end
          L9_2 = A0_2.collision
          L9_2 = L9_2.startRotation
          ::lbl_181::
          L10_2 = AnimateObjectRotation
          L11_2 = L7_2
          L12_2 = L8_2
          L13_2 = L9_2
          L14_2 = A5_2
          L15_2 = "easeInOut"
          L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
        end
      end
    end
  end
  if not A6_2 then
    L7_2 = TriggerServerEvent
    L8_2 = "repair_shops_anims:updatePropState"
    L9_2 = A0_2.name
    L10_2 = A2_2
    L7_2(L8_2, L9_2, L10_2)
  end
  L7_2 = SetTimeout
  L8_2 = A5_2
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = TriggerServerEvent
    L1_3 = "repair_shops_anims:setPropBusy"
    L2_3 = A0_2.name
    L3_3 = false
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = A6_2
    if not L0_3 then
      L0_3 = TriggerEvent
      L1_3 = "prompt_repair_shops:liftAnimationComplete"
      L2_3 = A0_2.name
      L3_3 = A2_2
      L0_3(L1_3, L2_3, L3_3)
    end
  end
  L7_2(L8_2, L9_2)
end
animatePropObject = L19_1
L19_1 = exports
L20_1 = "getLiftState"
function L21_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalState
  L1_2 = L1_2.repair_shops
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2[A0_2]
  return L2_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "isLiftBusy"
function L21_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalState
  L1_2 = L1_2.repair_shops_busy
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2[A0_2]
  if not L2_2 then
    L2_2 = false
  end
  return L2_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "setLiftState"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = animateProp
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = TriggerServerEvent
  L3_2 = "repair_shops_anims:setPropBusy"
  L4_2 = A0_2
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
end
L19_1(L20_1, L21_1)
L19_1 = Config
L19_1 = L19_1.Debug
if L19_1 then
  L19_1 = AddEventHandler
  L20_1 = "prompt_repair_shops:liftStateChanged"
  function L21_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
    L2_2 = print
    L3_2 = "[REPAIR SHOPS EXPORT DEBUG] [CLIENT] liftStateChanged -> propName: %s | state: %s (%s)"
    L4_2 = L3_2
    L3_2 = L3_2.format
    L5_2 = A0_2
    L6_2 = tostring
    L7_2 = A1_2
    L6_2 = L6_2(L7_2)
    if A1_2 then
      L7_2 = "UP"
      if L7_2 then
        goto lbl_14
      end
    end
    L7_2 = "DOWN"
    ::lbl_14::
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L2_2 = exports
    L3_2 = GetCurrentResourceName
    L3_2 = L3_2()
    L2_2 = L2_2[L3_2]
    L3_2 = L2_2
    L2_2 = L2_2.getLiftState
    L4_2 = A0_2
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = print
    L4_2 = "[REPAIR SHOPS EXPORT DEBUG] [CLIENT] getLiftState(%s) = %s"
    L5_2 = L4_2
    L4_2 = L4_2.format
    L6_2 = A0_2
    L7_2 = tostring
    L8_2 = L2_2
    L7_2, L8_2, L9_2 = L7_2(L8_2)
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L3_2 = exports
    L4_2 = GetCurrentResourceName
    L4_2 = L4_2()
    L3_2 = L3_2[L4_2]
    L4_2 = L3_2
    L3_2 = L3_2.isLiftBusy
    L5_2 = A0_2
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = print
    L5_2 = "[REPAIR SHOPS EXPORT DEBUG] [CLIENT] isLiftBusy(%s) = %s"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = A0_2
    L8_2 = tostring
    L9_2 = L3_2
    L8_2, L9_2 = L8_2(L9_2)
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
  L19_1(L20_1, L21_1)
  L19_1 = AddEventHandler
  L20_1 = "prompt_repair_shops:liftAnimationComplete"
  function L21_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
    L2_2 = print
    L3_2 = "[REPAIR SHOPS EXPORT DEBUG] [CLIENT] liftAnimationComplete -> propName: %s | state: %s (%s)"
    L4_2 = L3_2
    L3_2 = L3_2.format
    L5_2 = A0_2
    L6_2 = tostring
    L7_2 = A1_2
    L6_2 = L6_2(L7_2)
    if A1_2 then
      L7_2 = "UP"
      if L7_2 then
        goto lbl_14
      end
    end
    L7_2 = "DOWN"
    ::lbl_14::
    L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L19_1(L20_1, L21_1)
end
function L19_1(A0_2)
  local L1_2, L2_2
  L1_2 = L6_1
  if L1_2 ~= A0_2 then
    if A0_2 then
      L1_2 = lib
      L1_2 = L1_2.showTextUI
      L2_2 = A0_2
      L1_2(L2_2)
    else
      L1_2 = lib
      L1_2 = L1_2.hideTextUI
      L1_2()
    end
    L6_1 = A0_2
  end
end
updateTextUI = L19_1
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = Config
  L2_2 = L2_2.Props
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = GlobalState
    L7_2 = L7_2.repair_shops
    if L7_2 then
      L7_2 = GlobalState
      L7_2 = L7_2.repair_shops
      L8_2 = L6_2.name
      L7_2 = L7_2[L8_2]
    end
    if L7_2 then
      L8_2 = Config
      L8_2 = L8_2.Messages
      L8_2 = L8_2.close
      if L8_2 then
        goto lbl_26
      end
    end
    L8_2 = Config
    L8_2 = L8_2.Messages
    L8_2 = L8_2.open
    ::lbl_26::
    L9_2 = L6_2.displayName
    if not L9_2 then
      L9_2 = L6_2.label
      if not L9_2 then
        L9_2 = L6_2.name
      end
    end
    L10_2 = table
    L10_2 = L10_2.insert
    L11_2 = L0_2
    L12_2 = {}
    L12_2.title = L9_2
    L13_2 = L8_2
    L14_2 = " "
    L15_2 = L9_2
    L13_2 = L13_2 .. L14_2 .. L15_2
    L12_2.description = L13_2
    L12_2.icon = "building"
    function L13_2()
      local L0_3, L1_3, L2_3
      L0_3 = animateProp
      L1_3 = L6_2.name
      L2_3 = L7_2
      L2_3 = not L2_3
      L0_3(L1_3, L2_3)
    end
    L12_2.onSelect = L13_2
    L10_2(L11_2, L12_2)
  end
  return L0_2
end
getTestMenu = L19_1
function L19_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.interactionZone
  if not L1_2 then
    return
  end
  L2_2 = A0_2.name
  L1_2 = L9_1
  L1_2 = L1_2[L2_2]
  if L1_2 then
    return
  end
  L1_2 = "repair_shops_"
  L2_2 = A0_2.name
  L1_2 = L1_2 .. L2_2
  L2_2 = A0_2.displayName
  if not L2_2 then
    L2_2 = A0_2.label
    if not L2_2 then
      L2_2 = A0_2.name
    end
  end
  L3_2 = exports
  L3_2 = L3_2.ox_target
  L4_2 = L3_2
  L3_2 = L3_2.addBoxZone
  L5_2 = {}
  L6_2 = A0_2.interactionZone
  L6_2 = L6_2.coords
  L5_2.coords = L6_2
  L6_2 = A0_2.interactionZone
  L6_2 = L6_2.size
  L5_2.size = L6_2
  L6_2 = A0_2.interactionZone
  L6_2 = L6_2.rotation
  if not L6_2 then
    L6_2 = 0
  end
  L5_2.rotation = L6_2
  L6_2 = Config
  L6_2 = L6_2.Debug
  L5_2.debug = L6_2
  L6_2 = {}
  L7_2 = {}
  L8_2 = L1_2
  L9_2 = "_open"
  L8_2 = L8_2 .. L9_2
  L7_2.name = L8_2
  L7_2.icon = "fas fa-arrow-up"
  L8_2 = Config
  L8_2 = L8_2.Messages
  L8_2 = L8_2.open
  L9_2 = " "
  L10_2 = L2_2
  L8_2 = L8_2 .. L9_2 .. L10_2
  L7_2.label = L8_2
  function L8_2()
    local L0_3, L1_3, L2_3
    L0_3 = GlobalState
    L0_3 = L0_3.repair_shops
    if L0_3 then
      L0_3 = GlobalState
      L0_3 = L0_3.repair_shops
      L1_3 = A0_2.name
      L0_3 = L0_3[L1_3]
    end
    L1_3 = GlobalState
    L1_3 = L1_3.repair_shops_busy
    if L1_3 then
      L1_3 = GlobalState
      L1_3 = L1_3.repair_shops_busy
      L2_3 = A0_2.name
      L1_3 = L1_3[L2_3]
    end
    if L1_3 then
      L2_3 = false
      return L2_3
    end
    if L0_3 then
      L2_3 = false
      return L2_3
    end
    L2_3 = true
    return L2_3
  end
  L7_2.canInteract = L8_2
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2.onExecute
    if L0_3 then
      L0_3 = A0_2.onExecute
      L1_3 = A0_2
      L0_3(L1_3)
    end
    L0_3 = TriggerServerEvent
    L1_3 = "repair_shops_anims:setPropBusy"
    L2_3 = A0_2.name
    L3_3 = true
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = animateProp
    L1_3 = A0_2.name
    L2_3 = true
    L0_3(L1_3, L2_3)
  end
  L7_2.onSelect = L8_2
  L8_2 = {}
  L9_2 = L1_2
  L10_2 = "_close"
  L9_2 = L9_2 .. L10_2
  L8_2.name = L9_2
  L8_2.icon = "fas fa-arrow-down"
  L9_2 = Config
  L9_2 = L9_2.Messages
  L9_2 = L9_2.close
  L10_2 = " "
  L11_2 = L2_2
  L9_2 = L9_2 .. L10_2 .. L11_2
  L8_2.label = L9_2
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = GlobalState
    L0_3 = L0_3.repair_shops
    if L0_3 then
      L0_3 = GlobalState
      L0_3 = L0_3.repair_shops
      L1_3 = A0_2.name
      L0_3 = L0_3[L1_3]
    end
    L1_3 = GlobalState
    L1_3 = L1_3.repair_shops_busy
    if L1_3 then
      L1_3 = GlobalState
      L1_3 = L1_3.repair_shops_busy
      L2_3 = A0_2.name
      L1_3 = L1_3[L2_3]
    end
    if L1_3 then
      L2_3 = false
      return L2_3
    end
    if not L0_3 then
      L2_3 = false
      return L2_3
    end
    L2_3 = true
    return L2_3
  end
  L8_2.canInteract = L9_2
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2.onExecute
    if L0_3 then
      L0_3 = A0_2.onExecute
      L1_3 = A0_2
      L0_3(L1_3)
    end
    L0_3 = TriggerServerEvent
    L1_3 = "repair_shops_anims:setPropBusy"
    L2_3 = A0_2.name
    L3_3 = true
    L0_3(L1_3, L2_3, L3_3)
    L0_3 = animateProp
    L1_3 = A0_2.name
    L2_3 = false
    L0_3(L1_3, L2_3)
  end
  L8_2.onSelect = L9_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L5_2.options = L6_2
  L3_2(L4_2, L5_2)
  L4_2 = A0_2.name
  L3_2 = L9_1
  L3_2[L4_2] = L1_2
end
registerOxTarget = L19_1
function L19_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = A0_2.interactionZone
  if not L1_2 then
    return
  end
  L1_2 = lib
  L1_2 = L1_2.zones
  L1_2 = L1_2.box
  L2_2 = {}
  L3_2 = A0_2.interactionZone
  L3_2 = L3_2.coords
  L2_2.coords = L3_2
  L3_2 = A0_2.interactionZone
  L3_2 = L3_2.size
  L2_2.size = L3_2
  L3_2 = A0_2.interactionZone
  L3_2 = L3_2.rotation
  L2_2.rotation = L3_2
  L2_2.debug = false
  function L3_2()
    local L0_3, L1_3
    L0_3 = true
    L7_1 = L0_3
    L1_3 = A0_2.name
    L0_3 = L8_1
    L0_3[L1_3] = true
  end
  L2_2.onEnter = L3_2
  function L3_2()
    local L0_3, L1_3
    L1_3 = A0_2.name
    L0_3 = L8_1
    L0_3[L1_3] = nil
    L0_3 = next
    L1_3 = L8_1
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L0_3 = false
      L7_1 = L0_3
      L0_3 = updateTextUI
      L1_3 = nil
      L0_3(L1_3)
    end
  end
  L2_2.onExit = L3_2
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = GlobalState
    L0_3 = L0_3.repair_shops
    if L0_3 then
      L0_3 = GlobalState
      L0_3 = L0_3.repair_shops
      L1_3 = A0_2.name
      L0_3 = L0_3[L1_3]
    end
    L1_3 = GlobalState
    L1_3 = L1_3.repair_shops_busy
    if L1_3 then
      L1_3 = GlobalState
      L1_3 = L1_3.repair_shops_busy
      L2_3 = A0_2.name
      L1_3 = L1_3[L2_3]
    end
    if L1_3 then
      L2_3 = updateTextUI
      L3_3 = nil
      L2_3(L3_3)
      return
    end
    if L0_3 then
      L2_3 = Config
      L2_3 = L2_3.Messages
      L2_3 = L2_3.close
      if L2_3 then
        goto lbl_33
      end
    end
    L2_3 = Config
    L2_3 = L2_3.Messages
    L2_3 = L2_3.open
    ::lbl_33::
    L3_3 = A0_2.displayName
    if not L3_3 then
      L3_3 = A0_2.label
      if not L3_3 then
        L3_3 = A0_2.name
      end
    end
    L4_3 = updateTextUI
    L5_3 = L14_1
    L6_3 = L2_3
    L7_3 = A0_2.name
    L8_3 = L3_3
    L5_3, L6_3, L7_3, L8_3 = L5_3(L6_3, L7_3, L8_3)
    L4_3(L5_3, L6_3, L7_3, L8_3)
    L4_3 = IsControlJustPressed
    L5_3 = 0
    L6_3 = L12_1
    L6_3, L7_3, L8_3 = L6_3()
    L4_3 = L4_3(L5_3, L6_3, L7_3, L8_3)
    if L4_3 then
      L4_3 = A0_2.onExecute
      if L4_3 then
        L4_3 = A0_2.onExecute
        L5_3 = A0_2
        L4_3(L5_3)
      end
      L4_3 = TriggerServerEvent
      L5_3 = "repair_shops_anims:setPropBusy"
      L6_3 = A0_2.name
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = animateProp
      L5_3 = A0_2.name
      L6_3 = not L0_3
      L4_3(L5_3, L6_3)
    end
  end
  L2_2.inside = L3_2
  return L1_2(L2_2)
end
createInteractionZone = L19_1
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L11_1
  if L0_2 then
    L0_2 = pairs
    L1_2 = Config
    L1_2 = L1_2.Props
    L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
    for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
      L6_2 = L2_1
      L7_2 = L5_2.location
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = registerOxTarget
        L7_2 = L5_2
        L6_2(L7_2)
      else
        L6_2 = print
        L7_2 = "Skipped zone for %s (location off)"
        L8_2 = L5_2.name
        L6_2(L7_2, L8_2)
      end
    end
  else
    L0_2 = pairs
    L1_2 = Config
    L1_2 = L1_2.Props
    L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
    for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
      L6_2 = L2_1
      L7_2 = L5_2.location
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = createInteractionZone
        L7_2 = L5_2
        L6_2(L7_2)
      else
        L6_2 = print
        L7_2 = "Skipped zone for %s (location off)"
        L8_2 = L5_2.name
        L6_2(L7_2, L8_2)
      end
    end
  end
end
createInteractionZones = L19_1
function L19_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = lib
  L1_2 = L1_2.points
  L1_2 = L1_2.new
  L2_2 = {}
  L3_2 = A0_2.coords
  L2_2.coords = L3_2
  L3_2 = Config
  L3_2 = L3_2.SpawnDistance
  L2_2.distance = L3_2
  function L3_2()
    local L0_3, L1_3
    L0_3 = createProp
    L1_3 = A0_2
    L0_3(L1_3)
  end
  L2_2.onEnter = L3_2
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = A0_2.name
    L0_3 = L3_1
    L0_3 = L0_3[L1_3]
    if L0_3 then
      L0_3 = DeleteEntity
      L2_3 = A0_2.name
      L1_3 = L3_1
      L1_3 = L1_3[L2_3]
      L0_3(L1_3)
      L1_3 = A0_2.name
      L0_3 = L3_1
      L0_3[L1_3] = nil
    end
    L0_3 = A0_2.collision
    if L0_3 then
      L0_3 = A0_2.collision
      L1_3 = L0_3.name
      L0_3 = L4_1
      L0_3 = L0_3[L1_3]
      if L0_3 then
        L0_3 = DeleteEntity
        L1_3 = A0_2.collision
        L2_3 = L1_3.name
        L1_3 = L4_1
        L1_3 = L1_3[L2_3]
        L0_3(L1_3)
        L0_3 = A0_2.collision
        L1_3 = L0_3.name
        L0_3 = L4_1
        L0_3[L1_3] = nil
      end
    end
    L0_3 = A0_2.linkedProps
    if L0_3 then
      L0_3 = ipairs
      L1_3 = A0_2.linkedProps
      L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3)
      for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
        L7_3 = L5_3.name
        L6_3 = L5_1
        L6_3 = L6_3[L7_3]
        if L6_3 then
          L6_3 = DeleteEntity
          L8_3 = L5_3.name
          L7_3 = L5_1
          L7_3 = L7_3[L8_3]
          L7_3 = L7_3.entity
          L6_3(L7_3)
          L7_3 = L5_3.name
          L6_3 = L5_1
          L6_3[L7_3] = nil
        end
      end
    end
  end
  L2_2.onExit = L3_2
  L1_2(L2_2)
end
createSpawnPoint = L19_1
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = pairs
  L1_2 = Config
  L1_2 = L1_2.Props
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = L2_1
    L7_2 = L5_2.location
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = createSpawnPoint
      L7_2 = L5_2
      L6_2(L7_2)
    else
      L6_2 = print
      L7_2 = "Skipped spawn-point for %s (location off)"
      L8_2 = L5_2.name
      L6_2(L7_2, L8_2)
    end
  end
end
createSpawnPoints = L19_1
L19_1 = RegisterNetEvent
L20_1 = "repair_shops_anims:syncAnimation"
L19_1(L20_1)
L19_1 = AddEventHandler
L20_1 = "repair_shops_anims:syncAnimation"
function L21_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = GetPlayerPed
  L5_2 = GetPlayerFromServerId
  L6_2 = A0_2
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L5_2 = cache
  L5_2 = L5_2.ped
  if L4_2 ~= L5_2 then
    L5_2 = lib
    L5_2 = L5_2.requestAnimDict
    L6_2 = A1_2
    L5_2(L6_2)
    L5_2 = TaskPlayAnim
    L6_2 = L4_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = 8.0
    L10_2 = -8.0
    L11_2 = A3_2
    L12_2 = 0
    L13_2 = 0
    L14_2 = false
    L15_2 = false
    L16_2 = false
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L5_2 = RemoveAnimDict
    L6_2 = A1_2
    L5_2(L6_2)
  end
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "repair_shops_anims:animatePropAfterPlayerAnim"
L19_1(L20_1)
L19_1 = AddEventHandler
L20_1 = "repair_shops_anims:animatePropAfterPlayerAnim"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = A0_2.propName
  L2_2 = A0_2.state
  L3_2 = nil
  L4_2 = pairs
  L5_2 = Config
  L5_2 = L5_2.Props
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L9_2.name
    if L10_2 == L1_2 then
      L3_2 = L9_2
      break
    end
  end
  if not L3_2 then
    L4_2 = print
    L5_2 = "Error: No found the configuration for the prop: "
    L6_2 = L1_2
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    return
  end
  L4_2 = L3_1
  L4_2 = L4_2[L1_2]
  if not L4_2 then
    L4_2 = print
    L5_2 = "Error: The prop is not spawned: "
    L6_2 = L1_2
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    return
  end
  L4_2 = L3_1
  L4_2 = L4_2[L1_2]
  L5_2 = DoesEntityExist
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = print
    L6_2 = "Error: The entity of the prop does not exist: "
    L7_2 = L1_2
    L6_2 = L6_2 .. L7_2
    L5_2(L6_2)
    return
  end
  L5_2 = L3_2.animations
  L5_2 = L5_2.dict
  if L2_2 then
    L6_2 = L3_2.animations
    L6_2 = L6_2.open
    if L6_2 then
      goto lbl_58
    end
  end
  L6_2 = L3_2.animations
  L6_2 = L6_2.close
  ::lbl_58::
  L7_2 = lib
  L7_2 = L7_2.requestAnimDict
  L8_2 = L5_2
  L7_2(L8_2)
  L7_2 = GetAnimDuration
  L8_2 = L5_2
  L9_2 = L6_2
  L7_2 = L7_2(L8_2, L9_2)
  L7_2 = L7_2 * 1000
  L8_2 = L7_2 or L8_2
  if not (L7_2 > 0) or not L7_2 then
    L8_2 = L3_2.animations
    L8_2 = L8_2.duration
  end
  L9_2 = animatePropObject
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L2_2
  L13_2 = L5_2
  L14_2 = L6_2
  L15_2 = L8_2
  L16_2 = false
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
end
L19_1(L20_1, L21_1)
function L19_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = AddStateBagChangeHandler
  L1_2 = "repair_shops"
  L2_2 = nil
  function L3_2(A0_3, A1_3, A2_3, A3_3, A4_3)
    local L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    if not A2_3 then
      return
    end
    L5_3 = GlobalState
    L5_3 = L5_3.repair_shops
    if not L5_3 then
      L5_3 = {}
    end
    L6_3 = pairs
    L7_3 = Config
    L7_3 = L7_3.Props
    L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3)
    for L10_3, L11_3 in L6_3, L7_3, L8_3, L9_3 do
      L12_3 = L11_3.name
      L13_3 = A2_3[L12_3]
      if nil ~= L13_3 then
        L13_3 = A2_3[L12_3]
        L14_3 = L5_3[L12_3]
        if L13_3 ~= L14_3 then
          L13_3 = L3_1
          L13_3 = L13_3[L12_3]
          if L13_3 then
            L13_3 = animateProp
            L14_3 = L12_3
            L15_3 = A2_3[L12_3]
            L16_3 = true
            L17_3 = true
            L13_3(L14_3, L15_3, L16_3, L17_3)
          end
        end
      end
    end
  end
  L0_2(L1_2, L2_2, L3_2)
end
registerPropStateHandlers = L19_1
L19_1 = lib
L19_1 = L19_1.callback
L19_1 = L19_1.register
L20_1 = "repair_shops_anims:playPlayerAnimation"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A0_2 then
    L1_2 = A0_2.dict
    if L1_2 then
      L1_2 = A0_2.anim
      if L1_2 then
        L1_2 = A0_2.propName
        if L1_2 then
          goto lbl_17
        end
      end
    end
  end
  L1_2 = print
  L2_2 = "Error: Incomplete data for the player animation"
  L1_2(L2_2)
  L1_2 = false
  do return L1_2 end
  ::lbl_17::
  L1_2 = A0_2.position
  if L1_2 then
    L1_2 = A0_2.heading
    if L1_2 then
      goto lbl_28
    end
  end
  L1_2 = print
  L2_2 = "Error: Position or heading not provided for the player animation"
  L1_2(L2_2)
  L1_2 = false
  do return L1_2 end
  ::lbl_28::
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = ClearPedTasks
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = TaskGoStraightToCoord
  L3_2 = L1_2
  L4_2 = A0_2.position
  L4_2 = L4_2.x
  L5_2 = A0_2.position
  L5_2 = L5_2.y
  L6_2 = A0_2.position
  L6_2 = L6_2.z
  L7_2 = 1.0
  L8_2 = -1
  L9_2 = A0_2.heading
  L10_2 = 0.1
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = 0.5
  L3_2 = 5000
  L4_2 = GetGameTimer
  L4_2 = L4_2()
  while true do
    L5_2 = GetEntityCoords
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    L6_2 = A0_2.position
    L6_2 = L5_2 - L6_2
    L6_2 = #L6_2
    if L2_2 > L6_2 then
      break
    end
    L7_2 = GetGameTimer
    L7_2 = L7_2()
    L7_2 = L7_2 - L4_2
    if L3_2 < L7_2 then
      L7_2 = SetEntityCoords
      L8_2 = L1_2
      L9_2 = A0_2.position
      L9_2 = L9_2.x
      L10_2 = A0_2.position
      L10_2 = L10_2.y
      L11_2 = A0_2.position
      L11_2 = L11_2.z
      L12_2 = false
      L13_2 = false
      L14_2 = false
      L15_2 = false
      L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
      break
    end
    L7_2 = Wait
    L8_2 = 100
    L7_2(L8_2)
  end
  L5_2 = SetEntityCoordsNoOffset
  L6_2 = L1_2
  L7_2 = A0_2.position
  L7_2 = L7_2.x
  L8_2 = A0_2.position
  L8_2 = L8_2.y
  L9_2 = A0_2.position
  L9_2 = L9_2.z
  L10_2 = false
  L11_2 = false
  L12_2 = false
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L5_2 = SetEntityHeading
  L6_2 = L1_2
  L7_2 = A0_2.heading
  L5_2(L6_2, L7_2)
  L5_2 = lib
  L5_2 = L5_2.requestAnimDict
  L6_2 = A0_2.dict
  L5_2(L6_2)
  L5_2 = TaskPlayAnim
  L6_2 = L1_2
  L7_2 = A0_2.dict
  L8_2 = A0_2.anim
  L9_2 = 8.0
  L10_2 = 8.0
  L11_2 = -1
  L12_2 = 0
  L13_2 = 0
  L14_2 = false
  L15_2 = false
  L16_2 = false
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  L5_2 = RemoveAnimDict
  L6_2 = A0_2.dict
  L5_2(L6_2)
  L5_2 = TriggerServerEvent
  L6_2 = "repair_shops_anims:syncAnimation"
  L7_2 = A0_2.dict
  L8_2 = A0_2.anim
  L9_2 = -1
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = Wait
  L6_2 = 600
  L5_2(L6_2)
  L5_2 = true
  return L5_2
end
L19_1(L20_1, L21_1)
L19_1 = AddEventHandler
L20_1 = "onResourceStop"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if L1_2 ~= A0_2 then
    return
  end
  L1_2 = L11_1
  if L1_2 then
    L1_2 = pairs
    L2_2 = L9_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = exports
      L7_2 = L7_2.ox_target
      L8_2 = L7_2
      L7_2 = L7_2.removeZone
      L9_2 = L6_2
      L7_2(L8_2, L9_2)
    end
    L1_2 = {}
    L9_1 = L1_2
  end
  L1_2 = pairs
  L2_2 = L3_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = DeleteEntity
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L1_2 = pairs
  L2_2 = L4_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = DeleteEntity
    L8_2 = L6_2
    L7_2(L8_2)
  end
  L1_2 = pairs
  L2_2 = L5_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = DeleteEntity
    L8_2 = L6_2.entity
    L7_2(L8_2)
  end
  L1_2 = updateTextUI
  L2_2 = nil
  L1_2(L2_2)
end
L19_1(L20_1, L21_1)
L19_1 = CreateThread
function L20_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = L15_1
  L0_2()
  L0_2 = createInteractionZones
  L0_2()
  L0_2 = createSpawnPoints
  L0_2()
  L0_2 = registerPropStateHandlers
  L0_2()
  function L0_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = GetInteriorAtCoords
    L3_3 = A0_3.x
    L4_3 = A0_3.y
    L5_3 = A0_3.z
    L2_3 = L2_3(L3_3, L4_3, L5_3)
    if 0 == L2_3 then
      L3_3 = print
      L4_3 = string
      L4_3 = L4_3.format
      L5_3 = "[REPAIR SHOPS] Warning: No interior found at coordinates for location '%s' (%.2f, %.2f, %.2f)"
      L6_3 = A1_3
      L7_3 = A0_3.x
      L8_3 = A0_3.y
      L9_3 = A0_3.z
      L4_3, L5_3, L6_3, L7_3, L8_3, L9_3 = L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
      L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
      L3_3 = false
      return L3_3
    end
    L3_3 = Config
    L3_3 = L3_3.InteriorEntitySets
    L3_3 = L3_3[A1_3]
    if not L3_3 then
      L4_3 = print
      L5_3 = string
      L5_3 = L5_3.format
      L6_3 = "[REPAIR SHOPS] Warning: No entity set configured for location '%s'"
      L7_3 = A1_3
      L5_3, L6_3, L7_3, L8_3, L9_3 = L5_3(L6_3, L7_3)
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
      L4_3 = false
      return L4_3
    end
    L4_3 = ActivateInteriorEntitySet
    L5_3 = L2_3
    L6_3 = L3_3
    L4_3(L5_3, L6_3)
    L4_3 = RefreshInterior
    L5_3 = L2_3
    L4_3(L5_3)
    L4_3 = print
    L5_3 = string
    L5_3 = L5_3.format
    L6_3 = "[REPAIR SHOPS] Successfully activated entity set '%s' for interior %d at location '%s'"
    L7_3 = L3_3
    L8_3 = L2_3
    L9_3 = A1_3
    L5_3, L6_3, L7_3, L8_3, L9_3 = L5_3(L6_3, L7_3, L8_3, L9_3)
    L4_3(L5_3, L6_3, L7_3, L8_3, L9_3)
    L4_3 = true
    return L4_3
  end
  L1_2 = Wait
  L2_2 = 2000
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = pairs
  L3_2 = Config
  L3_2 = L3_2.Props
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.location
    L8_2 = L1_2[L8_2]
    if not L8_2 then
      L8_2 = L7_2.location
      L1_2[L8_2] = true
      L8_2 = L0_2
      L9_2 = L7_2.coords
      L10_2 = L7_2.location
      L8_2(L9_2, L10_2)
    end
  end
  L2_2 = print
  L3_2 = "[REPAIR SHOPS ANIMS] props system initialised"
  L2_2(L3_2)
end
L19_1(L20_1)
