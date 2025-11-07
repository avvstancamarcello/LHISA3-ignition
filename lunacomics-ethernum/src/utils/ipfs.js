// IPFS Upload utility using Pinata
export const uploadToIPFS = async (file) => {
  const pinataApiKey = import.meta.env.VITE_PINATA_API_KEY;
  const pinataSecretKey = import.meta.env.VITE_PINATA_SECRET_KEY;

  if (!pinataApiKey || !pinataSecretKey) {
    throw new Error('Pinata API keys not configured');
  }

  const formData = new FormData();
  formData.append('file', file);

  const metadata = JSON.stringify({
    name: `OceanManga-${Date.now()}`,
    keyvalues: {
      type: 'photo',
      mintedBy: 'LunaComics-Ethernum'
    }
  });
  formData.append('pinataMetadata', metadata);

  const options = JSON.stringify({
    cidVersion: 0,
  });
  formData.append('pinataOptions', options);

  try {
    const response = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
      method: 'POST',
      headers: {
        'pinata_api_key': pinataApiKey,
        'pinata_secret_api_key': pinataSecretKey,
      },
      body: formData,
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error || 'Failed to upload to IPFS');
    }

    return {
      cid: result.IpfsHash,
      url: `ipfs://${result.IpfsHash}`,
      gateway: `https://gateway.pinata.cloud/ipfs/${result.IpfsHash}`
    };
  } catch (error) {
    console.error('IPFS upload error:', error);
    throw error;
  }
};