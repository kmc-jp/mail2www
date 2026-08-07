export interface UrlMatch {
  index: number
  url: string
}

// RFC 3986 unreserved characters, reserved characters, and percent encoding.
const urlCandidatePattern = /https?:\/\/(?:(?!\]\(https?:\/\/)[A-Za-z0-9\-._~:/?#[\]@!$&'()*+,;=%])+/g
const trailingProsePunctuation = '.,;:!?'
const incompletePercentEncoding = /%(?![A-Fa-f0-9]{2})/

function trimUrlCandidate(candidate: string, precedingCharacter: string | undefined) {
  const incompleteEncoding = candidate.search(incompletePercentEncoding)
  const url = incompleteEncoding === -1 ? candidate : candidate.slice(0, incompleteEncoding)
  let parenthesisBalance = 0
  let bracketBalance = 0

  for (const character of url) {
    if (character === '(') parenthesisBalance--
    if (character === ')') parenthesisBalance++
    if (character === '[') bracketBalance--
    if (character === ']') bracketBalance++
  }

  let end = url.length
  while (end > 0) {
    const character = url[end - 1]

    if (trailingProsePunctuation.includes(character)) {
      end--
    } else if (character === ')' && parenthesisBalance > 0) {
      parenthesisBalance--
      end--
    } else if (character === ']' && bracketBalance > 0) {
      bracketBalance--
      end--
    } else if ((character === "'" || character === '*') && character === precedingCharacter) {
      end--
    } else {
      break
    }
  }

  return url.slice(0, end)
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
