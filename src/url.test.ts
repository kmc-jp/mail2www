import { expect, test } from 'vitest'

import { findUrls } from './url'

function urls(text: string) {
  return findUrls(text).map(match => match.url)
}

test('stops before adjacent non-ASCII prose', () => {
  expect(urls('See https://example.test/path。次はこちら')).toEqual([
    'https://example.test/path',
  ])
})

test('removes common trailing prose punctuation', () => {
  for (const punctuation of ['.', ',', ';', ':', '!', '?']) {
    expect(urls(`See https://example.test/path${punctuation} Next`)).toEqual([
      'https://example.test/path',
    ])
  }
})

test('keeps URL punctuation that is not trailing', () => {
  expect(urls('https://example.test/a_(b)/c?x=1&next=/a?b#section-1')).toEqual([
    'https://example.test/a_(b)/c?x=1&next=/a?b#section-1',
  ])
})

test('keeps square brackets in query parameter names', () => {
  expect(urls('https://example.test/path?a[]=1&a[]=2')).toEqual([
    'https://example.test/path?a[]=1&a[]=2',
  ])
})

test('removes an unmatched closing parenthesis surrounding a URL', () => {
  expect(urls('(https://example.test/path)')).toEqual([
    'https://example.test/path',
  ])
})

test('keeps balanced parentheses in a URL', () => {
  expect(urls('https://example.test/wiki/Foo_(bar)')).toEqual([
    'https://example.test/wiki/Foo_(bar)',
  ])
})

test('removes an unmatched closing bracket surrounding a URL', () => {
  expect(urls('[https://example.test/path]')).toEqual([
    'https://example.test/path',
  ])
})

test('keeps balanced brackets in a URL', () => {
  expect(urls('https://example.test/a[b]')).toEqual([
    'https://example.test/a[b]',
  ])
})

test('does not mistake IPv6 brackets for prose delimiters', () => {
  expect(urls('[https://[2001:db8::1]/path]')).toEqual([
    'https://[2001:db8::1]/path',
  ])
})

test('keeps complete percent encodings and stops at an incomplete one', () => {
  expect(urls('https://example.test/a%20b https://example.test/a%ZZ')).toEqual([
    'https://example.test/a%20b',
    'https://example.test/a',
  ])
})

test('removes a matching single-quote wrapper', () => {
  expect(urls("'https://example.test/path'")).toEqual([
    'https://example.test/path',
  ])
})

test('removes matching Markdown emphasis wrappers', () => {
  expect(urls('**https://example.test/path**')).toEqual([
    'https://example.test/path',
  ])
})

test('keeps a trailing star without an opening wrapper', () => {
  expect(urls('https://example.test/path*')).toEqual([
    'https://example.test/path*',
  ])
})

test('rejects URLs without a host', () => {
  expect(urls('http:///path and https://?query')).toEqual([])
})
