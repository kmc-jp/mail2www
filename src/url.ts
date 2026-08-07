export interface UrlMatch {
  index: number
  url: string
}

// RFC 3986 unreserved characters, reserved characters, and percent encoding.
const urlCandidatePattern = /https?:\/\/[A-Za-z0-9\-._~:/?#[\]@!$&'()*+,;=%]+/g
const trailingProsePunctuation = /[.,;:!?]$/
const incompletePercentEncoding = /%(?![A-Fa-f0-9]{2})/

function count(value: string, character: string) {
  return [...value].filter(item => item === character).length
}

function trimUrlCandidate(candidate: string, precedingCharacter: string | undefined) {
  const incompleteEncoding = candidate.search(incompletePercentEncoding)
  let url = incompleteEncoding === -1 ? candidate : candidate.slice(0, incompleteEncoding)

  let changed = true
  while (changed) {
    const previous = url
    url = url.replace(trailingProsePunctuation, '')

    if (url.endsWith(')') && count(url, ')') > count(url, '(')) url = url.slice(0, -1)
    if (url.endsWith(']') && count(url, ']') > count(url, '[')) url = url.slice(0, -1)
    if (url.endsWith("'") && precedingCharacter === "'") url = url.slice(0, -1)
    if (url.endsWith('*') && precedingCharacter === '*') url = url.slice(0, -1)
    changed = url !== previous
  }

  return url
}

export function findUrls(text: string): UrlMatch[] {
  const matches: UrlMatch[] = []

  for (const candidate of text.matchAll(urlCandidatePattern)) {
    const index = candidate.index
    const url = trimUrlCandidate(candidate[0], text[index - 1])
    const authority = url.slice(url.indexOf('//') + 2).split(/[/?#]/, 1)[0]

    if (!url || !authority) continue

    try {
      const parsed = new URL(url)
      if (!parsed.hostname) continue
    } catch {
      continue
    }

    matches.push({ index, url })
  }

  return matches
}
