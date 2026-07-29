import { parseUrl, buildUrl, ParsedUrl } from '../../../utils/LinkExtractor';
import { getRedirectsUrl } from '../../../utils/HttpUtil';

const BILIBILI_REDIRECT_TARGET_HOST: string[] = ['b23.tv'];

const BILIBILI_HOST_PATTERN = new RegExp('.+\\.bilibili\\.com');

const BILIBILI_RETAINED_PARAMS: string[] = [
  'business_id', 'business_type', 'itemsId', 'lottery_id', 'p', 'start_progress', 't',
];

export function getBilibiliRedirectTargetHost(): string[] {
  return BILIBILI_REDIRECT_TARGET_HOST;
}

export function isBilibiliNoParamsTarget(host: string): boolean {
  return BILIBILI_HOST_PATTERN.test(host.toLowerCase());
}

export function processBilibiliNoParamsUrl(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }

  const retainedPairs: string[] = [];
  if (parsed.query.length > 0) {
    const pairs = parsed.query.split('&');
    for (let i = 0; i < pairs.length; i++) {
      const eqIdx = pairs[i].indexOf('=');
      const key = eqIdx >= 0 ? pairs[i].substring(0, eqIdx) : pairs[i];
      if (BILIBILI_RETAINED_PARAMS.indexOf(key) < 0) {
        continue;
      }
      if (key === 'p') {
        const value = eqIdx >= 0 ? pairs[i].substring(eqIdx + 1) : '';
        if (value === '1') {
          continue;
        }
      }
      retainedPairs.push(pairs[i]);
    }
  }

  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: retainedPairs.join('&'),
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}

export async function processBilibiliRedirectUrl(url: string): Promise<string> {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const host = parsed.host.toLowerCase();
  let isRedirectTarget = false;
  for (let i = 0; i < BILIBILI_REDIRECT_TARGET_HOST.length; i++) {
    if (host === BILIBILI_REDIRECT_TARGET_HOST[i].toLowerCase()) {
      isRedirectTarget = true;
      break;
    }
  }
  if (!isRedirectTarget) {
    return url;
  }

  const redirectsUrl = await getRedirectsUrl(url);

  const redirectParsed: ParsedUrl | null = parseUrl(redirectsUrl);
  if (redirectParsed === null) {
    return url;
  }

  if (!isBilibiliNoParamsTarget(redirectParsed.host)) {
    return url;
  }

  return processBilibiliNoParamsUrl(redirectsUrl);
}
