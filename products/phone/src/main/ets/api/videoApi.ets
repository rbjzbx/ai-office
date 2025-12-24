import { TextToVideoDTO, TextToVideoResult } from "../type/VideoType";
import { AxiosUtil } from "../utils/AxiosUtils";

export class VideoApi {
  static textToVideo(dto:TextToVideoDTO) {
    return AxiosUtil.post<TextToVideoResult>(
      '/ai/text-to-video',dto
    )
  }
}