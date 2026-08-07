export function formatRelativeAge(value: Date) {
  const seconds = Math.max(0, (Date.now() - value.getTime()) / 1_000)
  const minute = 60
  const hour = 60 * minute
  const day = 24 * hour

  if (seconds < minute) return `${Math.floor(seconds)}s`
  if (seconds < hour) return `${Math.floor(seconds / minute)}m`
  if (seconds < day) return `${Math.floor(seconds / hour)}h`
  if (seconds <= 30 * day) return `${Math.floor(seconds / day)}d`
  return `${Math.floor(seconds / (30 * day))}M`
}
