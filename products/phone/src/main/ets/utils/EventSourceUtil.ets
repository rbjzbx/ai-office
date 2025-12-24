import http from '@ohos.net.http'
import util from '@ohos.util'

/* ---------- 类型定义 ---------- */

interface EventSourceOptions {
  method?: http.RequestMethod
  headers?: Record<string, string>
  body?: string
}

interface EventSourceEvent {
  data: string
}

interface RequestOptions {
  method: http.RequestMethod
  header: Record<string, string>
  readTimeout: number
  extraData?: string
}

type EventCallback = (event: EventSourceEvent) => void

/* ---------- 实现 ---------- */

export default class EventSource {
  private httpRequest: http.HttpRequest
  private url: string
  private options: EventSourceOptions
  private onmessage: EventCallback | null = null
  private onerror: ((error: Error) => void) | null = null
  private oncomplete: (() => void) | null = null
  private buffer: string = ''
  private isActive: boolean = false
  private decoder: util.TextDecoder = new util.TextDecoder()

  constructor(url: string, options: EventSourceOptions = {}) {
    this.url = url
    this.options = options
    this.httpRequest = http.createHttp()
    this.connect()
  }

  private connect(): void {
    this.isActive = true

    // 手动构建 headers（ArkTS 不允许 Object.assign）
    const headers: Record<string, string> = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Content-Type': 'application/json'
    }

    if (this.options.headers) {
      const keys: string[] = Object.keys(this.options.headers)
      for (let i = 0; i < keys.length; i++) {
        const key: string = keys[i]
        headers[key] = this.options.headers[key]
      }
    }

    // 显式使用接口类型
    const requestOptions: RequestOptions = {
      method: this.options.method ?? http.RequestMethod.POST,
      header: headers,
      readTimeout: 86400000
    }

    if (this.options.body) {
      requestOptions.extraData = this.options.body
    }

    this.httpRequest.on('dataReceive', (data: ArrayBuffer): void => {
      if (!this.isActive) {
        return
      }
      try {
        const chunk: string = this.decoder.decode(new Uint8Array(data))
        this.processChunk(chunk)
      } catch (_) {
        this.handleError(new Error('decode failed'))
      }
    })

    this.httpRequest
      .requestInStream(this.url, requestOptions)
      .then((): void => {
        if (this.oncomplete) {
          this.oncomplete()
        }
      })
      .catch((err: Error): void => {
        this.handleError(err)
      })
  }

  private processChunk(chunk: string): void {
    this.buffer += chunk
    const lines: string[] = this.buffer.split('\n')
    this.buffer = lines.pop() ?? ''

    for (let i = 0; i < lines.length; i++) {
      const line: string = lines[i]
      if (line.trim() === '') {
        continue
      }

      if (line.startsWith('data:')) {
        const data: string = line.slice(5).trim()

        if (data === '[DONE]') {
          if (this.oncomplete) {
            this.oncomplete()
          }
          this.close()
          return
        }

        if (this.onmessage) {
          this.onmessage({ data })
        }
      }
    }
  }

  private handleError(error: Error): void {
    if (this.onerror) {
      this.onerror(error)
    }
    this.close()
  }

  set onMessage(callback: EventCallback) {
    this.onmessage = callback
  }

  set onError(callback: (error: Error) => void) {
    this.onerror = callback
  }

  set onComplete(callback: () => void) {
    this.oncomplete = callback
  }

  public close(): void {
    this.isActive = false
    this.httpRequest.off('dataReceive')
    this.httpRequest.destroy()
  }
}
