export interface MessageVO {
  id:number ;
  conversationId:number ;
  content:string ;
  modelName:string ;
  role:string ;
  status:number;
  hasThinking:number;
  thinkingContent:string;
  hasWebSearch:number;
  createTime:string;
  updateTime:string;
}
export interface StreamChatRequest{
  content:string;
  conversationId:number;
  modelName:string;
  enableThanking:boolean;
}