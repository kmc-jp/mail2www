import * as z from 'zod/mini'

const jsonResponse = z.pipe(
  z.instanceof(Response),
  z.transform(response => response.json() as unknown),
)

const emptyResponse = z.pipe(
  z.instanceof(Response),
  z.transform(() => undefined),
)

const datetimeSchema = z.codec(z.iso.datetime({ offset: true }), z.date(), {
  decode: value => new Date(value),
  encode: value => value.toISOString(),
})

const configSchema = z.object({
  title: z.string(),
  folders: z.array(z.string()),
  ruby_version: z.string(),
  remote_user: z.nullable(z.string()),
})

const messageSummarySchema = z.object({
  number: z.string(),
  from: z.nullable(z.string()),
  date: z.nullable(datetimeSchema),
  subject: z.string(),
})

const messageListSchema = z.object({
  folder: z.string(),
  page: z.number(),
  per_page: z.number(),
  pages: z.number(),
  total: z.number(),
  messages: z.array(messageSummarySchema),
})

const mailboxSchema = z.object({
  name: z.nullable(z.string()),
  address: z.string(),
})

const messageSchema = z.object({
  folder: z.string(),
  number: z.string(),
  headers: z.object({
    from: z.array(mailboxSchema),
    to: z.array(mailboxSchema),
    cc: z.array(mailboxSchema),
    subject: z.string(),
    date: z.nullable(datetimeSchema),
  }),
  body: z.object({
    text: z.nullable(z.string()),
    html: z.nullable(z.string()),
  }),
  spam: z.boolean(),
  virus: z.nullable(z.string()),
  attachments: z.array(z.object({ filename: z.string(), content_type: z.nullable(z.string()) })),
})

const sourceSchema = z.object({ source: z.string() })

export type AppConfig = z.infer<typeof configSchema>
export type MessageList = z.infer<typeof messageListSchema>
export type Mailbox = z.infer<typeof mailboxSchema>
export type Message = z.infer<typeof messageSchema>

async function request<T extends z.ZodMiniType>(path: string, schema: T, init?: RequestInit): Promise<z.output<T>> {
  const response = await fetch(`/api${path}`, init)
  if (!response.ok) {
    const body = await response.json().catch(() => null) as { error?: string } | null
    throw new Error(body?.error ?? `Request failed (${response.status})`)
  }
  return schema.parseAsync(response)
}

export const api = {
  config: async () => request('/config', z.pipe(jsonResponse, configSchema)),
  messages: async (folder: string, page: number, perPage: number) =>
    request(
      `/folders/${encodeURIComponent(folder)}/messages?page=${page}&per_page=${perPage}`,
      z.pipe(jsonResponse, messageListSchema),
    ),
  message: async (folder: string, number: string) =>
    request(
      `/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}`,
      z.pipe(jsonResponse, messageSchema),
    ),
  source: async (folder: string, number: string) =>
    request(
      `/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/source`,
      z.pipe(jsonResponse, sourceSchema),
    ),
  forward: async (folder: string, number: string, to: string) =>
    request(`/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/forward`, emptyResponse, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ to }),
    }),
  attachmentUrl: (folder: string, number: string, filename: string) =>
    `/api/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/attachments/${encodeURIComponent(filename)}`,
  sourceDownloadUrl: (folder: string, number: string) =>
    `/api/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/source?download=1`,
}
