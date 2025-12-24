import {  StoreManager } from '@hw-agconnect/copilot';
import dayJs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import { ConversationApi } from '../api/conversationApi';
import { ConversationVO, ChatMessageVO } from '../type/ConversationType';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';

dayJs.extend(utc)

@CustomDialog
struct RenameDialog {
  controller: CustomDialogController
  @State textValue: string = ''
  confirm: (value: string) => void = (value: string) => {}

  build() {
    Column() {
      Text('重命名会话').fontSize(20).margin({ bottom: 10, top: 10 })
      TextInput({ text: this.textValue, placeholder: '请输入新名称' })
        .onChange((value: string) => {
          this.textValue = value
        })
        .margin({ bottom: 10 })
      Row() {
        Button('取消').onClick(() => { this.controller.close() }).backgroundColor(0xF5F5F5).fontColor(Color.Black).margin({right: 10})
        Button('确定').onClick(() => {
          this.confirm(this.textValue)
          this.controller.close()
        })
      }.margin({ top: 10 }).justifyContent(FlexAlign.SpaceEvenly).width('100%')
    }.padding(20).backgroundColor(Color.White).borderRadius(10)
  }
}

@ComponentV2
export struct CopilotHistory {
  @Param isDeleted: boolean = false;
  @Event onClickEvent?: (id: number) => void;
  @Local infos: ConversationVO[]|null = []
  @Local deleteThreadIds: number[] = [];
  @Local isAllChecked: boolean = false;
  @Local isAllCheckClicked: boolean = false;

  @Local renameValue: string = '';
  renameDialogController: CustomDialogController | null = null;

  aboutToAppear(): void {
    this.refreshList();
  }

  refreshList() {
    ConversationApi.getUserConversations().then(list => {
      this.infos = list
    })
  }

  handlePin(item: ConversationVO) {
    const newPinnedStatus = !(item.pinned === 1);
    
    // 乐观更新：立即在本地更新状态，无需等待网络请求返回
    if (this.infos) {
      const index = this.infos.findIndex(info => info.id === item.id);
      if (index !== -1) {
        // 创建新的对象副本以触发UI更新
        let oldItem = this.infos[index];
        let updatedItem: ConversationVO = {
          id: oldItem.id,
          title: oldItem.title,
          modelName: oldItem.modelName,
          status: oldItem.status,
          lastMessageId: oldItem.lastMessageId,
          lastMessagePreview: oldItem.lastMessagePreview,
          lastActivityTime: oldItem.lastActivityTime,
          createTime: oldItem.createTime,
          updateTime: oldItem.updateTime,
          pinned: newPinnedStatus ? 1 : 0
        };
        this.infos[index] = updatedItem;
        
        // 可选：如果需要立即排序，也可以在这里进行本地重排
        // 这里简单起见，先更新状态，随后网络请求成功后会全量刷新列表
      }
    }

    ConversationApi.pinConversation(item.id, newPinnedStatus).then(success => {
      if (success) {
        promptAction.showToast({ message: newPinnedStatus ? '已置顶' : '已取消置顶' });
        this.refreshList(); // 最终以服务器数据为准
      } else {
        promptAction.showToast({ message: '操作失败' });
        // 失败回滚
        this.refreshList();
      }
    });
  }

  handleRename(item: ConversationVO) {
    this.renameValue = item.title;
    this.renameDialogController = new CustomDialogController({
      builder: RenameDialog({
        textValue: this.renameValue,
        confirm: (newValue: string) => {
          ConversationApi.renameConversation(item.id, newValue).then(success => {
            if (success) {
              promptAction.showToast({ message: '重命名成功' });
              this.refreshList();
            } else {
              promptAction.showToast({ message: '重命名失败' });
            }
          });
        }
      }),
      alignment: DialogAlignment.Center,
    });
    this.renameDialogController.open();
  }

  handleShare(item: ConversationVO) {
    promptAction.showActionMenu({
      title: '分享会话',
      buttons: [
        { text: '复制文本', color: '#000000' },
        { text: '导出文件(模拟)', color: '#000000' }
      ]
    }).then(data => {
      if (data.index === 0) {
        // 复制文本
        ConversationApi.getConversationMessages(item.id).then((messages: ChatMessageVO[] | null) => {
          if (messages && messages.length > 0) {
            let content = messages.map((msg: ChatMessageVO) => `${msg.role}: ${msg.content}`).join('\n\n');
            let systemPasteboard = pasteboard.getSystemPasteboard();
            let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
            systemPasteboard.setData(pasteData).then(() => {
              promptAction.showToast({ message: '已复制到剪贴板' });
            });
          } else {
            promptAction.showToast({ message: '暂无消息可分享' });
          }
        });
      } else if (data.index === 1) {
        // 导出文件 (模拟)
        promptAction.showToast({ message: '文件导出功能开发中' });
      }
    });
  }

  @Builder itemEnd(item: ConversationVO) {
    Row() {
      // 置顶
      Button({ type: ButtonType.Normal }) {
        Column() {
           SymbolGlyph($r(item.pinned === 1 ? 'sys.symbol.pin_slash' : 'sys.symbol.pin'))
            .fontSize(24)
            .fontColor([Color.White])
           Text(item.pinned === 1 ? '取消置顶' : '置顶').fontColor(Color.White).fontSize(10)
        }
      }
      .backgroundColor('#FF9800') // Orange
      .width(80)
      .height('100%')
      .onClick(() => {
        this.handlePin(item);
      })

      // 分享
      Button({ type: ButtonType.Normal }) {
        Column() {
           SymbolGlyph($r('sys.symbol.share'))
            .fontSize(24)
            .fontColor([Color.White])
           Text('分享').fontColor(Color.White).fontSize(10)
        }
      }
      .backgroundColor('#2196F3') // Blue
      .width(80)
      .height('100%')
      .onClick(() => {
        this.handleShare(item);
      })

      // 重命名
      Button({ type: ButtonType.Normal }) {
        Column() {
           SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(24)
            .fontColor([Color.White])
           Text('重命名').fontColor(Color.White).fontSize(10)
        }
      }
      .backgroundColor('#9E9E9E') // Grey
      .width(80)
      .height('100%')
      .onClick(() => {
        this.handleRename(item);
      })
    }
    .justifyContent(FlexAlign.End)
  }

  build() {
    Column() {
      if (this.infos!==null) {
        List() {
          ForEach(
            this.infos,
            (item: ConversationVO) => {
              ListItem() {
                this.historyItemBuilder(item)
              }
              .swipeAction({ end: this.itemEnd(item) }) // 添加侧滑菜单
              .onClick(() => {
                this.onClickEvent?.(item.id)
              })
            },
            (item: ConversationVO, index: number): string => {
              return item.id.toString()
            }
          )
        }
        .padding({ top: 8 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row() {
          Column({ space: 4 }) {
            SymbolGlyph($r(this.isAllChecked ? 'sys.symbol.checkmark_square_on_square_fill' :
              'sys.symbol.checkmark_square_on_square'))
              .fontSize($r('sys.float.Title_M'))
              .fontColor([$r(this.isAllChecked ? 'sys.color.font_emphasize' : 'sys.color.font_primary')])
            Text('全选')
              .fontSize($r('sys.float.Caption_M'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
          }
          .width('50%')
          .onClick(() => {
            this.isAllChecked = !this.isAllChecked
            this.isAllCheckClicked = this.isAllChecked
          })

          Column({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize($r('sys.float.Title_M'))
              .fontColor([$r('sys.color.font_primary')])
            Text('删除')
              .fontSize($r('sys.float.Caption_M'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
          }
          .width('50%')
          .margin({ top: 5, bottom: 5 })
          .opacity(this.deleteThreadIds.length ? 1 : 0.4)
          .enabled(this.deleteThreadIds.length > 0)
          .onClick(() => {
            if (this.deleteThreadIds.length) {
              this.deleteThreadIds.forEach(id => {
                ConversationApi.deleteConversation(id)
              })

              this.infos = this.infos?.filter(
                item => !this.deleteThreadIds.includes(item.id)
              )?? []
            }
          })
        }
        .width('100%')
        .visibility(this.isDeleted ? Visibility.Visible : Visibility.None)
      } else {
        this.noneResultComp()
      }
    }
    .margin({ bottom: 28 })
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }


  @Builder
  historyItemBuilder(item: ConversationVO){
    Column() {
      Text(this.getFormatTime(item.createTime, 'YYYY-MM-DD'))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Start)

      Row({ space: 10 }) {
        Checkbox()
          .width(20)
          .height(20)
          .visibility(this.isDeleted ? Visibility.Visible : Visibility.None)
          .select(this.isAllCheckClicked)
          .onChange((isChecked: boolean) => {
            if (isChecked) {
              this.deleteThreadIds.push(item.id)
            } else {
              this.deleteThreadIds.splice(this.deleteThreadIds.indexOf(item.id), 1)
            }
            if (this.deleteThreadIds.length === this.infos?.length) {
              this.isAllChecked = true
            } else {
              this.isAllChecked = false
            }
          })

        Text(item.lastMessagePreview)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .wordBreak(WordBreak.BREAK_ALL)
      }
      .height(24)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  noneResultComp() {
    Column() {
      Image($r('app.media.no_history_result'))
        .width(120)
        .height(120)
      Text('暂无历史')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 转化成需要格式的日期
   *
   * @param time 需要的时间
   * @param format 需要的时间格式
   */
  public getFormatTime(time: string | number | Date, format?: string): string {
    let historyTime = new Date(time).toString()
    let currentTime = new Date().toString()
    if (dayJs(historyTime).isSame(dayJs(currentTime), 'day')) {
      return '今天'
    }
    return dayJs.utc(historyTime).format(format)
  }
}