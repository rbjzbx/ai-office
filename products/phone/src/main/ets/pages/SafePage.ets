import { CommonConstants } from 'lib_common';
import { SafePageVM } from '../viewmodels/SafePageVM';

@Builder
export function SafePageBuilder() {
  SafePage()
}

@ComponentV2
struct SafePage {
  vm: SafePageVM = new SafePageVM();

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Image($r('app.media.icon_flip_foreground'))
              .width(72)
              .draggable(false)
              .margin({ top: 136 })

            // ✅ 应用名称
            Text('校园 AI 助手')
              .fontSize($r('sys.float.Title_L'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: CommonConstants.PADDING_XXL,
                bottom: 2,
              })

            // ✅ 业务描述
            Text('为您提供校园导航、智能翻译、图片文字识别及快递查询等 AI 服务')
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        Column() {
          Image($r('app.media.ic_security'))
            .width($r('app.float.normal_img_size'))
            .draggable(false)

          // ✅ 隐私合规说明（核心改动）
          Text() {
            Span('校园 AI 助手在运行过程中需要联网，并在您使用校园导航、翻译、OCR 识别、快递查询等功能时，调用相关系统权限与必要信息，以便为您提供对应服务。我们仅在您主动使用具体功能时，才会收集和使用相关信息。详情请参阅')
              .fontColor($r('sys.color.font_secondary'))

            Span('《校园 AI 助手隐私政策与权限说明》')
              .fontColor($r('app.color.app_theme'))
              .onClick(() => {
                this.vm.privacyClick();
              })

            Span('。')
              .fontColor($r('sys.color.font_secondary'))
          }
          .fontSize($r('sys.float.Caption_M'))
          .margin({
            top: CommonConstants.PADDING_L,
            bottom: 6,
          })

          // ✅ 用户确认提示
          Text('请您仔细阅读上述说明，点击“同意”即表示您已阅读并同意我们按照说明为您提供校园 AI 助手服务。')
            .fontSize($r('sys.float.Caption_M'))
            .fontColor($r('sys.color.font_secondary'))

          Row({ space: CommonConstants.SPACE_M }) {
            Button('取消')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .role(ButtonRole.NORMAL)
              .height(40)
              .layoutWeight(1)
              .onClick(() => {
                this.vm.cancelBtnClick();
              })

            Button('同意')
              .height(40)
              .layoutWeight(1)
              .onClick(() => {
                this.vm.agreeBtnClick();
              })
          }
          .padding({
            top: CommonConstants.PADDING_L,
            bottom: CommonConstants.PADDING_L,
          })
        }
        .margin({
          top: CommonConstants.PADDING_M,
        })
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .padding({
        left: CommonConstants.PADDING_PAGE,
        right: CommonConstants.PADDING_PAGE,
        bottom: this.vm.windowModel.windowBottomPadding,
      })
    }
    .hideTitleBar(true)
  }
}
