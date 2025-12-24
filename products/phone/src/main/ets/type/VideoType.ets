export interface TextToVideoResult {
  videoUrl: string;
  textLength: number;
  model: string;
}
export interface TextToVideoDTO {
  text: string;
  model?: string;
}