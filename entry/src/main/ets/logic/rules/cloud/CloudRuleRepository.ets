import { fetchText } from '../../../utils/HttpUtil';
import { PreferencesHelper } from '../../../utils/PreferencesHelper';
import { FirefoxRuleKeys, QueryStrippingData, parseQueryStrippingRecords } from './firefox/QueryStripping';
import { BraveQueryRule } from './brave/QueryRules';
import { CleanUrlsRuleKeys, decodeCleanUrlsRules } from './brave/CleanUrls';
import { DebounceRule, DebounceRuleKeys, decodeDebounceRules } from './brave/Debounce';
import { QueryFilterRuleKeys, decodeQueryFilterRules } from './brave/QueryFilter';
import { ClearUrlsRuleKeys, ClearUrlsCatalog, decodeClearUrlsRules } from './clearurls/ClearUrls';
import { contentHash } from './ContentHash';

// Re-export rule keys for convenience
export { FirefoxRuleKeys } from './firefox/QueryStripping';
export { CleanUrlsRuleKeys } from './brave/CleanUrls';
export { DebounceRuleKeys } from './brave/Debounce';
export { QueryFilterRuleKeys } from './brave/QueryFilter';
export { ClearUrlsRuleKeys } from './clearurls/ClearUrls';

const FIREFOX_QUERY_STRIPPING_URL: string =
  'https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/query-stripping/records';

const BRAVE_CLEAN_URLS_URL: string =
  'https://raw.githubusercontent.com/brave/adblock-lists/master/brave-lists/clean-urls.json';

const BRAVE_DEBOUNCE_URL: string =
  'https://raw.githubusercontent.com/brave/adblock-lists/master/brave-lists/debounce.json';

const BRAVE_QUERY_FILTER_URL: string =
  'https://raw.githubusercontent.com/brave/adblock-lists/master/brave-lists/query-filter.json';

const CLEAR_URLS_DATA_URL: string = 'https://rules1.clearurls.xyz/data.minify.json';
const CLEAR_URLS_HASH_URL: string = 'https://rules1.clearurls.xyz/rules.minify.hash';

// ── Firefox ──────────────────────────────────────────────────────────

export async function syncQueryStripping(): Promise<void> {
  const body = await fetchText(FIREFOX_QUERY_STRIPPING_URL);
  const data = parseQueryStrippingRecords(body);
  PreferencesHelper.setStringArray(FirefoxRuleKeys.QUERY_STRIPPING_STRIP_LIST, data.stripList);
  PreferencesHelper.setStringArray(FirefoxRuleKeys.QUERY_STRIPPING_ALLOW_LIST, data.allowList);
  PreferencesHelper.setLong(FirefoxRuleKeys.QUERY_STRIPPING_LAST_MODIFIED, data.lastModified);
}

export function getCachedQueryStripping(): QueryStrippingData {
  const data = new QueryStrippingData();
  data.stripList = PreferencesHelper.getStringArray(FirefoxRuleKeys.QUERY_STRIPPING_STRIP_LIST, []);
  data.allowList = PreferencesHelper.getStringArray(FirefoxRuleKeys.QUERY_STRIPPING_ALLOW_LIST, []);
  data.lastModified = PreferencesHelper.getLong(FirefoxRuleKeys.QUERY_STRIPPING_LAST_MODIFIED, 0);
  return data;
}

// ── Brave Clean Urls ─────────────────────────────────────────────────

export async function syncCleanUrls(): Promise<void> {
  await syncBraveRule(BRAVE_CLEAN_URLS_URL, CleanUrlsRuleKeys.RULES, CleanUrlsRuleKeys.VERSION_HASH);
}

export function getCachedCleanUrlsRules(): BraveQueryRule[] {
  return decodeCleanUrlsRules(PreferencesHelper.getString(CleanUrlsRuleKeys.RULES, ''));
}

// ── Brave Debounce ───────────────────────────────────────────────────

export async function syncDebounce(): Promise<void> {
  await syncBraveRule(BRAVE_DEBOUNCE_URL, DebounceRuleKeys.RULES, DebounceRuleKeys.VERSION_HASH);
}

export function getCachedDebounceRules(): DebounceRule[] {
  return decodeDebounceRules(PreferencesHelper.getString(DebounceRuleKeys.RULES, ''));
}

// ── Brave Query Filter ───────────────────────────────────────────────

export async function syncQueryFilter(): Promise<void> {
  await syncBraveRule(BRAVE_QUERY_FILTER_URL, QueryFilterRuleKeys.RULES, QueryFilterRuleKeys.VERSION_HASH);
}

export function getCachedQueryFilterRules(): BraveQueryRule[] {
  return decodeQueryFilterRules(PreferencesHelper.getString(QueryFilterRuleKeys.RULES, ''));
}

// ── 共享同步逻辑 ──────────────────────────────────────────────────────

async function syncBraveRule(url: string, rulesKey: string, versionKey: string): Promise<void> {
  const body = await fetchText(url);
  const validated: Object[] = JSON.parse(body) as Object[]; // 验证 JSON 合法性
  PreferencesHelper.setString(rulesKey, body);
  PreferencesHelper.setString(versionKey, contentHash(body));
}

// ── ClearURLs.xyz ────────────────────────────────────────────────────

export async function syncClearUrls(): Promise<void> {
  const data = await fetchText(CLEAR_URLS_DATA_URL);
  const remoteHash = (await fetchText(CLEAR_URLS_HASH_URL)).trim().toLowerCase();
  if (contentHash(data) !== remoteHash) {
    throw new Error('ClearURLs hash mismatch');
  }
  PreferencesHelper.setString(ClearUrlsRuleKeys.RULES, data);
  PreferencesHelper.setString(ClearUrlsRuleKeys.VERSION_HASH, remoteHash);
}

export function getCachedClearUrlsRules(): ClearUrlsCatalog {
  return decodeClearUrlsRules(PreferencesHelper.getString(ClearUrlsRuleKeys.RULES, ''));
}
