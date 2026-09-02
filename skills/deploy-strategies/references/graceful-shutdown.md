# Health probes & graceful shutdown

## Two different endpoints

| Endpoint | Question | On failure | Checks |
|---|---|---|---|
| `/healthz` (liveness) | Is the process wedged? | platform **restarts** the instance | cheap: event loop responsive, not deadlocked. NOT dependencies. |
| `/readyz` (readiness) | Can it serve traffic now? | platform **stops routing** to it (no restart) | DB reachable, migrations applied, caches warm, not shutting down |

Making liveness check the DB causes a cascading restart storm when the DB blips.
Don't.

## Graceful shutdown sequence (on SIGTERM)

1. Flip `/readyz` to failing → load balancer drains this instance.
2. Wait `preStop` / a few seconds for the LB to notice.
3. Stop accepting new connections; let in-flight requests finish (bounded, e.g.
   25s < platform `terminationGracePeriodSeconds` 30s).
4. Close DB pool, flush logs/metrics, cancel background workers cleanly.
5. Exit 0.

## Node example

```js
const server = app.listen(PORT);
let shuttingDown = false;
app.get("/readyz", (_req, res) =>
  res.sendStatus(shuttingDown || !dbOk() ? 503 : 200));

process.on("SIGTERM", async () => {
  shuttingDown = true;
  await sleep(5000);                 // let the LB drop us
  server.close(async () => {
    await db.end();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 25000).unref(); // hard cap
});
```

## Kubernetes snippet

```yaml
readinessProbe: { httpGet: { path: /readyz, port: 8080 }, periodSeconds: 5 }
livenessProbe:  { httpGet: { path: /healthz, port: 8080 }, periodSeconds: 10, failureThreshold: 3 }
lifecycle: { preStop: { exec: { command: ["sleep", "5"] } } }
terminationGracePeriodSeconds: 30
```
