import { ParsedUrl, parseUrl } from '../../../utils/LinkExtractor';
import { getRedirectsUrl } from '../../../utils/HttpUtil';
import { isBilibiliNoParamsTarget, processBilibiliNoParamsUrl } from './BilibiliNoParams';

const BILIBILI_REDIRECT_TARGET_HOST: string[] = ['b23.tv'];
const MAX_REDIRECT_FOLLOW: number = 10;

export function getBilibiliRedirectTargetHost(): string[] {
  return BILIBILI_REDIRECT_TARGET_HOST;
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

  // 跟随重定向链，直到到达 bilibili.com 或无更多重定向
  // b23.tv 通常先 301 到 HTTPS（同 host），再 302 到 www.bilibili.com
  let currentUrl = url;
  for (let i = 0; i < MAX_REDIRECT_FOLLOW; i++) {
    const redirectUrl = await getRedirectsUrl(currentUrl);
    if (redirectUrl === currentUrl) {
      break;
    }
    currentUrl = redirectUrl;
    const redirectParsed: ParsedUrl | null = parseUrl(currentUrl);
    if (redirectParsed !== null && isBilibiliNoParamsTarget(redirectParsed.host)) {
      return processBilibiliNoParamsUrl(currentUrl);
    }
  }

  return url;
}
