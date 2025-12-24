import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "@ohos/axios";
import { storageUtil } from "lib_common";
import { BaseResponse } from "../type/CommonType";

export const axiosInstance = axios.create({
  // baseURL: 'http://192.168.3.83:8080',
  baseURL: '10.0.2.2:8080',
  timeout: 600000,
  headers: {}
})

// 请求拦截器：添加 Authorization 头部
axiosInstance.interceptors.request.use(
  async (config: InternalAxiosRequestConfig): Promise<InternalAxiosRequestConfig> => {
    try {
      // 获取 token（可能在 storageUtil 初始化前被调用）
      const token = await storageUtil.get('token');
      if (token) {
        const tokenString = token ? token.toString() : '';
        config.headers.set('Authorization', `Bearer ${tokenString}`);
      }
    } catch (error) {
      // 如果 storageUtil 未初始化，忽略错误继续请求
      console.warn('获取 token 失败，可能 storageUtil 未初始化:', error);
    }
    return config;
  },
  (error: AxiosError): Promise<AxiosError> => {
    return Promise.reject(error);
  }
);


axiosInstance.interceptors.response.use((response: AxiosResponse) => {
  return response
}, (error: AxiosError) => {
  return Promise.reject(error)
})


export type ResType<T> = AxiosResponse<BaseResponse<T>>

export class AxiosUtil {
  static get<T>(url: string, params?: object): Promise<ResType<T>> {
    return axiosInstance.get<null, ResType<T>>(url, { params })
  }

  static post<T>(url: string, data?: object): Promise<ResType<T>> {
    return axiosInstance.post<null, ResType<T>>(url, data)
  }

  static put<T>(url: string, data?: object): Promise<ResType<T>> {
    return axiosInstance.put<null, ResType<T>>(url, data)
  }

  static delete<T>(url: string, params?: object): Promise<ResType<T>> {
    return axiosInstance.delete<null, ResType<T>>(url, { params })
  }
  static postWithParams<T>(url: string, params: object): Promise<ResType<T>> {
    return axiosInstance.post<null, ResType<T>>(url, null, { params })
  }
}