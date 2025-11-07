# Documentazione Test: FTConversionManager

## Obiettivo
Verificare la correttezza e la robustezza delle funzioni di conversione, notifica e gestione storica dei token FT.

## Test implementati

1. **Rate Alert**
   - Verifica che l’utente possa impostare una soglia di tasso di conversione (`setRateAlert`).
   - Simula un cambio di tasso tramite il mock oracle.
   - Controlla che venga emesso l’evento `RateAlertTriggered` quando il tasso supera la soglia.

2. **Conversione tra FT token e storico**
   - Simula la conversione tra due token FT mock.
   - Verifica che la conversione venga registrata nello storico (`userConversionHistory`).
   - Controlla che l’evento `FTConverted` venga emesso.

3. **Notifica mint FT e simulazione conversione**
   - Simula la notifica di mint di nuovi FT (`notifyFTMint`).
   - Richiede una simulazione di conversione (`getConversionQuote`) e verifica che il tasso restituito corrisponda a quello dell’oracolo.
   - Usa `.staticCall` per estrarre correttamente i valori restituiti dalla funzione Solidity.

## Conferma superamento test

Tutti i test sono stati eseguiti con successo:
- Output: `3 passing`
- Nessun errore o warning residuo.
- La logica di conversione, notifica e storico è verificata e funzionante nella forma attuale.
