const { ethers } = require("hardhat");

async function main() {
  // Deploy contract
  const ReputationManager = await ethers.getContractFactory("SolidarySystemReputationManager3");
  const reputationManager = await ReputationManager.deploy();
  await reputationManager.waitForDeployment();

  // Simulazione: produttore registra un oggetto (giocattolo)
  const barcode = "TOY-2025-0001";
  const pin = "SECRET123";
  const [producer, buyer, thirdParty] = await ethers.getSigners();
  const mintTx = await reputationManager.connect(producer).registerObject(barcode, pin, producer.address);
  const mintReceipt = await mintTx.wait();
  const mintHash = mintReceipt.logs[0].args.mintHash;
  console.log("Oggetto registrato con mintHash:", mintHash);

  // Trasferimento proprietà dal produttore al buyer
  await reputationManager.connect(producer).transferOwnership(mintHash, buyer.address);
  console.log("Proprietà trasferita a buyer:", buyer.address);

  // Buyer aggiorna lo stato dell'oggetto (es. "in uso")
  await reputationManager.connect(buyer).updateObjectStatus(mintHash, "in use");
  console.log("Stato oggetto aggiornato a 'in use'");

  // Terza parte invia messaggio al proprietario
  await reputationManager.connect(thirdParty).sendMessageToOwner(mintHash, "Vorrei acquistare il tuo giocattolo!");
  console.log("Messaggio inviato al proprietario");

  // Buyer dichiara oggetto "riciclato"
  await reputationManager.connect(buyer).updateObjectStatus(mintHash, "recycled");
  console.log("Stato oggetto aggiornato a 'recycled'");

  // Recupera info oggetto
  const info = await reputationManager.getObjectInfo(mintHash);
  console.log("Info oggetto:", info);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
