<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/ContractLabs/template-foundry">
    <img src="https://avatars.githubusercontent.com/u/99892494?s=200&v=4" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">Foundry custom template</h3>

  <p align="center">
    <br />
    <br />
    <a href="https://github.com/github_username/repo_name/issues">Report Bug</a>
    ·
    <a href="https://github.com/github_username/repo_name/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project
A Foundry-custom template for developing Solidity smart contracts, with base script use for deploy, upgrade contract.


<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

* Install foundry
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  ```
* More details at: [Foundry installation](https://book.getfoundry.sh/getting-started/installation) 
* Shell recommended: Bash
### Installation

1. Clone the repo
   ```bash
   git clone https://github.com/ContractLabs/template-foundry.git
   ```
2. Install dependencies packages
   ```bash
   sh sh/setup.sh
   ```
   or
   ```bash
   forge install
   ```
4. Remappings
   ```bash
   forge remappings > remappings.txt
   ```
   Note: After remappings remember change import path in BaseScript follow your remappings.
<!-- USAGE EXAMPLES -->
## Usage

Use for deploy or upgrade contract. Currently only support 2 type of proxy, UUPS and Transparent.

1. Example
   ```Solidity
   contract CounterScript is BaseScript {
       function run() public {
          vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
          address deployment = _deployRaw("ERC20", abi.encodeCall(ERC20.initialize, "TokenName", "TokenSymbol"));
          vm.stopBroadcast();
       }
   }
   ```
2. Dependencies packages recommended 
   ```bash
   forge install --no-commit vectorized/solady
   forge install --no-commit PaulRBerg/prb-math
   forge install --no-commit foundry-rs/forge-std
   forge install --no-commit transmissions11/solmate
   forge install --no-commit openzeppelin/openzeppelin-contracts
   forge install --no-commit openzeppelin/openzeppelin-contracts-upgradeable
   ```
3. Script run guide
   
   Don't forget run this command first
   ```bash
   source .env
   ```
   Run script command:
   ```bash
   forge script script/<script file name>.s.sol --rpc-url $<CHAIN-RPC-URL> --etherscan-api-key $<YOUR-API-KEY> --broadcast --verify --legacy --ffi -vvvv
   ```
4. Note
   
   Must include option ```--ffi``` in your command run script.
   
   Must override ```admin()``` function in your script.
   ```Solidity
   function admin() public view override returns (address) {
      return vm.addr(vm.envUint("YOUR_PRIVATE_KEY"));
   }
   ```
   Must override ```contractFile()``` function if your contract file name and contract name is mismatch.
   ```Solidity
   function contractFile() public view override returns (string memory) {
      return "ERC20.sol";
   }
   ```
   If you have this error ```File import callback not supported```. Try import this configuration to .vscode/settings.json
   ```json
    "[solidity]": {
      "editor.formatOnSave": true,
    },

    "solidity.formatter": "forge",
    "solidity.compileUsingRemoteVersion": "v0.8.20+commit.a1b79de6",
    "solidity.packageDefaultDependenciesContractsDirectory": "src",
    "solidity.packageDefaultDependenciesDirectory": "lib",
   ```
   

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- CONTACT -->
## Contact

tasibii - [@telegram](https://t.me/tasiby) - [@email](mailto:tuanhawork@gmail.com) - [@github](https://github.com/tasibii)


<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Solidity](https://soliditylang.org/)
* [Foundry](https://book.getfoundry.sh/)
* [Bash]()

[Foundry.com]: https://avatars.githubusercontent.com/u/99892494?s=200&v=4
[Foundry-url]: https://getfoundry.sh/
