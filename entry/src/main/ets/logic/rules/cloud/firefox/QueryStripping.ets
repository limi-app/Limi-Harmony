import { ParsedUrl, parseUrl, rebuildUrlWithQuery } from '../../../../utils/LinkExtractor';

export class FirefoxRuleKeys {
  static readonly QUERY_STRIPPING_STRIP_LIST: string = 'cloud_query_stripping_strip_list';
  static readonly QUERY_STRIPPING_ALLOW_LIST: string = 'cloud_query_stripping_allow_list';
  static readonly QUERY_STRIPPING_LAST_MODIFIED: string = 'cloud_query_stripping_last_modified';
}

export interface QueryStrippingRecord {
  stripList: string[];
  allowList: string[];
  last_modified: number;
}

export interface QueryStrippingResponse {
  data: QueryStrippingRecord[];
}

export class QueryStrippingData {
  stripList: string[] = [];
  allowList: string[] = [];
  lastModified: number = 0;
}

export function parseQueryStrippingRecords(body: string): QueryStrippingData {
  const result = new QueryStrippingData();
  const response = JSON.parse(body) as QueryStrippingResponse;
  const stripList: string[] = [];
  const allowList: string[] = [];
  let lastModified: number = 0;
  for (let i = 0; i < response.data.length; i++) {
    const record = response.data[i];
    for (let j = 0; j < record.stripList.length; j++) {
      pushIfAbsent(stripList, record.stripList[j].toLowerCase());
    }
    for (let j = 0; j < record.allowList.length; j++) {
      pushIfAbsent(allowList, record.allowList[j].toLowerCase());
    }
    if (record.last_modified > lastModified) {
      lastModified = record.last_modified;
    }
  }
  result.stripList = stripList;
  result.allowList = allowList;
  result.lastModified = lastModified;
  return result;
}

export function processQueryStripping(url: string, stripList: string[], allowList: string[]): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const host = parsed.host.toLowerCase();
  if (containsIgnoreCase(allowList, host)) {
    return url;
  }
  return rebuildUrlWithQuery(parsed, filterStripParams(parsed.query, stripList));
}

function containsIgnoreCase(list: string[], value: string): boolean {
  for (let i = 0; i < list.length; i++) {
    if (list[i].toLowerCase() === value) {
      return true;
    }
  }
  return false;
}

function filterStripParams(query: string, stripList: string[]): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    if (stripList.indexOf(key.toLowerCase()) < 0) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}

function pushIfAbsent(list: string[], value: string): void {
  if (list.indexOf(value) < 0) {
    list.push(value);
  }
}
