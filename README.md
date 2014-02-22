# Second Contract

This is a Ruby-based text MUD game driver in the spirit of DGD/LPC-based
MUDs and based on much of the design work behind the LPC-based game in 
[the other Second Contract repository](https://github.com/jgsmith/second-contract).

## Configuring the game

Game configuration is in `config/game.yml`. The `production`, `development`,
and `testing` sections contain settings for those particular environments.
The `all` section contains settings applicable in all environments.

## Test the game

Test the game by running

```bash
% rake
```

This should run all of the unit and behavioral tests. If any tests fail, you
shouldn't expect the game to run without problems.

## Running the game

Run the game with

```bash
./driver
```

You can select an environment with the `--environment` switch. By default,
the driver will use the `production` environment.


## Directory Organization

The various Ruby classes and modules are organized roughly following the
scheme established in the DGD Kernel library:

- SecondContract::IFLib - classes dealing with the interactive fiction component
 -- Data:: - simple data-oriented classes
 -- Sys:: - singleton classes providing services
