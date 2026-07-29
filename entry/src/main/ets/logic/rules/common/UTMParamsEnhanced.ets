import { parseUrl, ParsedUrl, rebuildUrlWithQuery, filterParamsByPrefix } from '../../../utils/LinkExtractor';

export function processUTMParamsEnhanced(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const filteredQuery = filterParamsByPrefix(parsed.query, 'utm_');
  return rebuildUrlWithQuery(parsed, filteredQuery);
}
