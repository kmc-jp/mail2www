import { describe, expect, test } from 'vitest'
import { renderToStaticMarkup } from 'react-dom/server'
import { Mailbox } from './Mailbox'

describe('Mailbox', () => {
  test('hides a suspicious mailbox name', () => {
    expect(renderToStaticMarkup(<Mailbox mailbox={{ name: 'Impostor', address: 'safe@example.com', suspicious_name: true, suspicious_address: false }} />))
      .toBe('&lt;safe@example.com&gt;')
  })

  test('renders a normal mailbox name', () => {
    expect(renderToStaticMarkup(<Mailbox mailbox={{ name: 'User', address: 'user@example.com', suspicious_name: false, suspicious_address: false }} />))
      .toBe('User &lt;user@example.com&gt;')
  })

  test('renders an unnamed address in angle brackets', () => {
    expect(renderToStaticMarkup(<Mailbox mailbox={{ name: null, address: 'user@example.com', suspicious_name: false, suspicious_address: false }} />))
      .toBe('&lt;user@example.com&gt;')
  })
})
