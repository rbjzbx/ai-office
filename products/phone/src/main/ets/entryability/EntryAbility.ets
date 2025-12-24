import {
  AbilityConstant,
  UIAbility,
  Want,
  Configuration,
  ConfigurationConstant
} from '@kit.AbilityKit';

import { window, KeyboardAvoidMode } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { BundleUtils, Logger, storageUtil } from 'lib_common';
import { NetworkUtils } from '../common/NetworkUtils';
import { WindowUtils } from '../common/WindowUtils';
import { AppUtils } from '../common/AppUtils';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  // 标记是否需要执行 windowStage.loadContent
  private needLoadContent: boolean = false;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    await storageUtil.init(this.context);
    Logger.info(TAG, 'Ability onCreate');
    this.setNeedLoadContent(true);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onNewWant');
    this.setNeedLoadContent(false);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    Logger.info(TAG, 'Ability onWindowStageCreate');

    const token = await storageUtil.get('token');
    const isLoggedIn = token != null && token !== '';

    AppStorage.setOrCreate('isLoggedIn', isLoggedIn);
    AppStorage.setOrCreate('currentTabIndex', 0);
    AppStorage.setOrCreate('beforeLoginPage', 0);
    if (AppStorage.get('hasAgreePrivacy') === undefined) {
      AppStorage.set('hasAgreePrivacy', false);
    }

    this.handleWindowStageCreateOrRestore(windowStage);
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
    Logger.info(TAG, 'Ability onWindowStageRestore');
    if (this.needLoadContent) {
      this.handleWindowStageCreateOrRestore(windowStage);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppUtils.listenConfigurationUpdate(newConfig);
  }

  onWindowStageDestroy(): void {
    Logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
    WindowUtils.offAvoidAreaChange();
    NetworkUtils.unRegisterNetwork();
  }

  handleWindowStageCreateOrRestore(windowStage: window.WindowStage) {
    WindowUtils.setWinConfig(windowStage);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error(
          TAG,
          'Failed to load the content. Cause: ' + JSON.stringify(err)
        );
        return;
      }

      Logger.info(TAG, 'Succeeded in loading the content.');

      windowStage
        .getMainWindowSync()
        .getUIContext()
        .setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);

      AppUtils.setAppTheme();
      AppUtils.setColorMode();
      BundleUtils.getBundleInfo();

      // 判断是否是模拟器
      const productMode = deviceInfo.productModel;
      if (productMode !== 'emulator') {
        NetworkUtils.initNetwork();
      }
    });
  }

  setNeedLoadContent(value: boolean) {
    this.needLoadContent = value;
  }
}
