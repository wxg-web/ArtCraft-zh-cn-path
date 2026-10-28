import fs from "node:fs/promises";
import process from "node:process";

const scriptDirectory = new URL("./", import.meta.url);
const translationSource = await fs.readFile(
  new URL("./zh-cn.js", scriptDirectory),
  "utf8",
);

const portArgument = process.argv.findIndex((argument) => argument === "--port");
const port =
  portArgument >= 0 && process.argv[portArgument + 1]
    ? Number(process.argv[portArgument + 1])
    : 9333;

const endpoint = `http://127.0.0.1:${port}/json`;
let stopping = false;

process.on("SIGINT", () => {
  stopping = true;
  process.exit(0);
});
process.on("SIGTERM", () => {
  stopping = true;
  process.exit(0);
});

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

async function findArtCraftTarget() {
  const response = await fetch(endpoint, { signal: AbortSignal.timeout(2000) });
  if (!response.ok) {
    return null;
  }
  const targets = await response.json();
  return (
    targets
      .filter(
        (target) =>
          target.type === "page" &&
          target.webSocketDebuggerUrl &&
          !target.url.startsWith("devtools://") &&
          !target.url.startsWith("edge://"),
      )
      .sort((left, right) => {
        const leftArtCraft =
          /artcraft|tauri\.localhost/i.test(`${left.url} ${left.title}`) ? 1 : 0;
        const rightArtCraft =
          /artcraft|tauri\.localhost/i.test(`${right.url} ${right.title}`) ? 1 : 0;
        return rightArtCraft - leftArtCraft;
      })
      .find((target) =>
        /artcraft|tauri\.localhost/i.test(`${target.url} ${target.title}`),
      ) ?? null
  );
}

async function connectToArtCraft() {
  while (!stopping) {
    try {
      const target = await findArtCraftTarget();
      if (target) {
        return target;
      }
    } catch {
      // ArtCraft is still starting.
    }
    await sleep(350);
  }
  return null;
}

while (!stopping) {
  const target = await connectToArtCraft();
  if (!target) {
    break;
  }

  const socket = new WebSocket(target.webSocketDebuggerUrl);
  let nextId = 1;
  let closed = false;
  const pending = new Map();
  let injectTimer = null;

  socket.addEventListener("message", (event) => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const request = pending.get(message.id);
      if (!request) {
        return;
      }
      pending.delete(message.id);
      if (message.error) {
        request.reject(new Error(JSON.stringify(message.error)));
      } else {
        request.resolve(message.result);
      }
      return;
    }

    if (
      message.method === "Page.loadEventFired" ||
      message.method === "Page.frameNavigated"
    ) {
      clearTimeout(injectTimer);
      injectTimer = setTimeout(() => {
        inject().catch((error) => log(`Injection after navigation failed: ${error}`));
      }, 250);
    }
  });

  socket.addEventListener("close", () => {
    closed = true;
    clearTimeout(injectTimer);
  });

  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, { once: true });
    socket.addEventListener("error", reject, { once: true });
  });

  function send(method, params = {}) {
    if (closed) {
      return Promise.reject(new Error("Debugger connection is closed"));
    }
    const id = nextId++;
    socket.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
    });
  }

  async function evaluate(expression) {
    const result = await send("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true,
    });
    if (result.exceptionDetails) {
      throw new Error(JSON.stringify(result.exceptionDetails));
    }
    return result.result.value;
  }

  async function inject() {
    if (closed) {
      return;
    }
    try {
      await evaluate(translationSource);
      log(`Chinese interface applied to ${target.url}`);
    } catch (error) {
      log(`Injection will retry: ${error}`);
    }
  }

  try {
    await send("Page.enable");
    await send("Runtime.enable");
    await send("Page.addScriptToEvaluateOnNewDocument", {
      source: translationSource,
    });
    await inject();
  } catch (error) {
    log(`Debugger setup failed: ${error}`);
  }

  while (!closed && !stopping) {
    await sleep(1500);
    if (closed) {
      break;
    }
    try {
      const applied = await evaluate(
        "Boolean(window.__ARTCRAFT_ZH_CN__ && document.body)",
      );
      if (!applied) {
        await inject();
      }
    } catch {
      // Navigation can briefly invalidate the execution context.
    }
  }

  socket.close();
  if (!stopping) {
    await sleep(500);
  }
}

log("Translator stopped");
