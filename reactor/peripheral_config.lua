-- Manual mapping for every reactor component.
-- Peripheral numbers do not need to match reactor numbers.
--
-- Create Smart Chutes and Clutches are commonly disabled when powered.
-- The default poweredMeansEnabled = false reflects that behavior.
-- Flip it to true for any control where a redstone signal should mean ON.
return {
    fuelItems = {
        ["create_new_age:nuclear_fuel"] = true
    },

    expectedFuelPerVault = 1024,
    lowFuelPercent = 25,
    criticalFuelPercent = 10,

    reactors = {
        {
            id = "reactor_1",
            label = "Reactor 1",
            enabled = true,
            fuelVault = "create:item_vault_2",

            primaryStressometer = "create_stressometer_1",
            backupStressometer = "create_stressometer_2",
            primarySpeedometer = "create_speedometer_0",
            backupSpeedometer = "create_speedometer_4",

            generatorCoil = {
                label = "Generator Coil",
                clutch = { label = "Generator Coil Clutch", relay = { peripheral = "CHANGE_ME_R1_GENERATOR_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                accumulators = {
                    { label = "Accumulator 01", peripheral = "CHANGE_ME_R1_ACCUMULATOR_01" },
                    { label = "Accumulator 02", peripheral = "CHANGE_ME_R1_ACCUMULATOR_02" },
                    { label = "Accumulator 03", peripheral = "CHANGE_ME_R1_ACCUMULATOR_03" },
                    { label = "Accumulator 04", peripheral = "CHANGE_ME_R1_ACCUMULATOR_04" },
                    { label = "Accumulator 05", peripheral = "CHANGE_ME_R1_ACCUMULATOR_05" },
                    { label = "Accumulator 06", peripheral = "CHANGE_ME_R1_ACCUMULATOR_06" },
                    { label = "Accumulator 07", peripheral = "CHANGE_ME_R1_ACCUMULATOR_07" },
                    { label = "Accumulator 08", peripheral = "CHANGE_ME_R1_ACCUMULATOR_08" },
                    { label = "Accumulator 09", peripheral = "CHANGE_ME_R1_ACCUMULATOR_09" },
                    { label = "Accumulator 10", peripheral = "CHANGE_ME_R1_ACCUMULATOR_10" },
                    { label = "Accumulator 11", peripheral = "CHANGE_ME_R1_ACCUMULATOR_11" },
                    { label = "Accumulator 12", peripheral = "CHANGE_ME_R1_ACCUMULATOR_12" },
                    { label = "Accumulator 13", peripheral = "CHANGE_ME_R1_ACCUMULATOR_13" },
                    { label = "Accumulator 14", peripheral = "CHANGE_ME_R1_ACCUMULATOR_14" },
                    { label = "Accumulator 15", peripheral = "CHANGE_ME_R1_ACCUMULATOR_15" },
                    { label = "Accumulator 16", peripheral = "CHANGE_ME_R1_ACCUMULATOR_16" },
                    { label = "Accumulator 17", peripheral = "CHANGE_ME_R1_ACCUMULATOR_17" },
                    { label = "Accumulator 18", peripheral = "CHANGE_ME_R1_ACCUMULATOR_18" },
                    { label = "Accumulator 19", peripheral = "CHANGE_ME_R1_ACCUMULATOR_19" },
                    { label = "Accumulator 20", peripheral = "CHANGE_ME_R1_ACCUMULATOR_20" }
                }
            },

            fuelChutes = {
                { label = "Rod 1", relay = { peripheral = "redstone_relay_6", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 2", relay = { peripheral = "redstone_relay_7", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 3", relay = { peripheral = "redstone_relay_8", outputSide = "back", poweredMeansEnabled = false } }
            },

            clutches = {
                primary = { label = "Primary Pump", relay = { peripheral = "redstone_relay_1", outputSide = "back", poweredMeansEnabled = false } },
                backup = { label = "Backup Pump", relay = { peripheral = "redstone_relay_2", outputSide = "back", poweredMeansEnabled = false } }
            }
        },
        {
            id = "reactor_2",
            label = "Reactor 2",
            enabled = false,
            fuelVault = "create:item_vault_2",

            primaryStressometer = "Create_Stressometer_3",
            backupStressometer = "Create_Stressometer_4",
            primarySpeedometer = "CHANGE_ME_R2_PRIMARY_SPEEDOMETER",
            backupSpeedometer = "CHANGE_ME_R2_BACKUP_SPEEDOMETER",

            generatorCoil = {
                label = "Generator Coil",
                clutch = { label = "Generator Coil Clutch", relay = { peripheral = "CHANGE_ME_R2_GENERATOR_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                accumulators = {
                    { label = "Accumulator 01", peripheral = "CHANGE_ME_R2_ACCUMULATOR_01" },
                    { label = "Accumulator 02", peripheral = "CHANGE_ME_R2_ACCUMULATOR_02" },
                    { label = "Accumulator 03", peripheral = "CHANGE_ME_R2_ACCUMULATOR_03" },
                    { label = "Accumulator 04", peripheral = "CHANGE_ME_R2_ACCUMULATOR_04" },
                    { label = "Accumulator 05", peripheral = "CHANGE_ME_R2_ACCUMULATOR_05" },
                    { label = "Accumulator 06", peripheral = "CHANGE_ME_R2_ACCUMULATOR_06" },
                    { label = "Accumulator 07", peripheral = "CHANGE_ME_R2_ACCUMULATOR_07" },
                    { label = "Accumulator 08", peripheral = "CHANGE_ME_R2_ACCUMULATOR_08" },
                    { label = "Accumulator 09", peripheral = "CHANGE_ME_R2_ACCUMULATOR_09" },
                    { label = "Accumulator 10", peripheral = "CHANGE_ME_R2_ACCUMULATOR_10" },
                    { label = "Accumulator 11", peripheral = "CHANGE_ME_R2_ACCUMULATOR_11" },
                    { label = "Accumulator 12", peripheral = "CHANGE_ME_R2_ACCUMULATOR_12" },
                    { label = "Accumulator 13", peripheral = "CHANGE_ME_R2_ACCUMULATOR_13" },
                    { label = "Accumulator 14", peripheral = "CHANGE_ME_R2_ACCUMULATOR_14" },
                    { label = "Accumulator 15", peripheral = "CHANGE_ME_R2_ACCUMULATOR_15" },
                    { label = "Accumulator 16", peripheral = "CHANGE_ME_R2_ACCUMULATOR_16" },
                    { label = "Accumulator 17", peripheral = "CHANGE_ME_R2_ACCUMULATOR_17" },
                    { label = "Accumulator 18", peripheral = "CHANGE_ME_R2_ACCUMULATOR_18" },
                    { label = "Accumulator 19", peripheral = "CHANGE_ME_R2_ACCUMULATOR_19" },
                    { label = "Accumulator 20", peripheral = "CHANGE_ME_R2_ACCUMULATOR_20" }
                }
            },

            fuelChutes = {
                { label = "Rod 1", relay = { peripheral = "CHANGE_ME_R2_CHUTE_1_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 2", relay = { peripheral = "CHANGE_ME_R2_CHUTE_2_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 3", relay = { peripheral = "CHANGE_ME_R2_CHUTE_3_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            },

            clutches = {
                primary = { label = "Primary Pump", relay = { peripheral = "CHANGE_ME_R2_PRIMARY_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                backup = { label = "Backup Pump", relay = { peripheral = "CHANGE_ME_R2_BACKUP_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            }
        },
        {
            id = "reactor_3",
            label = "Reactor 3",
            enabled = false,
            fuelVault = "create:item_vault_3",

            primaryStressometer = "Create_Stressometer_5",
            backupStressometer = "Create_Stressometer_6",
            primarySpeedometer = "CHANGE_ME_R3_PRIMARY_SPEEDOMETER",
            backupSpeedometer = "CHANGE_ME_R3_BACKUP_SPEEDOMETER",

            generatorCoil = {
                label = "Generator Coil",
                clutch = { label = "Generator Coil Clutch", relay = { peripheral = "CHANGE_ME_R3_GENERATOR_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                accumulators = {
                    { label = "Accumulator 01", peripheral = "CHANGE_ME_R3_ACCUMULATOR_01" },
                    { label = "Accumulator 02", peripheral = "CHANGE_ME_R3_ACCUMULATOR_02" },
                    { label = "Accumulator 03", peripheral = "CHANGE_ME_R3_ACCUMULATOR_03" },
                    { label = "Accumulator 04", peripheral = "CHANGE_ME_R3_ACCUMULATOR_04" },
                    { label = "Accumulator 05", peripheral = "CHANGE_ME_R3_ACCUMULATOR_05" },
                    { label = "Accumulator 06", peripheral = "CHANGE_ME_R3_ACCUMULATOR_06" },
                    { label = "Accumulator 07", peripheral = "CHANGE_ME_R3_ACCUMULATOR_07" },
                    { label = "Accumulator 08", peripheral = "CHANGE_ME_R3_ACCUMULATOR_08" },
                    { label = "Accumulator 09", peripheral = "CHANGE_ME_R3_ACCUMULATOR_09" },
                    { label = "Accumulator 10", peripheral = "CHANGE_ME_R3_ACCUMULATOR_10" },
                    { label = "Accumulator 11", peripheral = "CHANGE_ME_R3_ACCUMULATOR_11" },
                    { label = "Accumulator 12", peripheral = "CHANGE_ME_R3_ACCUMULATOR_12" },
                    { label = "Accumulator 13", peripheral = "CHANGE_ME_R3_ACCUMULATOR_13" },
                    { label = "Accumulator 14", peripheral = "CHANGE_ME_R3_ACCUMULATOR_14" },
                    { label = "Accumulator 15", peripheral = "CHANGE_ME_R3_ACCUMULATOR_15" },
                    { label = "Accumulator 16", peripheral = "CHANGE_ME_R3_ACCUMULATOR_16" },
                    { label = "Accumulator 17", peripheral = "CHANGE_ME_R3_ACCUMULATOR_17" },
                    { label = "Accumulator 18", peripheral = "CHANGE_ME_R3_ACCUMULATOR_18" },
                    { label = "Accumulator 19", peripheral = "CHANGE_ME_R3_ACCUMULATOR_19" },
                    { label = "Accumulator 20", peripheral = "CHANGE_ME_R3_ACCUMULATOR_20" }
                }
            },

            fuelChutes = {
                { label = "Rod 1", relay = { peripheral = "CHANGE_ME_R3_CHUTE_1_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 2", relay = { peripheral = "CHANGE_ME_R3_CHUTE_2_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 3", relay = { peripheral = "CHANGE_ME_R3_CHUTE_3_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            },

            clutches = {
                primary = { label = "Primary Pump", relay = { peripheral = "CHANGE_ME_R3_PRIMARY_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                backup = { label = "Backup Pump", relay = { peripheral = "CHANGE_ME_R3_BACKUP_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            }
        },
        {
            id = "reactor_4",
            label = "Reactor 4",
            enabled = false,
            fuelVault = "create:item_vault_4",

            primaryStressometer = "Create_Stressometer_7",
            backupStressometer = "Create_Stressometer_8",
            primarySpeedometer = "CHANGE_ME_R4_PRIMARY_SPEEDOMETER",
            backupSpeedometer = "CHANGE_ME_R4_BACKUP_SPEEDOMETER",

            generatorCoil = {
                label = "Generator Coil",
                clutch = { label = "Generator Coil Clutch", relay = { peripheral = "CHANGE_ME_R4_GENERATOR_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                accumulators = {
                    { label = "Accumulator 01", peripheral = "CHANGE_ME_R4_ACCUMULATOR_01" },
                    { label = "Accumulator 02", peripheral = "CHANGE_ME_R4_ACCUMULATOR_02" },
                    { label = "Accumulator 03", peripheral = "CHANGE_ME_R4_ACCUMULATOR_03" },
                    { label = "Accumulator 04", peripheral = "CHANGE_ME_R4_ACCUMULATOR_04" },
                    { label = "Accumulator 05", peripheral = "CHANGE_ME_R4_ACCUMULATOR_05" },
                    { label = "Accumulator 06", peripheral = "CHANGE_ME_R4_ACCUMULATOR_06" },
                    { label = "Accumulator 07", peripheral = "CHANGE_ME_R4_ACCUMULATOR_07" },
                    { label = "Accumulator 08", peripheral = "CHANGE_ME_R4_ACCUMULATOR_08" },
                    { label = "Accumulator 09", peripheral = "CHANGE_ME_R4_ACCUMULATOR_09" },
                    { label = "Accumulator 10", peripheral = "CHANGE_ME_R4_ACCUMULATOR_10" },
                    { label = "Accumulator 11", peripheral = "CHANGE_ME_R4_ACCUMULATOR_11" },
                    { label = "Accumulator 12", peripheral = "CHANGE_ME_R4_ACCUMULATOR_12" },
                    { label = "Accumulator 13", peripheral = "CHANGE_ME_R4_ACCUMULATOR_13" },
                    { label = "Accumulator 14", peripheral = "CHANGE_ME_R4_ACCUMULATOR_14" },
                    { label = "Accumulator 15", peripheral = "CHANGE_ME_R4_ACCUMULATOR_15" },
                    { label = "Accumulator 16", peripheral = "CHANGE_ME_R4_ACCUMULATOR_16" },
                    { label = "Accumulator 17", peripheral = "CHANGE_ME_R4_ACCUMULATOR_17" },
                    { label = "Accumulator 18", peripheral = "CHANGE_ME_R4_ACCUMULATOR_18" },
                    { label = "Accumulator 19", peripheral = "CHANGE_ME_R4_ACCUMULATOR_19" },
                    { label = "Accumulator 20", peripheral = "CHANGE_ME_R4_ACCUMULATOR_20" }
                }
            },

            fuelChutes = {
                { label = "Rod 1", relay = { peripheral = "CHANGE_ME_R4_CHUTE_1_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 2", relay = { peripheral = "CHANGE_ME_R4_CHUTE_2_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                { label = "Rod 3", relay = { peripheral = "CHANGE_ME_R4_CHUTE_3_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            },

            clutches = {
                primary = { label = "Primary Pump", relay = { peripheral = "CHANGE_ME_R4_PRIMARY_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } },
                backup = { label = "Backup Pump", relay = { peripheral = "CHANGE_ME_R4_BACKUP_CLUTCH_RELAY", outputSide = "back", poweredMeansEnabled = false } }
            }
        }
    }
}
