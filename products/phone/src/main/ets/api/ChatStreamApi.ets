import http from '@ohos.net.http'
import { StreamChatRequest } from '../type/MessageType'
import EventSource from '../utils/EventSourceUtil'
import { storageUtil } from 'lib_common'
import { ChatMessageRequest } from '../type/RAGType'

export interface StreamChatCallbacks {
  onMessage: (text: string) => void
  onError?: (error: Error) => void
  onComplete?: () => void
}

export class ChatStreamApi {
  private eventSource: EventSource | null = null

  async startChat(
    url: string,
    req: StreamChatRequest,
    callbacks: StreamChatCallbacks
  ): Promise<void> {
    // 防止重复连接
    this.stopChat()

    let tokenString = ''

    try {
      const token = await storageUtil.get('token')
      tokenString = token ? token.toString() : ''
    } catch (e) {
      console.warn('获取 token 失败:', e)
    }

    this.eventSource = new EventSource(url, {
      method: http.RequestMethod.POST,
      headers: {
        'Content-Type': 'application/json',
        // ⭐ 关键就在这里
        'Authorization': tokenString ? `Bearer ${tokenString}` : ''
      },
      body: JSON.stringify(req)
    })

    this.eventSource.onMessage = (event): void => {
      callbacks.onMessage(event.data)
    }

    this.eventSource.onError = (err: Error): void => {
      callbacks.onError?.(err)
    }

    this.eventSource.onComplete = (): void => {
      callbacks.onComplete?.()
    }
  }
  async startChatRAG(
    url: string,
    req: ChatMessageRequest,
    callbacks: StreamChatCallbacks
  ): Promise<void> {
    // 防止重复连接
    this.stopChat()

    let tokenString = ''

    try {
      const token = await storageUtil.get('token')
      tokenString = token ? token.toString() : ''
    } catch (e) {
      console.warn('获取 token 失败:', e)
    }

    this.eventSource = new EventSource(url, {
      method: http.RequestMethod.POST,
      headers: {
        'Content-Type': 'application/json',
        // ⭐ 关键就在这里
        'Authorization': tokenString ? `Bearer ${tokenString}` : ''
      },
      body: JSON.stringify(req)
    })

    this.eventSource.onMessage = (event): void => {
      callbacks.onMessage(event.data)
    }

    this.eventSource.onError = (err: Error): void => {
      callbacks.onError?.(err)
    }

    this.eventSource.onComplete = (): void => {
      callbacks.onComplete?.()
    }
  }

  stopChat(): void {
    if (this.eventSource) {
      this.eventSource.close()
      this.eventSource = null
    }
  }
}

