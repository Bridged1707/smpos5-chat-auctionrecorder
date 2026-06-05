return {
    refreshRate = 1,
    warningPercent = 85,
    criticalPercent = 95,

    graphDefaults = {
        sampleSeconds = 30,
        historyPoints = 120
    },

    outputs = {
        stress_full = {
            enabled = true,
            monitor = "monitor_4",
            textScale = 0.5
        },

        reactor_fuel = {
            enabled = true,
            monitor = "monitor_6",
            textScale = 0.5
        },


        accumulators = {
            enabled = false,
            monitor = "monitor_7",
            textScale = 0.5
        },

        reactor_fuel_graph = {
            enabled = false,
            monitor = "monitor_5",
            textScale = 0.5,
            sampleSeconds = 30,
            historyPoints = 120
        },

        stress_graph = {
            enabled = true,
            monitor = "monitor_5",
            textScale = 0.5,
            sampleSeconds = 30,
            historyPoints = 120
        },

        speed_graph = {
            enabled = false,
            monitor = "monitor_6",
            textScale = 0.5,
            sampleSeconds = 30,
            historyPoints = 120
        }
    }
}
