import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HttpUtil';
const DOMAIN = 0x0000;

export async function getRedirectsUrl(url: string): Promise<string> {
  const httpRequest = http.createHttp();
  let firstRedirectUrl: string = '';

  httpRequest.on('headersReceive', (header: Object) => {
    const headerObj = header as Record<string, string>;
    const location = headerObj['Location'] ?? headerObj['location'] ?? '';
    if (location.length > 0 && firstRedirectUrl.length === 0) {
      firstRedirectUrl = location;
    }
  });

  try {
    await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        'User-Agent': 'Mozilla/5.0',
      },
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 10000,
    });

    if (firstRedirectUrl.length > 0) {
      return firstRedirectUrl;
    }

    return url;
  } catch (e) {
    hilog.error(DOMAIN, TAG, `HTTP error: ${JSON.stringify(e)}`);
    if (firstRedirectUrl.length > 0) {
      return firstRedirectUrl;
    }
    return url;
  } finally {
    httpRequest.off('headersReceive');
    httpRequest.destroy();
  }
}
