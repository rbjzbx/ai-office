import { MarkdownV2 } from "@lidary/markdown"
import { NavHeaderBar } from "lib_widget"
import { ChatStreamApi } from "../../api/ChatStreamApi"
import { ChatMessage } from "../../type/RAGType"
@Builder
export function CampusPolicyChatPageBuilder() {
  CampusPolicyChatPage()
}
@ComponentV2
export struct CampusPolicyChatPage {
  @Local messages: ChatMessage[] = []
  @Local inputText: string = ''
  @Local streaming: boolean = false

  private chatStreamApi: ChatStreamApi = new ChatStreamApi()
  private listScroller: Scroller = new Scroller()

  private scrollToBottom(delay: number = 30) {
    setTimeout(() => {
      this.listScroller.scrollEdge(Edge.Bottom, { velocity: 2000 })
    }, delay)
  }

  async sendMessage() {
    if (!this.inputText.trim() || this.streaming) return

    const content = this.inputText
    this.inputText = ''

    const now = Date.now()

    const userMsg: ChatMessage = {
      id: now,
      role: 'user',
      content
    }

    const assistantMsg: ChatMessage = {
      id: now + 1,
      role: 'assistant',
      content: ''
    }

    this.messages = [...this.messages, userMsg, assistantMsg]
    this.scrollToBottom()

    this.startStream(content)
  }

  async startStream(userContent: string) {
    this.streaming = true

    await this.chatStreamApi.startChatRAG(
      '10.0.2.2:8080/ai/bailian/agent/stream',
      { message: userContent },
      {
        onMessage: (text: string) => {
          const list = this.messages.slice()
          list[list.length - 1].content += text
          this.messages = list
          this.scrollToBottom()
        },
        onComplete: () => {
          this.streaming = false
          this.scrollToBottom(50)
        },
        onError: () => {
          this.streaming = false
        }
      }
    )
  }

  build() {
    NavDestination() {   // ✅ 必须有
      Column() {

        // ① 顶部标题栏
        NavHeaderBar({
          title: '校园政策 AI',
          showBackBtn: true
        })

        // ② 消息列表（中间，可滚动）
        List({ scroller: this.listScroller }) {
          ForEach(
            this.messages,
            (_: ChatMessage, index: number) => {
              this.messageItem(index)
            },
            (msg: ChatMessage) => msg.id.toString()
          )
        }
        .layoutWeight(1)   // ✅ 只给 List

        // ③ 底部输入区（固定高度）
        Row({ space: 8 }) {
          TextInput({
            text: this.inputText,
            placeholder: '请输入校园政策相关问题'
          })
            .layoutWeight(1)
            .onChange(v => this.inputText = v)

          Button('发送')
            .enabled(!this.streaming)
            .onClick(() => this.sendMessage())
        }
        .padding(12)
      }
      .height('100%')
    }
    .expandSafeArea([SafeAreaType.KEYBOARD])  // ✅ 只在这里
    .hideTitleBar(true)                       // 如果你用自定义 Header
  }

  @Builder
  messageItem(index: number) {
    ListItem() {
      Row() {
        if (this.messages[index].role !== 'user') {
          Blank().width(40)
        }

        Column() {
          MarkdownV2({
            content: this.messages[index].content,
            lineSpace: 4,
            fontStyle: {
              fontSize: $r('sys.float.Body_M'),
              fontColor:
              this.messages[index].role === 'user'
                ? Color.White
                : $r('sys.color.font_primary')
            }
          })
        }
        .padding(12)
        .backgroundColor(
          this.messages[index].role === 'user'
            ? $r('sys.color.comp_background_emphasize')
            : $r('sys.color.comp_background_secondary')
        )
        .borderRadius(16)
        .constraintSize({ maxWidth: '70%' })

        if (this.messages[index].role === 'user') {
          Blank().width(40)
        }
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .justifyContent(
        this.messages[index].role === 'user'
          ? FlexAlign.End
          : FlexAlign.Start
      )
    }
  }

}
