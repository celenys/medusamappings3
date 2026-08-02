local L0_1, L1_1, L2_1
L0_1 = RegisterNetEvent
L1_1 = "prompt_hornys:despawnSandyMLO"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "prompt_hornys:despawnSandyMLO"
function L2_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = GetInteriorAtCoords
  L1_2 = 1864.11328
  L2_2 = 3748.07275
  L3_2 = 32.05642
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  L1_2 = RemoveIpl
  L2_2 = "lr_cs4_10_interior_v_tattoo2_milo_"
  L1_2(L2_2)
  L1_2 = DisableInterior
  L2_2 = L0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = RefreshInterior
  L2_2 = L0_2
  L1_2(L2_2)
end
L0_1(L1_1, L2_1)
