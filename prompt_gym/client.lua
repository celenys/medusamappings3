local L0_1, L1_1, L2_1
L0_1 = CreateThread
function L1_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 500
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "gym:requestEntitySets"
  L0_2(L1_2)
end
L0_1(L1_1)
L0_1 = RegisterNetEvent
L1_1 = "gym:openGymSetsMenu"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = table
    L8_2 = L8_2.insert
    L9_2 = L1_2
    L10_2 = {}
    L12_2 = L6_2
    L11_2 = L6_2.sub
    L13_2 = 1
    L14_2 = 1
    L11_2 = L11_2(L12_2, L13_2, L14_2)
    L12_2 = L11_2
    L11_2 = L11_2.upper
    L11_2 = L11_2(L12_2)
    L13_2 = L6_2
    L12_2 = L6_2.sub
    L14_2 = 2
    L12_2 = L12_2(L13_2, L14_2)
    L11_2 = L11_2 .. L12_2
    L10_2.title = L11_2
    L11_2 = "Manage the "
    L12_2 = L6_2
    L13_2 = " entity set"
    L11_2 = L11_2 .. L12_2 .. L13_2
    L10_2.description = L11_2
    L10_2.icon = "cubes"
    L11_2 = "gym_entity_set_"
    L12_2 = L6_2
    L11_2 = L11_2 .. L12_2
    L10_2.menu = L11_2
    L8_2(L9_2, L10_2)
    L8_2 = {}
    L9_2 = pairs
    L10_2 = L7_2
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
      L15_2 = table
      L15_2 = L15_2.insert
      L16_2 = L8_2
      L17_2 = {}
      if L14_2 then
        L18_2 = "Disable"
        if L18_2 then
          goto lbl_51
        end
      end
      L18_2 = "Enable"
      ::lbl_51::
      L19_2 = " "
      L20_2 = L13_2
      L18_2 = L18_2 .. L19_2 .. L20_2
      L17_2.title = L18_2
      if L14_2 then
        L18_2 = "Disable"
        if L18_2 then
          goto lbl_61
        end
      end
      L18_2 = "Enable"
      ::lbl_61::
      L19_2 = " the "
      L20_2 = L13_2
      L21_2 = " entity set"
      L18_2 = L18_2 .. L19_2 .. L20_2 .. L21_2
      L17_2.description = L18_2
      if L14_2 then
        L18_2 = "toggle-on"
        if L18_2 then
          goto lbl_72
        end
      end
      L18_2 = "toggle-off"
      ::lbl_72::
      L17_2.icon = L18_2
      function L18_2()
        local L0_3, L1_3, L2_3, L3_3, L4_3
        L0_3 = lib
        L0_3 = L0_3.callback
        L0_3 = L0_3.await
        L1_3 = "gym:toggleGymEntitySet"
        L2_3 = 300
        L3_3 = {}
        L4_3 = L6_2
        L3_3.location = L4_3
        L4_3 = L13_2
        L3_3.entitySet = L4_3
        L4_3 = L14_2
        L4_3 = not L4_3
        L3_3.enable = L4_3
        L0_3(L1_3, L2_3, L3_3)
      end
      L17_2.onSelect = L18_2
      L17_2._set = L13_2
      L15_2(L16_2, L17_2)
    end
    L9_2 = table
    L9_2 = L9_2.sort
    L10_2 = L8_2
    function L11_2(A0_3, A1_3)
      local L2_3, L3_3
      L2_3 = A0_3._set
      L3_3 = A1_3._set
      L2_3 = L2_3 < L3_3
      return L2_3
    end
    L9_2(L10_2, L11_2)
    L9_2 = lib
    L9_2 = L9_2.registerContext
    L10_2 = {}
    L11_2 = "gym_entity_set_"
    L12_2 = L6_2
    L11_2 = L11_2 .. L12_2
    L10_2.id = L11_2
    L11_2 = "Entity Set: "
    L12_2 = L6_2
    L11_2 = L11_2 .. L12_2
    L10_2.title = L11_2
    L10_2.menu = "gym_entity_sets"
    L10_2.options = L8_2
    L9_2(L10_2)
  end
  L2_2 = table
  L2_2 = L2_2.sort
  L3_2 = L1_2
  function L4_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.title
    L3_3 = A1_3.title
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  L2_2(L3_2, L4_2)
  L2_2 = lib
  L2_2 = L2_2.registerContext
  L3_2 = {}
  L3_2.id = "gym_entity_sets"
  L3_2.title = "Gym Entity Sets"
  L3_2.options = L1_2
  L2_2(L3_2)
  L2_2 = lib
  L2_2 = L2_2.showContext
  L3_2 = "gym_entity_sets"
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNetEvent
L1_1 = "gym:updateGymEntitySets"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = GetInteriorAtCoords
  L2_2 = A0_2.coords
  L2_2 = L2_2.x
  L3_2 = A0_2.coords
  L3_2 = L3_2.y
  L4_2 = A0_2.coords
  L4_2 = L4_2.z
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if L1_2 and 0 ~= L1_2 then
    L2_2 = A0_2.enable
    if L2_2 then
      L2_2 = ActivateInteriorEntitySet
      L3_2 = L1_2
      L4_2 = A0_2.entitySet
      L2_2(L3_2, L4_2)
    else
      L2_2 = DeactivateInteriorEntitySet
      L3_2 = L1_2
      L4_2 = A0_2.entitySet
      L2_2(L3_2, L4_2)
    end
    L2_2 = RefreshInterior
    L3_2 = L1_2
    L2_2(L3_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNetEvent
L1_1 = "gym:syncGymEntitySets"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = GetInteriorAtCoords
    L8_2 = L5_2.x
    L9_2 = L5_2.y
    L10_2 = L5_2.z
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if L7_2 and 0 ~= L7_2 then
      L8_2 = pairs
      L9_2 = L6_2
      L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
      for L12_2, L13_2 in L8_2, L9_2, L10_2, L11_2 do
        if L13_2 then
          L14_2 = ActivateInteriorEntitySet
          L15_2 = L7_2
          L16_2 = L12_2
          L14_2(L15_2, L16_2)
        else
          L14_2 = DeactivateInteriorEntitySet
          L15_2 = L7_2
          L16_2 = L12_2
          L14_2(L15_2, L16_2)
        end
      end
      L8_2 = RefreshInterior
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
end
L0_1(L1_1, L2_1)
