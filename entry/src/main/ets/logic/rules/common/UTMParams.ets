import { parseUrl, ParsedUrl, rebuildUrlWithQuery, filterParams } from '../../../utils/LinkExtractor';

const UTM_TARGET_PARAMS: string[] = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'];

export function processUTMParams(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const filteredQuery = filterParams(parsed.query, UTM_TARGET_PARAMS);
  return rebuildUrlWithQuery(parsed, filteredQuery);
}
