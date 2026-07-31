import { fetchText } from '../../../utils/HttpUtil';
import { PreferencesHelper } from '../../../utils/PreferencesHelper';
import { parseQueryStrippingRecords, QueryStrippingData } from './QueryStripping';

export class CloudRuleKeys {
  static readonly QUERY_STRIPPING_STRIP_LIST: string = 'cloud_query_stripping_strip_list';
  static readonly QUERY_STRIPPING_ALLOW_LIST: string = 'cloud_query_stripping_allow_list';
  static readonly QUERY_STRIPPING_LAST_MODIFIED: string = 'cloud_query_stripping_last_modified';
}

const QUERY_STRIPPING_URL: string =
  'https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/query-stripping/records';

export async function syncQueryStripping(): Promise<void> {
  const body = await fetchText(QUERY_STRIPPING_URL);
  const data = parseQueryStrippingRecords(body);
  PreferencesHelper.setStringArray(CloudRuleKeys.QUERY_STRIPPING_STRIP_LIST, data.stripList);
  PreferencesHelper.setStringArray(CloudRuleKeys.QUERY_STRIPPING_ALLOW_LIST, data.allowList);
  PreferencesHelper.setLong(CloudRuleKeys.QUERY_STRIPPING_LAST_MODIFIED, data.lastModified);
}

export function getCachedQueryStripping(): QueryStrippingData {
  const data = new QueryStrippingData();
  data.stripList = PreferencesHelper.getStringArray(CloudRuleKeys.QUERY_STRIPPING_STRIP_LIST, []);
  data.allowList = PreferencesHelper.getStringArray(CloudRuleKeys.QUERY_STRIPPING_ALLOW_LIST, []);
  data.lastModified = PreferencesHelper.getLong(CloudRuleKeys.QUERY_STRIPPING_LAST_MODIFIED, 0);
  return data;
}
