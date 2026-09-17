# nix-config

Declarative NixOS + home-manager configuration, managed as a flake.

## Layout

```text
flake.nix                          # defines nixosConfigurations.<host>
flake.lock                         # pinned nixpkgs, committed

hosts/
└── laptop/
    ├── configuration.nix          # host entrypoint
    └── hardware-configuration.nix # untouched nixos-generate-config output, never shared

modules/
└── nixos/                         # concern-scoped, host-agnostic settings
    └── README.md                  # what each module owns
```

## Building

```sh
nix flake check
sudo nixos-rebuild dry-activate --flake .#laptop
```

## Adding a host

Add `hosts/<name>/` with its own `hardware-configuration.nix` and `configuration.nix`, then
import whichever `modules/nixos/*.nix` files it needs. Only add a new `nixosConfigurations`
output in `flake.nix` once that host actually exists — see the constitution's Simplicity
principle for why this repo avoids building multi-host abstractions ahead of a second host.

See `.specify/memory/constitution.md` for the principles this repo follows.
