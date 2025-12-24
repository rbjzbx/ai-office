/**
 * 用户信息 VO (与后端接口对应)
 */
export interface UserVO {
  id: number;
  userNo: string;
  nickname: string;
  avatar: string;
  college: string;
  email: string;
  dept: string;
  phone: string;
  password: string;
  role: string;
  status: number; }
export interface PhoneDTO {
  phone: string;
}