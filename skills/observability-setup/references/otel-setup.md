# OpenTelemetry setup

## Architecture

```
app (OTel SDK) --OTLP--> OTel Collector --> [Tempo/Jaeger]  traces
                                       --> [Mimir/Prometheus] metrics
                                       --> [Loki]             logs
```

The Collector is the only thing that knows your backend. Apps only speak OTLP.

## Resource attributes (set once, on every signal)

`service.name`, `service.version`, `service.namespace`, `deployment.environment`,
`host.name` / `k8s.pod.name`.

## Auto-instrument first

Node: `@opentelemetry/auto-instrumentations-node` (http, express/fastify, pg,
ioredis, amqplib, aws-sdk, ...).
Python: `opentelemetry-instrument` + `opentelemetry-distro`.
Go/Java: the contrib instrumentation libs / Java agent.

## Then add manual spans for business operations

```js
import { trace } from "@opentelemetry/api";
const tracer = trace.getTracer("app");

await tracer.startActiveSpan("digest.build", async (span) => {
  span.setAttribute("digest.user_count", users.length);
  try { await build(); }
  catch (e) { span.recordException(e); span.setStatus({ code: 2 }); throw e; }
  finally { span.end(); }
});
```

## Context propagation

- Use the W3C `traceparent` header (default). Ensure your HTTP client + server
  and queue producers/consumers propagate it.
- For queues: inject the trace context into the message headers on publish,
  extract + link on consume.

## Sampling

- Traces: parent-based + a ratio (e.g. 10–20%) at the SDK, or tail-sampling in
  the Collector (keep all errors + slow, sample the rest).
- Metrics: never sampled.
- Errors: always keep the trace.

## Fail-open

Exporter timeout short (a few seconds), queue bounded, drop on overflow. The app
must not block or crash because the collector is unreachable.
