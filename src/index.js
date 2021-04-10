const thetajs = require("@thetalabs/theta-js");
const contracts = require("./contracts.json");

// Sets the THETA network & provider.
const chainId = thetajs.networks.ChainIds.Privatenet;
const provider = new thetajs.providers.HttpProvider(chainId);

// Generates all of the smart contracts in the node modules.
contracts.smart_contracts.forEach(sc => {
    try {
        let builtSC = require("../build/contracts/" + sc + ".json");
        let ABIToDeploy = JSON.stringify(builtSC.abi);
        let byteCodeToDeploy = {
            "linkReferences": builtSC.immutableReferences,
            "object": builtSC.deployedBytecode,
            "opcodes": "lmao",
            "sourceMap": builtSC.deployedSourceMap
        }
        console.log(ABIToDeploy);
    } catch (e) {
        console.error("Error with importing " + sc + ". " + e);
    }
});

console.log("brug");