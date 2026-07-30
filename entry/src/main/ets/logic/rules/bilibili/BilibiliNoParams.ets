import { ParsedUrl, parseUrl, rebuildUrlWithQuery } from '../../../utils/LinkExtractor';

const BILIBILI_HOST_PATTERN = new RegExp('.+\\.bilibili\\.com');

const BILIBILI_RETAINED_PARAMS: string[] = [
  'business_id', 'business_type', 'itemsId', 'lottery_id', 'p', 'start_progress', 't',
];

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

  return rebuildUrlWithQuery(parsed, retainedPairs.join('&'));
}
