import { AuthApi } from '../api/authApi';
import { UserApi } from '../api/userApi';
import { PromptAction, PersistenceV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { storageUtil, UserInfoModel, RouterUtils, RouterMap } from 'lib_common';

@Builder
export function LoginPageBuilder() {
  LoginPage()
}

@Component
struct LoginPage {
  @State user_no: string = 'admin';
  @State password: string = '123456';
  @State mobile: string = '';
  @State smsCode: string = '';
  @State loginType: 'password' | 'sms' = 'password';
  @State loading: boolean = false;
  @State countdown: number = 0; // 验证码倒计时
  @State canSendSms: boolean = true; // 是否可以发送验证码
  private timer: number = -1; // 定时器 ID
  // 获取当前 UI 上下文的 PromptAction 实例
  private promptAction: PromptAction = this.getUIContext().getPromptAction();

  // 组件即将销毁时清除定时器
  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
      // 标题
      Text('欢迎登录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 40 })

      // 登录方式切换
      Row({ space: 20 }) {
        Button('账号密码登录')
          .width('45%')
          .height(44)
          .fontSize(16)
          .onClick(() => this.loginType = 'password')
          .backgroundColor(this.loginType === 'password' ? '#007DFF' : '#F0F0F0')
          .fontColor(this.loginType === 'password' ? Color.White : '#666')

        Button('短信验证码登录')
          .width('45%')
          .height(44)
          .fontSize(16)
          .onClick(() => this.loginType = 'sms')
          .backgroundColor(this.loginType === 'sms' ? '#007DFF' : '#F0F0F0')
          .fontColor(this.loginType === 'sms' ? Color.White : '#666')
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 20, bottom: 30 })

      if (this.loginType === 'password') {
        // 账号密码登录表单
        TextInput({ placeholder: '请输入用户名' })
          .width('90%')
          .height(50)
          .fontSize(16)
          .onChange((value: string) => this.user_no = value)

        TextInput({ placeholder: '请输入密码' })
          .width('90%')
          .height(50)
          .fontSize(16)
          .type(InputType.Password)
          .onChange((value: string) => this.password = value)

        Button('登录')
          .width('90%')
          .height(50)
          .fontSize(18)
          .margin({ top: 30 })
          .onClick(() => this.handlePasswordLogin())
          .enabled(!this.loading)
      } else {
        // 短信验证码登录表单
        TextInput({ placeholder: '请输入手机号' })
          .width('90%')
          .height(50)
          .fontSize(16)
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((value: string) => this.mobile = value)

        Row({ space: 10 }) {
          TextInput({ placeholder: '请输入验证码' })
            .height(50)
            .fontSize(16)
            .layoutWeight(1)
            .type(InputType.Number)
            .maxLength(6)
            .onChange((value: string) => this.smsCode = value)

          Button(this.countdown > 0 ? `${this.countdown}秒后重试` : '获取验证码')
            .width(120)
            .height(50)
            .fontSize(14)
            .onClick(() => this.sendSmsCode())
            .enabled(this.canSendSms && this.mobile.length === 11 && !this.loading)
        }
        .width('90%')

        Button('登录')
          .width('90%')
          .height(50)
          .fontSize(18)
          .margin({ top: 30 })
          .onClick(() => this.handleSmsLogin())
          .enabled(!this.loading)
      }

      if (this.loading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 20 })
      }
    }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Start)
    }
    .hideTitleBar(true)
  }

  // 账号密码登录
  private async handlePasswordLogin() {
    if (!this.user_no || !this.password) {
      this.promptAction.openToast({
        message: '请输入用户名和密码',
        duration: 1500
      });
      return;
    }

    this.loading = true;

    try {
      const tokenVO = await AuthApi.passwordLogin({userNo: this.user_no, password: this.password });
      hilog.info(0x0000, 'LoginPage', `登录结果: ${JSON.stringify(tokenVO)}`);

      if (tokenVO && tokenVO.token) {
        // 保存 Token 到本地存储
        await storageUtil.set('token', tokenVO.token);

        // 获取用户信息
        const userInfo = await UserApi.getUserInfo();
        if (userInfo) {
          await storageUtil.setObject('userInfo', userInfo);
          
          const userInfoModel = PersistenceV2.connect(UserInfoModel, () => new UserInfoModel())!;
          userInfoModel.isLogin = true;
          userInfoModel.authorId = userInfo.id ? userInfo.id.toString() : '';
          userInfoModel.authorNickName = userInfo.nickname || '';
          userInfoModel.authorIcon = userInfo.avatar || '';
          userInfoModel.authorPhone = userInfo.phone || '';
          PersistenceV2.save(UserInfoModel);
        }

        // 更新全局登录状态
        AppStorage.setOrCreate('isLoggedIn', true);

        this.promptAction.openToast({
          message: '登录成功',
          duration: 1500
        });

        // 延迟跳转,确保状态已更新
        setTimeout(() => {
          this.loading = false;
          // 获取登录前的页面索引
          const beforeLoginIndex = AppStorage.get<number>('beforeLoginPageIndex') || 0;
          // 设置主页面的 Tab 索引
          AppStorage.set<number>('currentTabIndex', beforeLoginIndex);
          // 清除保存的索引
          AppStorage.set<number>('beforeLoginPageIndex', 0);
          // 跳转到主页面
          RouterUtils.replacePathByName(RouterMap.INDEX_PAGE);
        }, 500);
      } else {
        this.loading = false;
        this.promptAction.openToast({
          message: '登录失败',
          duration: 2000
        });
      }
    } catch (error) {
      this.loading = false;
      hilog.error(0x0000, 'LoginPage', `登录异常: ${error}`);
      this.promptAction.openToast({
        message: '登录异常,请重试',
        duration: 2000
      });
    }
  }

  // 短信验证码登录
  private async handleSmsLogin() {
    if (!this.mobile || !this.smsCode) {
      this.promptAction.openToast({
        message: '请输入手机号和验证码',
        duration: 1500
      });
      return;
    }

    // 验证手机号格式
    const mobileReg = /^1[3-9]\d{9}$/;
    if (!mobileReg.test(this.mobile)) {
      this.promptAction.openToast({
        message: '请输入正确的手机号',
        duration: 1500
      });
      return;
    }

    this.loading = true;

    try {
      const tokenVO = await AuthApi.smsLogin({ phone: this.mobile, code: this.smsCode });
      hilog.info(0x0000, 'LoginPage', `短信登录结果: ${JSON.stringify(tokenVO)}`);

      if (tokenVO && tokenVO.token) {
        // 保存 Token 到本地存储
        await storageUtil.set('token', tokenVO.token);

        // 获取用户信息
        const userInfo = await UserApi.getUserInfo();
        if (userInfo) {
          await storageUtil.setObject('userInfo', userInfo);

          const userInfoModel = PersistenceV2.connect(UserInfoModel, () => new UserInfoModel())!;
          userInfoModel.isLogin = true;
          userInfoModel.authorId = userInfo.id ? userInfo.id.toString() : '';
          userInfoModel.authorNickName = userInfo.nickname || '';
          userInfoModel.authorIcon = userInfo.avatar || '';
          userInfoModel.authorPhone = userInfo.phone || '';
          PersistenceV2.save(UserInfoModel);
        }

        // 更新全局登录状态
        AppStorage.setOrCreate('isLoggedIn', true);

        this.promptAction.openToast({
          message: '登录成功',
          duration: 1500
        });

        // 延迟跳转,确保状态已更新
        setTimeout(() => {
          this.loading = false;
          // 获取登录前的页面索引
          const beforeLoginIndex = AppStorage.get<number>('beforeLoginPageIndex') || 0;
          // 设置主页面的 Tab 索引
          AppStorage.set<number>('currentTabIndex', beforeLoginIndex);
          // 清除保存的索引
          AppStorage.set<number>('beforeLoginPageIndex', 0);
          // 跳转到主页面
          RouterUtils.replacePathByName(RouterMap.INDEX_PAGE);
        }, 500);
      } else {
        this.loading = false;
        this.promptAction.openToast({
          message: '登录失败',
          duration: 2000
        });
      }
    } catch (error) {
      this.loading = false;
      hilog.error(0x0000, 'LoginPage', `短信登录异常: ${error}`);
      this.promptAction.openToast({
        message: '登录异常,请重试',
        duration: 2000
      });
    }
  }

  // 发送短信验证码
  private async sendSmsCode() {
    // 验证手机号格式
    const mobileReg = /^1[3-9]\d{9}$/;
    if (!mobileReg.test(this.mobile)) {
      this.promptAction.openToast({
        message: '请输入正确的手机号',
        duration: 1500
      });
      return;
    }

    this.loading = true;
    try {
      this.loading = true;
      const result = await AuthApi.sendSmsCode({ phone: this.mobile });
      this.loading = false;

      // ✅ 后端约定：返回 null 表示成功
      if (result === null) {
        this.promptAction.openToast({
          message: '验证码发送成功',
          duration: 2000
        });

        // 开始倒计时
        this.startCountdown();
      } else {
        // 理论上不会进，兜底处理
        this.promptAction.openToast({
          message: '验证码发送失败',
          duration: 2000
        });
      }
    } catch (error) {
      this.loading = false;
      hilog.error(0x0000, 'LoginPage', `发送验证码异常: ${JSON.stringify(error)}`);
      this.promptAction.openToast({
        message: '发送异常，请重试',
        duration: 2000
      });
    }

  }

  // 开始倒计时
  private startCountdown() {
    this.countdown = 60;
    this.canSendSms = false;

    this.timer = setInterval(() => {
      if (this.countdown > 0) {
        this.countdown--;
      } else {
        this.canSendSms = true;
        clearInterval(this.timer);
        this.timer = -1;
      }
    }, 1000);
  }
}
