import { MessageVO, StreamChatRequest } from "../type/MessageType";
import { AxiosUtil } from "../utils/AxiosUtils";
import EventSource from "../utils/EventSourceUtil";
import { http } from "@kit.NetworkKit";

export class MessageApi {
  static async getConversationMessages(conversationId:number): Promise<MessageVO[]| null> {
    try {
    const response = await AxiosUtil.get<MessageVO[]>(`/ai/conversation/${conversationId}`);
      if (response.data.code === 0) {
        return response.data.data;
      } else {
        console.error(`获取用户会话列表，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('获取用户会话列表异常：', error);
      return null;
    }
  }
}