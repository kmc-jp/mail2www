import type { ReactNode } from 'react'
import { findUrls } from '../url'

export function MessageBody({ text, dangerous }: { text: string, dangerous: boolean }) {
  const chunks: ReactNode[] = []
  let offset = 0
  for (const match of findUrls(text)) {
    const { index, url } = match
    chunks.push(text.slice(offset, index))
    chunks.push(<a key={index} href={url} rel="noreferrer" onClick={(event) => {
      if (dangerous && !window.confirm('このリンクは危険な可能性があります。本当に開きますか？')) event.preventDefault()
    }}>{url}</a>)
    offset = index + url.length
  }
  chunks.push(text.slice(offset))
  return <pre className="mail-body">{chunks}</pre>
}
