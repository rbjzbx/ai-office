import { RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { CopilotHistory } from '../../components/CopilotHistory';

@Builder
export function ChatHistoryPageBuilder() {
  ChatHistoryPage()
}

@ComponentV2
export struct ChatHistoryPage {
  build() {
    NavDestination() {
      Column() {
        NavHeaderBar({
          title: '历史对话'
        })
        CopilotHistory({
          onClickEvent: (id:number) => {
            RouterUtils.pop(id);
          }
        }).padding({ left: 16, right: 16, bottom: 16 })
          .layoutWeight(1)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .height('100%')
    }.hideTitleBar(true)
  }
}