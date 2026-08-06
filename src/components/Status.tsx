export function Loading() {
  return <div className="main">Loading…</div>
}

export function PageError({ error }: { error: Error }) {
  return <div className="main">{error.message}</div>
}
