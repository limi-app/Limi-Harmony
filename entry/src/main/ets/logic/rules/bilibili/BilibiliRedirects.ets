import { ParsedUrl, parseUrl } from '../../../utils/LinkExtractor';
import { getRedirectsUrl } from '../../../utils/HttpUtil';
import { isBilibiliNoParamsTarget, processBilibiliNoParamsUrl } from './BilibiliNoParams';

const BILIBILI_REDIRECT_TARGET_HOST: string[] = ['b23.tv'];

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
