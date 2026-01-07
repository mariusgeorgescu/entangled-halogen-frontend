// FFI module for mounting the DexHunter React swap widget
import React from 'react';
import { createRoot } from 'react-dom/client';
import Swap from '@dexhunterio/swaps';
import '@dexhunterio/swaps/lib/assets/style.css';

// Store for managing React roots
const roots = new Map();

// Hide the Connect Wallet button when no wallet is connected
// Users should use the navbar's Connect button instead
const hideConnectWalletButton = (containerId) => {
  setTimeout(() => {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    // Find buttons containing "Connect Wallet" text
    const buttons = container.querySelectorAll('button');
    buttons.forEach(btn => {
      if (btn.textContent?.includes('Connect Wallet')) {
        btn.style.display = 'none';
        console.log('DexHunter: Hid Connect Wallet button');
      }
    });
  }, 100); // Small delay to ensure React has rendered
};

// Mount the DexHunter swap widget to a container element
export const mountDexHunterSwapImpl = (containerId) => (config) => () => {
  console.log('DexHunter: Mounting widget WITHOUT wallet');
  
  const container = document.getElementById(containerId);
  if (!container) {
    console.error('DexHunter: Container element not found:', containerId);
    return;
  }

  // Clean up existing root if any
  if (roots.has(containerId)) {
    roots.get(containerId).unmount();
    roots.delete(containerId);
  }
  
  // Clear the container to ensure fresh React mount
  container.innerHTML = '';

  const root = createRoot(container);
  roots.set(containerId, root);

  // Colors aligned with daisyUI dim theme
  const dimThemeColors = {
    background: "#2A303C",   // base-100
    containers: "#242933",   // base-200
    subText: "#A6ADBA",      // base-content muted
    mainText: "#B8C5D3",     // base-content
    buttonText: "#1D232A",   // neutral
    accent: "#9FE88D"        // primary (green)
  };

  root.render(
    React.createElement(Swap, {
      key: 'wallet-disconnected',
      partnerName: 'e7d',
      partnerCode: 'e7d616464723171396c34687765376338613061677166767879717266717066366174636467303775386d72666e326c74686c366a6b7166783232767a776a70797a637a356d386a7a36303367676c753564753563726372646d71686a7a6c39637473326a38383532da39a3ee5e6b4b0d3255bfef95601890afd80709',
      defaultTokenIn: config.defaultTokenIn || '',
      defaultTokenOut: '0691b2fecca1ac4f53cb6dfb00b7013e561d1f34403b957cbb5af1fa4e49474854',
      orderTypes: ['SWAP', 'LIMIT', 'DCA'],
      theme: 'dark',
      colors: dimThemeColors,
      width: config.width || 400,
      showChart: true,
      showOrders: true,
      getWalletAddress: null,
      getWalletUtxos: null,
      signTx: null,
      submitTx: null,
      onTxSubmitted: null,
    })
  );
  
  // Hide the Connect Wallet button - users should use navbar
  hideConnectWalletButton(containerId);
};

// Unmount the DexHunter swap widget from a container
export const unmountDexHunterSwapImpl = (containerId) => () => {
  if (roots.has(containerId)) {
    roots.get(containerId).unmount();
    roots.delete(containerId);
  }
};

// Mount with wallet API integration
export const mountDexHunterWithWalletImpl = (containerId) => (config) => (walletApi) => (walletName) => () => {
  console.log('DexHunter: Mounting widget with wallet:', walletApi ? 'connected' : 'not connected', 'name:', walletName);
  
  const container = document.getElementById(containerId);
  if (!container) {
    console.error('DexHunter: Container element not found:', containerId);
    return;
  }

  // Clean up existing root if any
  if (roots.has(containerId)) {
    console.log('DexHunter: Unmounting existing widget');
    roots.get(containerId).unmount();
    roots.delete(containerId);
  }
  
  // Clear the container to ensure fresh React mount
  container.innerHTML = '';

  const root = createRoot(container);
  roots.set(containerId, root);

  // Create wallet callback functions using CIP-30 API
  const walletCallbacks = walletApi ? {
    getWalletAddress: async () => {
      console.log('DexHunter: getWalletAddress called');
      try {
        const addresses = await walletApi.getUsedAddresses();
        const address = addresses[0] || await walletApi.getUnusedAddresses().then(a => a[0]);
        console.log('DexHunter: Wallet address:', address);
        return address;
      } catch (e) {
        console.error('DexHunter: Failed to get wallet address', e);
        return null;
      }
    },
    getWalletUtxos: async () => {
      console.log('DexHunter: getWalletUtxos called');
      try {
        const utxos = await walletApi.getUtxos();
        console.log('DexHunter: UTXOs count:', utxos?.length);
        return utxos;
      } catch (e) {
        console.error('DexHunter: Failed to get wallet UTXOs', e);
        return [];
      }
    },
    signTx: async (tx) => {
      console.log('DexHunter: signTx called');
      try {
        return await walletApi.signTx(tx, true);
      } catch (e) {
        console.error('DexHunter: Failed to sign transaction', e);
        throw e;
      }
    },
    submitTx: async (tx) => {
      console.log('DexHunter: submitTx called');
      try {
        return await walletApi.submitTx(tx);
      } catch (e) {
        console.error('DexHunter: Failed to submit transaction', e);
        throw e;
      }
    },
  } : {};

  console.log('DexHunter: Wallet callbacks:', Object.keys(walletCallbacks));
  console.log('DexHunter: selectedWallet:', walletName);

  // Use a unique key to force React to recreate the component when wallet state changes
  const widgetKey = walletApi ? 'wallet-connected-' + Date.now() : 'wallet-disconnected';
  
  // Normalize wallet name to lowercase for DexHunter (e.g., "Nami" -> "nami")
  const selectedWalletName = walletName ? walletName.toLowerCase() : undefined;

  // Colors aligned with daisyUI dim theme
  const dimThemeColors = {
    background: "#2A303C",   // base-100
    containers: "#242933",   // base-200
    subText: "#A6ADBA",      // base-content muted
    mainText: "#B8C5D3",     // base-content
    buttonText: "#1D232A",   // neutral
    accent: "#9FE88D"        // primary (green)
  };

  root.render(
    React.createElement(Swap, {
      key: widgetKey,
      partnerName: 'e7d',
      partnerCode: 'e7d616464723171396c34687765376338613061677166767879717266717066366174636467303775386d72666e326c74686c366a6b7166783232767a776a70797a637a356d386a7a36303367676c753564753563726372646d71686a7a6c39637473326a38383532da39a3ee5e6b4b0d3255bfef95601890afd80709',
      defaultTokenIn: config.defaultTokenIn || '',
      defaultTokenOut: '0691b2fecca1ac4f53cb6dfb00b7013e561d1f34403b957cbb5af1fa4e49474854',
      orderTypes: ['SWAP', 'LIMIT', 'DCA'],
      theme: 'dark',
      colors: dimThemeColors,
      width: config.width || 400,
      showChart: true,
      showOrders: true,
      selectedWallet: selectedWalletName,
      ...walletCallbacks,
      onClickWalletConnect: () => {
        console.log('DexHunter: User clicked internal connect button');
      },
      onWalletConnect: (data) => {
        console.log('DexHunter: Wallet connected via widget:', data);
      },
      onTxSubmitted: (txHash) => {
        console.log('DexHunter: Transaction submitted:', txHash);
        if (config.onTxSubmitted) config.onTxSubmitted(txHash)();
      },
    })
  );
  
  console.log('DexHunter: Widget mounted successfully');
};



