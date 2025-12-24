import { storageUtil } from 'lib_common';
import router from '@ohos.router';

export async function restoreLogin() {
  const token = await storageUtil.get('token', '');

  if (token) {
    AppStorage.setOrCreate('isLoggedIn', true);
    router.replaceUrl({ url: 'pages/Index' });
  } else {
    router.replaceUrl({ url: 'pages/LoginPage' });
  }
}
