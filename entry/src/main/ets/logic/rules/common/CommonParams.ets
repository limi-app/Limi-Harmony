import { filterParams, ParsedUrl, parseUrl, rebuildUrlWithQuery } from '../../../utils/LinkExtractor';

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
  return rebuildUrlWithQuery(parsed, filteredQuery);
}
