import { Fragment } from 'react'
import type { Mailbox as MailboxData } from '../api'

export function Mailbox({ mailbox }: { mailbox: MailboxData }) {
  const name = mailbox.name
  return <>{name && !mailbox.suspicious_name && `${name} `}&lt;{mailbox.address}&gt;</>
}

export function Mailboxes({ mailboxes }: { mailboxes: MailboxData[] }) {
  if (mailboxes.length === 0) return '(none)'

  return mailboxes.map((mailbox, index) => <Fragment key={`${mailbox.address}-${index}`}>
    {index > 0 && ', '}
    <Mailbox mailbox={mailbox} />
  </Fragment>)
}
