import { parseUrl, buildUrl, ParsedUrl } from '../../../utils/LinkExtractor';

const COMMON_TARGET_PARAMS: string[] = [
  'gclid', 'dclid', 'wbraid', 'gbraid', 'gad_source', 'gad_campaignid', 'gclsrc',
  'fbclid', 'ttclid', 'msclkid', 'li_fat_id', 'twclid', 'epik', 'ScCid',
  'yclid', 'ymclid', 'sznclid', 'mc_cid', 'mc_eid', 'wickedid', 'tblclid',
  'dicbo', 'extclid', 'aa_campaignid', 'aa_adgroupid', 'maas',
  'traffic_type', 'traffic_source',
  'unique_aff_sub1', 'unique_aff_sub2', 'unique_aff_sub3', 'unique_aff_sub4', 'unique_aff_sub5',
  'ha_source', 'ha_sourceId', 'bd_vid',
];

export function processCommonParams(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const filteredQuery = filterParams(parsed.query, COMMON_TARGET_PARAMS);
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: filteredQuery,
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}

export function processUTMParams(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const utmParams: string[] = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'];
  const filteredQuery = filterParams(parsed.query, utmParams);
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: filteredQuery,
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}

export function processUTMParamsEnhanced(url: string): string {
  const parsed: ParsedUrl | null = parseUrl(url);
  if (parsed === null) {
    return url;
  }
  const filteredQuery = filterParamsByPrefix(parsed.query, 'utm_');
  const result: ParsedUrl = {
    protocol: parsed.protocol,
    host: parsed.host,
    port: parsed.port,
    path: parsed.path,
    query: filteredQuery,
    fragment: parsed.fragment,
  };
  return buildUrl(result);
}

function filterParams(query: string, targetParams: string[]): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    let found = false;
    for (let j = 0; j < targetParams.length; j++) {
      if (key === targetParams[j]) {
        found = true;
        break;
      }
    }
    if (!found) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}

function filterParamsByPrefix(query: string, prefix: string): string {
  if (query.length === 0) {
    return '';
  }
  const pairs = query.split('&');
  const kept: string[] = [];
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    if (!key.startsWith(prefix)) {
      kept.push(pair);
    }
  }
  return kept.join('&');
}
