import { RouterMap, RouterUtils, WindowModel } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { AppStorageV2 } from '@kit.ArkUI';
import { VideoApi } from '../../api/videoApi';
import { TextToVideoDTO } from '../../type/VideoType';
@Builder
export function TextToVideoPageBuilder() {
  TextToVideoPage()
}
@ComponentV2
export struct TextToVideoPage {
  @Local prompt: string = '';
  @Local loading: boolean = false;
  @Local videoUrl: string = '';
  @Local windowModel: WindowModel =
    AppStorageV2.connect(WindowModel, () => new WindowModel())!;
  @Local videoController: VideoController = new VideoController();

  // ✅ 核心方法：调用后端
  async generateVideo() {
    if (!this.prompt || this.loading) {
      return;
    }

    this.loading = true;
    this.videoUrl = '';

    try {
      const dto: TextToVideoDTO = {
        text: this.prompt,
        model: 'wanx2.1-t2v-turbo'
      };

      const res = await VideoApi.textToVideo(dto);

      if (res.data.success && res.data.data?.videoUrl) {
        this.videoUrl = res.data.data.videoUrl;
      } else {
        this.getUIContext().getPromptAction().openToast({
          message: res.data.message || '生成失败',
          duration: 2000
        });
      }
    } catch (e) {
      this.getUIContext().getPromptAction().openToast({
        message: '视频生成失败，请稍后重试',
        duration: 2000
      });
    } finally {
      this.loading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部导航
        NavHeaderBar({
          title: '文本生成视频'
        })

        // 内容区
        Column({ space: 16 }) {
          // 输入框
          TextArea({
            placeholder: '请输入视频描述，例如：夕阳下的海边，一只小狗在奔跑',
            text: $$this.prompt
          })
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_primary'))
            .placeholderColor($r('sys.color.font_secondary'))
            .borderRadius(8)
            .padding(12)
            .constraintSize({ minHeight: 120 })

          // 生成按钮
          Button(this.loading ? '生成中...' : '生成视频')
            .width('100%')
            .height(44)
            .enabled(!!this.prompt && !this.loading)
            .onClick(() => this.generateVideo())

          // loading
          if (this.loading) {
            Row() {
              LoadingProgress()
                .width(32)
                .height(32)
            }
            .justifyContent(FlexAlign.Center)
          }

          // 视频展示
          if (this.videoUrl) {
            Column({ space: 8 }) {
              Text('生成结果')
                .fontSize($r('sys.float.Subtitle_M'))
                .fontWeight(FontWeight.Bold)

              Video({
                src: this.videoUrl,
                controller: this.videoController
              })
                .width('100%')
                .height(220)
                .borderRadius(8)
                .controls(true)
                .autoPlay(true)
            }
          }
        }
        .padding(16)
        .layoutWeight(1)

        // 底部安全区
        Blank().height(this.windowModel.windowBottomPadding)
      }
      .height('100%')
      .expandSafeArea([SafeAreaType.KEYBOARD])
    }
    .hideTitleBar(true)
  }
}
