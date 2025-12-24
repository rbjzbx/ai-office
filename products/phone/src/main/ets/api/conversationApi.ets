import { Conversation, ConversationCreateDTO, ConversationVO, ChatMessageVO } from "../type/ConversationType";
import { AxiosUtil } from "../utils/AxiosUtils";

export class ConversationApi {
  /**
   * 获取会话列表
   * @param {string} [cursor] 分页游标, 第一页不传, 第二页取第一页返回的next_cursor, 以此类推
   * @param {number} [limit] 每页大小, 默认为20
   * @returns {Promise<Conversation[]>}
   */
  static async getUserConversations(): Promise<ConversationVO[]| null> {
    try {
      const response = await AxiosUtil.get<ConversationVO[]>('/ai');
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
  static async deleteConversation(conversationId:number): Promise<string| null> {
    try {
      const response = await AxiosUtil.delete<string>(`/ai/${conversationId}`);
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
  static async createUserConversation(dto: ConversationCreateDTO): Promise<Conversation| null> {
    try {
      const response = await AxiosUtil.post<Conversation>('/ai', dto);
      if (response.data.code === 0) {
        return response.data.data;
      } else {
        console.error(`创建会话失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('创建会话异常：', error);
      return null;
    }
  }

  static async pinConversation(id: number, isPinned: boolean): Promise<boolean> {
    try {
      const response = await AxiosUtil.post<string>(`/ai/${id}/pin?isPinned=${isPinned}`);
      return response.data.code === 0;
    } catch (error) {
      console.error('置顶会话异常：', error);
      return false;
    }
  }

  static async renameConversation(id: number, newTitle: string): Promise<boolean> {
    try {
      const response = await AxiosUtil.post<string>(`/ai/${id}/rename?newTitle=${encodeURIComponent(newTitle)}`);
      return response.data.code === 0;
    } catch (error) {
      console.error('重命名会话异常：', error);
      return false;
    }
  }

  static async getConversationMessages(id: number): Promise<ChatMessageVO[] | null> {
    try {
      const response = await AxiosUtil.get<ChatMessageVO[]>(`/ai/conversation/${id}`);
      if (response.data.code === 0) {
        return response.data.data;
      }
      return null;
    } catch (error) {
      console.error('获取会话消息异常：', error);
      return null;
    }
  }
}