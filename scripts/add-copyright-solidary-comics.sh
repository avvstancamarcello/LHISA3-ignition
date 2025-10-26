echo "📜 AGGIUNTA COPYRIGHT - Marcello Stanca"
echo "🏛️ Rispettando la tradizione autoriale dell'ecosistema..."

# Backup prima della modifica
cp contracts/creative_cultural/SolidaryComics.sol contracts/creative_cultural/SolidaryComics.sol.backup2

# Aggiunta del copyright dopo la licenza SPDX
sed -i '3i\ ' contracts/creative_cultural/SolidaryComics.sol
sed -i '4i\// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.' contracts/creative_cultural/SolidaryComics.sol
sed -i '5i\// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) gratis conceditur.' contracts/creative_cultural/SolidaryComics.sol
sed -i '6i\// (This smart contract, part of the Solidary System, is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)' contracts/creative_cultural/SolidaryComics.sol
sed -i '7i\ ' contracts/creative_cultural/SolidaryComics.sol

echo "✅ Copyright aggiunto!"
echo "🔍 Verifica:"
head -10 contracts/creative_cultural/SolidaryComics.sol
