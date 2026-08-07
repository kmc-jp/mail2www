import type { Mailbox } from './api'

export const formatAddresses = (addresses: Mailbox[]) =>
  addresses.map(({ name, address }) => name ? `${name} <${address}>` : address).join(', ') || '(none)'
