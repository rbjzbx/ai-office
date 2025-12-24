// 账号密码登录dto
export interface LoginDTO {
  userNo: string;
  password: string;
}

// 短信登录、绑定手机号、换绑手机号dto
export interface SmsDTO {
  mobile: string;
  code: string;
}

// 登录返回token
export interface TokenVO {
  token: string;
}
