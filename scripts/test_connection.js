#!/usr/bin/env node
/**
 * test_connection.js
 *
 * Modalità:
 *  - Server: `node scripts/test_connection.js --server`
 *      Avvia:
 *        • HTTP streaming (chunked/SSE-like) su /stream
 *        • WebSocket echo su /ws
 *
 *  - Client: `node scripts/test_connection.js`
 *      Esegue test verso:
 *        • WebSocket (URL da env WS_URL o ws://localhost:7070/ws)
 *        • HTTP streaming (URL da env STREAM_URL o http://localhost:7070/stream)
 *      Se il test WS locale fallisce, prova un endpoint pubblico: wss://echo.websocket.events
 *
 * Env utili:
 *  PORT=7070
 *  WS_URL=wss://...
 *  STREAM_URL=http://...
 *  DURATION_MS=30000
 */

const http = require("http");
const express = require("express");
const WebSocket = require("ws");

const args = process.argv.slice(2);
const IS_SERVER = args.includes("--server");

const PORT = parseInt(process.env.PORT || "7070", 10);
const DURATION_MS = parseInt(process.env.DURATION_MS || "30000", 10);

async function startServer() {
  const app = express();

  // HTTP streaming “chunked” (stile SSE semplice)
  app.get("/stream", (req, res) => {
    res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
    res.setHeader("Cache-Control", "no-cache, no-transform");
    res.setHeader("Connection", "keep-alive");
    // Nota: niente CORS qui; per test locale non serve. Aggiungi se ti serve dal browser.

    let i = 0;
    const start = Date.now();
    const timer = setInterval(() => {
      i++;
      const elapsed = Date.now() - start;
      res.write(`data: chunk #${i}, elapsed=${elapsed}ms\n\n`); // SSE frame
      if (elapsed >= DURATION_MS) {
        clearInterval(timer);
        res.write(`data: [END]\n\n`);
        res.end();
      }
    }, 1000);

    req.on("close", () => clearInterval(timer));
  });

  const server = http.createServer(app);
  const wss = new WebSocket.Server({ server, path: "/ws" });

  wss.on("connection", (socket, req) => {
    const ip = req.socket.remoteAddress;
    socket.send(JSON.stringify({ type: "welcome", msg: "WebSocket echo ready", ip }));

    socket.on("message", (data) => {
      // Echo with timestamp
      socket.send(JSON.stringify({ type: "echo", ts: Date.now(), data: data.toString() }));
    });

    socket.on("ping", () => {
      socket.pong();
    });
  });

  server.listen(PORT, () => {
    console.log(`🟢 Test server avviato su http://localhost:${PORT}`);
    console.log(`   • HTTP stream:  GET http://localhost:${PORT}/stream`);
    console.log(`   • WebSocket:    WS  ws://localhost:${PORT}/ws`);
    console.log(`   (Durata stream predefinita: ${DURATION_MS}ms — override con DURATION_MS)`);
  });
}

function delay(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function testWebSocket(url, label) {
  console.log(`\n[WS] Test: ${label} → ${url}`);
  return new Promise((resolve) => {
    const start = Date.now();
    let open = false;
    let messages = 0;
    let pongs = 0;
    let closed = false;

    const ws = new WebSocket(url, { handshakeTimeout: 8000 });

    const pingInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        try {
          ws.ping();
        } catch {}
      }
    }, 5000);

    const echoInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(`ping-${Date.now()}`);
      }
    }, 4000);

    ws.on("open", () => {
      open = true;
      console.log("  ✓ WS open");
    });

    ws.on("pong", () => {
      pongs++;
    });

    ws.on("message", (data) => {
      messages++;
      // Non stampare tutto per evitare rumore
      if (messages <= 3) console.log("  ↪ message:", data.toString().slice(0, 120));
    });

    ws.on("close", (code, reason) => {
      closed = true;
      clearInterval(pingInterval);
      clearInterval(echoInterval);
      const elapsed = Date.now() - start;
      console.log(`  ⚠ WS closed (code=${code}) after ${elapsed}ms. reason=${reason?.toString?.() || ""}`);
      resolve({ ok: open, messages, pongs, closedEarly: elapsed < 10000 });
    });

    ws.on("error", (err) => {
      clearInterval(pingInterval);
      clearInterval(echoInterval);
      console.log("  ✗ WS error:", err?.message || err);
      resolve({ ok: false, messages, pongs, closedEarly: true, error: err?.message || String(err) });
    });

    // Hard timeout
    setTimeout(() => {
      try { ws.close(); } catch {}
    }, Math.min(DURATION_MS, 30000));
  });
}

async function testHttpStream(url) {
  console.log(`\n[HTTP] Streaming test → ${url}`);

  return new Promise((resolve) => {
    const start = Date.now();
    const req = http.get(url, (res) => {
      console.log(`  • status=${res.statusCode}, headers: transfer-encoding=${res.headers["transfer-encoding"] || ""}, content-type=${res.headers["content-type"] || ""}`);

      let chunks = 0;
      let lastChunkAt = 0;

      res.on("data", (buf) => {
        chunks++;
        lastChunkAt = Date.now();
        if (chunks <= 3) {
          console.log("  ↪ chunk:", buf.toString().slice(0, 80).replace(/\n/g, "\\n"));
        }
      });

      res.on("end", () => {
        const elapsed = Date.now() - start;
        console.log(`  ✓ stream ended after ${elapsed}ms, chunks=${chunks}`);
        resolve({ ok: chunks > 0, chunks, elapsed, lastChunkAt });
      });
    });

    req.on("error", (e) => {
      console.log("  ✗ HTTP error:", e?.message || e);
      resolve({ ok: false, chunks: 0, error: e?.message || String(e) });
    });

    // hard timeout
    req.setTimeout(Math.min(DURATION_MS + 5000, 40000), () => {
      console.log("  ✗ HTTP timeout");
      try { req.destroy(new Error("timeout")); } catch {}
      resolve({ ok: false, chunks: 0, error: "timeout" });
    });
  });
}

async function runClient() {
  // Target locali di default
  const wsLocal = process.env.WS_URL || `ws://localhost:${PORT}/ws`;
  const httpLocal = process.env.STREAM_URL || `http://localhost:${PORT}/stream`;

  // 1) Test WS (locale o custom)
  const ws1 = await testWebSocket(wsLocal, "Local/Custom");

  // 1b) Se fallisce o si chiude troppo presto, prova endpoint pubblico
  let ws2 = null;
  if (!ws1.ok || ws1.closedEarly) {
    const publicWS = "wss://echo.websocket.events";
    ws2 = await testWebSocket(publicWS, "Public fallback");
  }

  // 2) Test HTTP streaming (locale o custom)
  const s1 = await testHttpStream(httpLocal);

  // 3) Report sintetico
  console.log("\n====== SUMMARY ======");
  console.log("WebSocket local/custom:", ws1);
  if (ws2) console.log("WebSocket public      :", ws2);
  console.log("HTTP stream           :", s1);

  // 4) Diagnosi rapida
  console.log("\n====== DIAGNOSIS HINTS ======");
  if (!ws1.ok && (!ws2 || !ws2.ok)) {
    console.log("- ❌ WebSocket sembra bloccato sia localmente che su endpoint pubblico.");
    console.log("  Possibili cause: proxy aziendale, firewall, plugin browser, rete instabile.");
  } else if (!ws1.ok && ws2 && ws2.ok) {
    console.log("- ⚠️  WS locale fallisce, pubblico ok → probabilmente server locale non raggiungibile o porte bloccate.");
  } else if (ws1.closedEarly) {
    console.log("- ⚠️  WS si chiude troppo presto → la tua rete interrompe connessioni lunghe (idle timeout).");
  } else {
    console.log("- ✅ WebSocket stabile.");
  }

  if (!s1.ok || s1.chunks === 0) {
    console.log("- ❌ HTTP streaming non ha ricevuto chunk → proxy o ispezioni che bufferizzano/chiudono.");
  } else {
    console.log("- ✅ HTTP streaming ok (chunk ricevuti).");
  }

  console.log("\nSuggerimenti:");
  console.log("• Prova a disattivare AdBlock/estensioni privacy e ripeti il test.");
  console.log("• Se usi rete aziendale, prova hotspot o VPN per confronto.");
  console.log("• In caso di sessioni lunghe, ricarica la pagina della chat quando noti lo 'spinner' infinito.");
}

(async () => {
  if (IS_SERVER) {
    await startServer();
  } else {
    console.log("ℹ️  Modalità client (usa --server in un’altra shell per avviare il server locale di test).");
    console.log(`   PORT=${PORT}  DURATION_MS=${DURATION_MS}\n`);
    await runClient();
  }
})();
