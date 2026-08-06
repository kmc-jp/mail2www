import * as z from 'zod/mini'

const configSchema = z.object({
  title: z.string(),
  folders: z.array(z.string()),
  mails_per_page: z.number(),
})

const messageSummarySchema = z.object({
  number: z.string(),
  from: z.nullable(z.string()),
  date: z.nullable(z.string()),
  age: z.nullable(z.string()),
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

const messageSchema = z.object({
  folder: z.string(),
  number: z.string(),
  headers: z.object({
    from: z.nullable(z.string()),
    to: z.nullable(z.string()),
    cc: z.nullable(z.string()),
    subject: z.string(),
    date: z.nullable(z.string()),
  }),
  body: z.string(),
  spam: z.boolean(),
  virus: z.nullable(z.string()),
  remote_user: z.nullable(z.string()),
  attachments: z.array(z.object({ filename: z.string(), content_type: z.nullable(z.string()) })),
})

const sourceSchema = z.object({ source: z.string() })

export type AppConfig = z.infer<typeof configSchema>
export type MessageList = z.infer<typeof messageListSchema>
export type Message = z.infer<typeof messageSchema>

async function request(path: string, init?: RequestInit): Promise<unknown> {
  const response = await fetch(`/api${path}`, init)
  if (!response.ok) {
    const body = await response.json().catch(() => null) as { error?: string } | null
    throw new Error(body?.error ?? `Request failed (${response.status})`)
  }
  return response.status === 204 ? undefined : response.json()
}

export const api = {
  config: async () => configSchema.parse(await request('/config')),
  messages: async (folder: string, page: number, perPage: number) =>
    messageListSchema.parse(await request(`/folders/${encodeURIComponent(folder)}/messages?page=${page}&per_page=${perPage}`)),
  message: async (folder: string, number: string) =>
    messageSchema.parse(await request(`/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}`)),
  source: async (folder: string, number: string) =>
    sourceSchema.parse(await request(`/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/source`)),
  forward: async (folder: string, number: string, to: string) =>
    request(`/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/forward`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ to }),
    }),
  attachmentUrl: (folder: string, number: string, filename: string) =>
    `/api/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/attachments/${encodeURIComponent(filename)}`,
  sourceDownloadUrl: (folder: string, number: string) =>
    `/api/folders/${encodeURIComponent(folder)}/messages/${encodeURIComponent(number)}/source?download=1`,
}
