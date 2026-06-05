# Create: New Age Reactor Monitor and Control

## Configure peripherals

Edit `peripheral_config.lua`. Every reactor explicitly maps its item vault, two Stressometers, two Speedometers, three Smart Chute relays, and two Clutch relays.

For each relay, set `outputSide` to the relay side facing the controlled block.

The default `poweredMeansEnabled = false` assumes a powered Smart Chute or Clutch is disabled. Set it to `true` for any device where redstone power should mean enabled.

## Commands

```text
reactorctl status [reactor|all]
reactorctl fuel <reactor|all> <on|off>
reactorctl chute <reactor|all> <1|2|3|all> <on|off>
reactorctl clutch <reactor|all> <primary|backup|all> <on|off>
reactorctl safeoff <reactor|all>
```

Examples:

```text
reactorctl status all
reactorctl fuel 1 off
reactorctl chute 2 3 on
reactorctl clutch all backup off
reactorctl safeoff 4
```

## Dashboards

- `stress.lua` shows primary/backup clutch state, used SU, capacity, and RPM.
- `reactor_fuel.lua` shows item vault fuel and how many of the three fuel chutes are enabled.
- `reactor_fuel_graph.lua` graphs vault fuel history.
- `stress_graph.lua` graphs primary/backup used SU history.
- `speed_graph.lua` graphs primary/backup RPM history.

## Generator coil / modular accumulator support

Each reactor can now define one `generatorCoil` block in `peripheral_config.lua`.
The coil has:

- one clutch relay for enabling/disabling the generator coil rotation path
- up to 20 modular accumulator peripherals

Commands:

```sh
reactorctl coil 1 on
reactorctl coil 1 off
reactorctl clutch 1 generator on
reactorctl clutch 1 generator off
reactorctl status 1
```

Diagnostics:

```sh
check_accumulators
```

Display program:

```sh
accumulators
```

Enable the `accumulators` output in `monitor_config.lua` and set it to the monitor you want.

If the accumulator screen says `NO ENERGY API`, the accumulator blocks are visible on the modem network, but their mod does not expose readable energy methods to CC:Tweaked. In that case the scripts can still control the generator coil clutch, but cannot read stored energy from the accumulator bank.
