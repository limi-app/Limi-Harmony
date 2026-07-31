export class LimiHistory {
  id: number = 0;
  originUrl: string = '';
  processedUrl: string = '';
  datetime: string = '';

  static create(originUrl: string, processedUrl: string, datetime: string): LimiHistory {
    const h = new LimiHistory();
    h.originUrl = originUrl;
    h.processedUrl = processedUrl;
    h.datetime = datetime;
    return h;
  }
}
