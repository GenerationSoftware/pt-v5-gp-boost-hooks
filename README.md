# Grand Prize Boost Hooks

This repo contains multiple GP boost hooks that can be used to inject value into a prize pool with the goal of increasing the value of the grand prize.

## GpBoostHookConstantRate

The "contstant rate" GP boost hook is a modified version of the legacy hook that is used in conjunction with a vault booster to inject a constant stream of value into the prize pool while feeding any non-GP wins back into the vault booster reserves to continue the injections for a longer period while avoiding sudden fluctuations in prize pool contributions. This modification results in a more drawn-out injection that minimizes the impact on the win experience for users of the protocol.

### Deployments

| Network      | Address                                                                                                                            |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
|      |  |

## GpBoostHook (legacy)

The code for this hook was previously found in the [builder code examples repo](https://github.com/GenerationSoftware/pt-v5-builder-code-examples/tree/main/src/prize-hooks/examples/gp-booster), but has now been moved to this dedicated repo for further development.

The legacy hook uses both hook calls to redirect all prizes won (except the GP) back to the prize pool and contribute them on behalf of this "vault", creating a continuous loop of contributions until this vault's chance slowly fades. The end result of this hook is to contribute as much capital as possible to the GP without creating a game-able opportunity.

### Deployments

| Network      | Address                                                                                                                            |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Optimism     | [`0xdEef914A2Ee2f2014cE401dCb4e13f6540d20bA7`](https://optimistic.etherscan.io/address/0xdeef914a2ee2f2014ce401dcb4e13f6540d20ba7) |
| Base         | [`0x327B2Ea9668a552fe5DEC8e3c6e47E540A0A58c6`](https://basescan.org/address/0x327b2ea9668a552fe5dec8e3c6e47e540a0a58c6)            |
| Arbitrum One | [`0x1DcFb8b47C2F05Ce86C21580C167485De1202e12`](https://arbiscan.io/address/0x1dcfb8b47c2f05ce86c21580c167485de1202e12)             |
| Ethereum     | [`0x6bE9C23AA3C2cfEFf92d884E20D1Ec9E134aB076`](https://etherscan.io/address/0x6be9c23aa3c2cfeff92d884e20d1ec9e134ab076)            |
| Gnosis       | [`0x65F3AEa2594D82024B7Ee98DDcF08F991Ab1c626`](https://gnosisscan.io/address/0x65f3aea2594d82024b7ee98ddcf08f991ab1c626)           |
| Scroll       | [`0x2D3ad415198D7156e8c112A508b8306699f6E4cC`](https://scrollscan.com/address/0x2d3ad415198d7156e8c112a508b8306699f6e4cc)          |

## Getting started

The easiest way to get started is by clicking the [Use this template](https://github.com/GenerationSoftware/foundry-template/generate) button at the top right of this page.

If you prefer to go the CLI way:

```
forge init my-project --template https://github.com/GenerationSoftware/foundry-template
```

## Development

### Installation

You may have to install the following tools to use this repository:

- [Foundry](https://github.com/foundry-rs/foundry) to compile and test contracts
- [direnv](https://direnv.net/) to handle environment variables
- [lcov](https://github.com/linux-test-project/lcov) to generate the code coverage report

Install dependencies:

```
npm i
```

### Env

Copy `.envrc.example` and write down the env variables needed to run this project.

```
cp .envrc.example .envrc
```

Once your env variables are setup, load them with:

```
direnv allow
```

### Compile

Run the following command to compile the contracts:

```
npm run compile
```

### Coverage

Forge is used for coverage, run it with:

```
npm run coverage
```

You can then consult the report by opening `coverage/index.html`:

```
open coverage/index.html
```

### Code quality

[Husky](https://typicode.github.io/husky/#/) is used to run [lint-staged](https://github.com/okonet/lint-staged) and tests when committing.

[Prettier](https://prettier.io) is used to format TypeScript and Solidity code. Use it by running:

```
npm run format
```

[Solhint](https://protofire.github.io/solhint/) is used to lint Solidity files. Run it with:

```
npm run hint
```

### CI

A default Github Actions workflow is setup to execute on push and pull request.

It will build the contracts and run the test coverage.

You can modify it here: [.github/workflows/coverage.yml](.github/workflows/coverage.yml)

For the coverage to work, you will need to setup the `MAINNET_RPC_URL` repository secret in the settings of your Github repository.
