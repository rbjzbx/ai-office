export interface ConversationVO {
  id: number;
  title: string;
  modelName:string ;
  status:number ;
  lastMessageId:number ;
  lastMessagePreview:string ;
  lastActivityTime:string ;
  createTime:string ;
  updateTime: string;
  pinned?: number;
}

export interface ChatMessageVO {
  id: number;
  conversationId: number;
  role: string;
  content: string;
  type: string;
  createTime: string;
}

export interface ConversationCreateDTO {
title:string ;
modelName:string ;
}
export interface Conversation {
  id: number;
  title: string;
  userId: number;
  modelName: string;
  messageCount: number;
  tokenCount: number;
  status: number;
  lastMessageId: number;
  lastMessagePreview: string;
  lastActivityTime: string;
  createTime: string;
  updateTime: string;
  deleted?: number;
}