import { parseUrl, buildUrl, ParsedUrl } from '../../../utils/LinkExtractor';
import { getRedirectsUrl } from '../../../utils/HttpUtil';

const BILIBILI_REDIRECT_TARGET_HOST: string[] = ['b23.tv'];

const BILIBILI_ALLOWED_HOST: string[] = [
  'www.bilibili.com', 'bilibili.com', 'm.bilibili.com', 'show.bilibili.com',
  'space.bilibili.com', 'live.bilibili.com', 'bilibili.cn', 'bilibili.tv',
  'www.bilibili.cn', 'www.bilibili.tv', 'bangumi.bilibili.com',
  'n.bilibili.com', 'miniapp.bilibili.com',
];

export function getBilibiliRedirectTargetHost(): string[] {
  return BILIBILI_REDIRECT_TARGET_HOST;
}

export function getBilibiliNoParamsTargetHost(): string[] {
  return BILIBILI_ALLOWED_HOST;
}

export function processBilibiliNoParamsUrl(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: '',
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
  const redirectHost = redirectParsed.host.toLowerCase();

  let isAllowed = false;
  for (let i = 0; i < BILIBILI_ALLOWED_HOST.length; i++) {
    if (redirectHost === BILIBILI_ALLOWED_HOST[i].toLowerCase()) {
      isAllowed = true;
      break;
    }
  }
  if (!isAllowed) {
    return url;
  }

  return processBilibiliNoParamsUrl(redirectsUrl);
}
