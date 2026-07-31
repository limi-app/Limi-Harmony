import { PreferenceItem } from '../../components/PreferenceGroup';

export class LimiHistory implements PreferenceItem {
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
