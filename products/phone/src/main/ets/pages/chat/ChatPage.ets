import { markConfig, MarkdownV2 } from '@lidary/markdown';
import { RouterMap, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { ChatStreamApi } from '../../api/ChatStreamApi';
import { ConversationApi } from '../../api/conversationApi';
import { MessageApi } from '../../api/messageApi';
import { HistoryButton } from '../../components/HistoryButton';
import { ConversationCreateDTO } from '../../type/ConversationType';
import { MessageVO } from '../../type/MessageType';

@ComponentV2
export struct ChatPage {
  @Local conversationId?: number
  @Local messages: MessageVO[] | null = []
  @Local inputText: string = ''
  @Local streaming: boolean = false
  private chatStreamApi: ChatStreamApi = new ChatStreamApi()
  private listScroller: Scroller = new Scroller()
  private scrollToBottom(delay: number = 30) {
    setTimeout(() => {
      // API 12+ 官方推荐
      this.listScroller.scrollEdge(Edge.Bottom, {
        velocity: 2000
      })
    }, delay)
  }

  get messageList(): MessageVO[] {
    return this.messages ?? []
  }
  async loadMessages() {
    if (this.conversationId === undefined) {
      return
    }

    this.messages = await MessageApi.getConversationMessages(
      this.conversationId
    )
    this.scrollToBottom(50)
  }
  private createConversationDTO: ConversationCreateDTO= {
    title: '',
    modelName: '',
  }
  async createConversationAndInit() {
    const newConversation = await ConversationApi.createUserConversation(this.createConversationDTO)
    this.conversationId = newConversation?.id
    this.messages = []
  }

  aboutToAppear(): void {
    if (this.conversationId === undefined) {
      this.createConversationAndInit()
    } else {
      this.loadMessages()
    }markConfig.registerLinkClick = (url? : string) => {
      this.getUIContext().getPromptAction().showToast({
        message: `超链接被点击----url:${url}`,
        duration: 1500,
        bottom: 'center',
      })
    }
  }
  async sendMessage() {
    if (!this.inputText.trim() || this.streaming) return

    if (this.conversationId === undefined) {
      await this.createConversationAndInit()
      if (this.conversationId === undefined) return
    }

    // ⭐ 关键：在这里收敛
    const conversationId = this.conversationId

    const content = this.inputText
    this.inputText = ''

    const now = Date.now()

    const userMsg: MessageVO = {
      id: now,
      conversationId: conversationId,
      role: 'user',
      content,
      createTime: now.toString(),
      modelName: '',
      status: 0,
      hasThinking: 0,
      thinkingContent: '',
      hasWebSearch: 0,
      updateTime: ''
    }

    const assistantMsg: MessageVO = {
      id: now + 1,
      conversationId: conversationId,
      role: 'assistant',
      content: '',
      createTime: now.toString(),
      modelName: '',
      status: 0,
      hasThinking: 0,
      thinkingContent: '',
      hasWebSearch: 0,
      updateTime: ''
    }

    this.messages = [
      ...(this.messages ?? []),
      userMsg,
      assistantMsg
    ]

    this.scrollToBottom()

    // ⭐ 把 number 传下去
    this.startStream(conversationId, content, assistantMsg)
  }




  async startStream(
    conversationId: number,
    userContent: string,
    assistantMsg: MessageVO
  ) {
    this.streaming = true

    await this.chatStreamApi.startChat(
      '10.0.2.2:8080/ai/chat/stream',
      {
        conversationId: conversationId, // ✅ 已经是 number
        content: userContent,
        modelName: '',
        enableThanking: false
      },
      {
        onMessage: (text: string) => {
          const oldList: MessageVO[] = this.messages ?? []
          if (oldList.length === 0) return

          const list = oldList.slice()
          list[list.length - 1].content += text

          this.messages = list
          this.scrollToBottom()
        },
        onComplete: () => {
          this.streaming = false
          this.scrollToBottom(50)
        },
        onError: (err: Error) => {
          console.error('SSE error', err)
          this.streaming = false
        }
      }
    )
  }

  build() {
    Column() {
      // ① 顶部 Header
      NavHeaderBar({
        title: '校园助手AI',
        isSubTitle: false,
        showBackBtn: false,
        rightPartBuilder: () => {
          this.menusBuilder()
        }
      }).expandSafeArea([SafeAreaType.KEYBOARD])

      // ② 消息列表（List）
      List({
        scroller: this.listScroller
      }) {
        ForEach(
          this.messages,
          (msg: MessageVO, index: number) => {
            this.messageItem(index)
          },
          (msg: MessageVO) => msg.id.toString()
        )
      }
      .layoutWeight(1)

      // ③ 输入区（Row）
      Row({ space: 8 }) {
        TextInput({
          text: this.inputText,
          placeholder: '请输入消息'
        })
          .layoutWeight(1)
          .onChange(v => this.inputText = v)

        Button('发送')
          .enabled(!this.streaming)
          .onClick(() => this.sendMessage())
      }
      .padding(12)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%')
  }

  @Builder
  markdownRender(content: string) {
    MarkdownV2({
      content: content,
      lineSpace: 4,
      fontStyle: {
        fontSize: $r('sys.float.Body_M'),
        fontColor: $r('sys.color.font_primary')
      }
    })
  }
  @Builder
  messageItem(index: number) {
    Row() {
      if (this.messageList[index].role !== 'user') {
        // assistant 左侧留空头像位
        Blank().width(40)
      }

      Column() {
        MarkdownV2({
          content: this.messageList[index].content,
          lineSpace: 4,
          fontStyle: {
            fontSize: $r('sys.float.Body_M'),
            fontColor:
            this.messageList[index].role === 'user'
              ? Color.White
              : $r('sys.color.font_primary')
          }
        })
      }
      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
      .backgroundColor(
        this.messageList[index].role === 'user'
          ? $r('sys.color.comp_background_emphasize')
          : $r('sys.color.comp_background_secondary')
      )
      .borderRadius(16)
      .constraintSize({ maxWidth: '70%' })

      if (this.messageList[index].role === 'user') {
        // user 右侧留空头像位
        Blank().width(40)
      }
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .justifyContent(
      this.messageList[index].role === 'user'
        ? FlexAlign.End
        : FlexAlign.Start
    )
  }


  @Builder
  menusBuilder() {
    Row({ space: 16 }) {

      // 新会话 / 清空当前消息
      SymbolGlyph($r('sys.symbol.message_badge_plus_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.icon_primary')])
        .padding(8)
        .borderRadius(40)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .onClick(async () => {
          if (this.streaming) {
            return
          }

          await this.createConversationAndInit()
        })

      // 历史会话
      HistoryButton({
        onEvent: () => {
          RouterUtils.pushPathByName(
            RouterMap.CHAT_HISTORY_PAGE,
            null,
            (popInfo) => {
              const id = popInfo.result as number
              if (this.conversationId !== id) {
                this.conversationId = id
                this.loadMessages()
              }
            }
          )
        }
      })
    }
  }

}