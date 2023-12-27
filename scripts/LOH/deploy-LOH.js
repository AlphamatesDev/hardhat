const { utils } = require("ethers");
const crypto = require( 'crypto' );

async function main() {
    const StandardERC721A = await ethers.getContractFactory("StandardERC721A");
    const standardERC721A = await StandardERC721A.deploy("LIFE OF HEL - Volume 1", "LIFE OF HEL - Volume 1", 1, 3333, "0xe3D2536E9f70215243fD3F1aEF8eEa259BFA83e5", 100);
    await standardERC721A.deployed();
    console.log("StandardERC721A address: ", standardERC721A.address, "LIFE OF HEL - Volume 1", "LIFE OF HEL - Volume 1", 1, 3333, "0xe3D2536E9f70215243fD3F1aEF8eEa259BFA83e5", 100);

    const StandardERC721A1 = await ethers.getContractFactory("StandardERC721A");
    const standardERC721A1 = await StandardERC721A1.deploy("LIFE OF HEL - Reapers", "LOHR", 1, 2000, "0xe3D2536E9f70215243fD3F1aEF8eEa259BFA83e5", 100);
    await standardERC721A1.deployed();
    console.log("StandardERC721A1 address: ", standardERC721A1.address, "LIFE OF HEL - Reapers", "LOHR", 1, 2000, "0xe3D2536E9f70215243fD3F1aEF8eEa259BFA83e5", 100);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });