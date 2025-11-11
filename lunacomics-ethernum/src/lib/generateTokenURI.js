// generateTokenURI.js
// Build NFT metadata and return a tokenURI string
// Inputs: { title, description, imageCID, attributes } and options { mode: 'data' | 'ipfs' }
// Output: { tokenURI, metadata, pinned: boolean, cid?: string }

import { uploadToIPFS } from "../utils/ipfs";

function toBase64Unicode(str) {
  // Browser-safe base64 for Unicode strings
  try {
    return btoa(unescape(encodeURIComponent(str)));
  } catch (e) {
    // Fallback for environments with Buffer
    return typeof Buffer !== 'undefined' ? Buffer.from(str, 'utf-8').toString('base64') : '';
  }
}

/**
 * Generate a tokenURI for the NFT.
 * @param {Object} fields
 * @param {string} fields.title
 * @param {string} fields.description
 * @param {string} fields.imageCID - IPFS CID for the image (optional if using direct upload)
 * @param {Array}  fields.attributes - Array of { trait_type, value }
 * @param {Object} options
 * @param {'data'|'ipfs'} [options.mode='data'] - 'data' returns a data:application/json;base64 URI; 'ipfs' tries to pin JSON then returns ipfs://CID
 * @param {File} [options.imageFile] - Optional browser File to upload to IPFS (if provided, overrides imageCID)
 * @returns {Promise<{tokenURI:string, metadata:Object, pinned:boolean, cid?:string, image?:{cid:string,url:string,gateway:string}}>} 
 */
export async function generateTokenURI(fields = {}, options = {}) {
  const { title = '', description = '', imageCID = '', attributes = [] } = fields;
  const { mode = 'data', imageFile } = options;

  // If an image file is provided, try to upload it to IPFS using the existing util
  let imageInfo = null;
  if (imageFile) {
    try {
      imageInfo = await uploadToIPFS(imageFile);
    } catch (e) {
      console.warn('Image upload failed, continuing with provided imageCID if any:', e.message || e);
    }
  }

  const imageURI = imageInfo?.url || (imageCID ? `ipfs://${imageCID}` : '');

  const metadata = {
    name: title || 'OceanManga Photo',
    description: description || 'Minted via LunaComics Ethernum',
    image: imageURI,
    attributes: Array.isArray(attributes) ? attributes : [],
  };

  if (mode === 'ipfs') {
    // Try to pin JSON metadata to IPFS via Pinata if keys exist
    try {
      // Prepare a blob/file like for JSON
      const jsonBlob = new Blob([JSON.stringify(metadata)], { type: 'application/json' });
      const file = new File([jsonBlob], `metadata-${Date.now()}.json`, { type: 'application/json' });
      const result = await uploadToIPFS(file);
      return { tokenURI: result.url, metadata, pinned: true, cid: result.cid, image: imageInfo || undefined };
    } catch (e) {
      console.warn('Metadata pin failed, falling back to data URI:', e.message || e);
      const data = `data:application/json;base64,${toBase64Unicode(JSON.stringify(metadata))}`;
      return { tokenURI: data, metadata, pinned: false, image: imageInfo || undefined };
    }
  }

  // Default: inline data URI (no pinning)
  const data = `data:application/json;base64,${toBase64Unicode(JSON.stringify(metadata))}`;
  return { tokenURI: data, metadata, pinned: false, image: imageInfo || undefined };
}
