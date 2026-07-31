import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HttpUtil';
const DOMAIN = 0x0000;

export async function fetchText(url: string): Promise<string> {
  const httpRequest = http.createHttp();
  try {
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 10000,
    });
    const code = response.responseCode;
    if (code < 200 || code >= 300) {
      throw new Error(`Unexpected response code: ${code}`);
    }
    return response.result as string;
  } catch (e) {
    if (e instanceof Error) {
      const message = e.message ?? 'HTTP request failed';
      const code = (e as BusinessError).code;
      hilog.error(DOMAIN, TAG, `fetchText failed: code=${code}, message=${message}`);
      throw new Error(message);
    }
    hilog.error(DOMAIN, TAG, `fetchText failed: ${JSON.stringify(e)}`);
    throw new Error('HTTP request failed');
  } finally {
    httpRequest.destroy();
  }
}

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
