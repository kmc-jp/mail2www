import type { ReactNode } from 'react'

const urlPattern = /https?:\/\/[^\s<>]+/g

export function MessageBody({ text, dangerous }: { text: string, dangerous: boolean }) {
  const chunks: ReactNode[] = []
  let offset = 0
  for (const match of text.matchAll(urlPattern)) {
    const index = match.index
    chunks.push(text.slice(offset, index))
    chunks.push(<a key={index} href={match[0]} rel="noreferrer" onClick={(event) => {
      if (dangerous && !window.confirm('このリンクは危険な可能性があります。本当に開きますか？')) event.preventDefault()
    }}>{match[0]}</a>)
    offset = index + match[0].length
  }
  chunks.push(text.slice(offset))
  return <pre className="mail-body">{chunks}</pre>
}
