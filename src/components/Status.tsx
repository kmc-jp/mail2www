export function Loading() {
  return <div className="main">Loading…</div>
}

export function PageError({ error }: { error: unknown }) {
  return <div className="main">{error instanceof Error ? error.message : String(error)}</div>
}
