export type ChatRole = 'user' | 'assistant'

export interface ChatMessage {
  id: number
  role: 'user' | 'assistant'
  content: string
}

export interface ChatMessageRequest {
  message: string
}