import { RuleConfig } from '../data/rules/RuleConfig';
import { processUTMParams } from './rules/common/UTMParams';
import { processUTMParamsEnhanced } from './rules/common/UTMParamsEnhanced';
import { getBilibiliRedirectTargetHost, processBilibiliRedirectUrl } from './rules/bilibili/BilibiliRedirects';
import { isBilibiliNoParamsTarget, processBilibiliNoParamsUrl } from './rules/bilibili/BilibiliNoParams';
import {
  getCachedQueryStripping,
  getCachedCleanUrlsRules,
  getCachedDebounceRules,
  getCachedQueryFilterRules,
  getCachedClearUrlsRules,
} from './rules/cloud/CloudRuleRepository';
import { processQueryStripping } from './rules/cloud/firefox/QueryStripping';
import { processCleanUrls } from './rules/cloud/brave/CleanUrls';
import { processDebounce } from './rules/cloud/brave/Debounce';
import { processQueryFilter } from './rules/cloud/brave/QueryFilter';
import { processClearUrls } from './rules/cloud/clearurls/ClearUrls';
import { extractUrlList, ParsedUrl, parseUrl } from '../utils/LinkExtractor';
import { PreferencesHelper } from '../utils/PreferencesHelper';

export class RuleIds {
  static readonly BILIBILI: string = 'bilibili_rules';
  static readonly UTM_PARAMS: string = 'utm_params_rules';
  static readonly UTM_PARAMS_ENHANCED: string = 'utm_params_enhanced_rules';
  static readonly FIREFOX_QUERY_STRIPPING: string = 'firefox_query_stripping_rules';
  static readonly BRAVE_CLEAN_URLS: string = 'brave_clean_urls_rules';
  static readonly BRAVE_DEBOUNCE: string = 'brave_debounce_rules';
  static readonly BRAVE_QUERY_FILTER: string = 'brave_query_filter_rules';
  static readonly CLEAR_URLS: string = 'clear_urls_rules';
  static readonly INCOGNITO_MODE: string = 'incognito_mode';
}

const URL_SCHEME_REGEX: RegExp = /^[a-zA-Z][a-zA-Z0-9+.-]*$/;

/**
 * 判断链接是否自带协议头。
 * candidate 须符合 RFC 3986 scheme 语法（字母开头，仅含字母数字 +.−）。
 * 排除 host:port 形式（如 a.com:8080、localhost:3000、intranet:8080）：
 * - candidate 含 "."（域名形态）
 * - ":" 后为纯数字（端口号形态）
 */
export function hasUrlScheme(urlString: string): boolean {
  const colonIndex = urlString.indexOf(':');
  if (colonIndex <= 0) {
    return false;
  }
  const candidate = urlString.substring(0, colonIndex);
  if (!URL_SCHEME_REGEX.test(candidate)) {
    return false;
  }
  // 排除域名形态的 host:port（如 a.com:8080）
  if (candidate.indexOf('.') >= 0) {
    return false;
  }
  // 排除端口号形态的 host:port（如 localhost:3000、intranet:8080）
  const afterColon = urlString.substring(colonIndex + 1);
  if (isDigitsOnly(afterColon)) {
    return false;
  }
  return true;
}

function isDigitsOnly(s: string): boolean {
  if (s.length === 0) {
    return false;
  }
  for (let i = 0; i < s.length; i++) {
    const code = s.charCodeAt(i);
    if (code < 48 || code > 57) {
      return false;
    }
  }
  return true;
}

/**
 * 为不带协议的链接补全 http://，确保 HTTP 请求与 URL 解析正常工作
 */
export function ensureUrlScheme(urlString: string): string {
  return hasUrlScheme(urlString) ? urlString : 'http://' + urlString;
}

/**
 * 保持用户链接原样式：原链接不带协议头时，去掉补全的 http(s):// 前缀
 */
export function applyOriginalSchemeStyle(result: string, hadScheme: boolean): string {
  if (hadScheme) {
    return result;
  }
  if (result.startsWith('https://')) {
    return result.substring('https://'.length);
  }
  if (result.startsWith('http://')) {
    return result.substring('http://'.length);
  }
  return result;
}

export async function processUrl(urlString: string): Promise<string> {
  const ruleConfig = new RuleConfig();
  ruleConfig.UTMParams = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true);
  ruleConfig.UTMParamsEnhanced = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false);
  ruleConfig.bilibili = PreferencesHelper.getBoolean(RuleIds.BILIBILI, true);
  ruleConfig.firefoxQueryStripping = PreferencesHelper.getBoolean(RuleIds.FIREFOX_QUERY_STRIPPING, false);
  ruleConfig.braveCleanUrls = PreferencesHelper.getBoolean(RuleIds.BRAVE_CLEAN_URLS, false);
  ruleConfig.braveDebounce = PreferencesHelper.getBoolean(RuleIds.BRAVE_DEBOUNCE, false);
  ruleConfig.braveQueryFilter = PreferencesHelper.getBoolean(RuleIds.BRAVE_QUERY_FILTER, false);
  ruleConfig.clearUrls = PreferencesHelper.getBoolean(RuleIds.CLEAR_URLS, false);

  const hadScheme = hasUrlScheme(urlString);
  let finalUrl = ensureUrlScheme(urlString);

  // 第一层：去重定向跳转（Brave Debounce）
  if (ruleConfig.braveDebounce) {
    const rules = getCachedDebounceRules();
    if (rules.length > 0) {
      const target = processDebounce(finalUrl, rules);
      if (target !== null) {
        finalUrl = target;
      }
    }
  }

  // 第二层：特定 Host 匹配处理
  const parsed: ParsedUrl | null = parseUrl(finalUrl);
  if (parsed !== null) {
    const host = parsed.host.toLowerCase();

    if (ruleConfig.bilibili && isInHostList(host, getBilibiliRedirectTargetHost())) {
      finalUrl = await processBilibiliRedirectUrl(finalUrl);
    } else if (ruleConfig.bilibili && isBilibiliNoParamsTarget(host)) {
      finalUrl = processBilibiliNoParamsUrl(finalUrl);
    }
  }

  // 第三层：通用参数去除处理
  if (ruleConfig.UTMParams) {
    finalUrl = processUTMParams(finalUrl);
  }
  if (ruleConfig.UTMParamsEnhanced) {
    finalUrl = processUTMParamsEnhanced(finalUrl);
  }
  if (ruleConfig.firefoxQueryStripping) {
    const cloudData = getCachedQueryStripping();
    if (cloudData.stripList.length > 0) {
      finalUrl = processQueryStripping(finalUrl, cloudData.stripList, cloudData.allowList);
    }
  }
  if (ruleConfig.braveCleanUrls) {
    const rules = getCachedCleanUrlsRules();
    if (rules.length > 0) {
      finalUrl = processCleanUrls(finalUrl, rules);
    }
  }
  if (ruleConfig.braveQueryFilter) {
    const rules = getCachedQueryFilterRules();
    if (rules.length > 0) {
      finalUrl = processQueryFilter(finalUrl, rules);
    }
  }
  if (ruleConfig.clearUrls) {
    const catalog = getCachedClearUrlsRules();
    if (catalog.providers.size > 0) {
      finalUrl = processClearUrls(finalUrl, catalog);
    }
  }

  if (finalUrl.length === 0) {
    return urlString;
  }
  return applyOriginalSchemeStyle(finalUrl, hadScheme);
}

function isInHostList(host: string, hosts: string[]): boolean {
  for (let i = 0; i < hosts.length; i++) {
    if (host === hosts[i].toLowerCase()) {
      return true;
    }
  }
  return false;
}

export interface ProcessLinksResult {
  processedText: string;
  processedUrlList: string[];
  isEmpty: boolean;
  isNotHasUrls: boolean;
}

export async function processLinksInText(text: string): Promise<ProcessLinksResult> {
  if (text.length === 0) {
    return {
      processedText: '',
      processedUrlList: [],
      isEmpty: true,
      isNotHasUrls: false
    };
  }

  const urls = extractUrlList(text, true, false);
  if (urls.length === 0) {
    return {
      processedText: text,
      processedUrlList: [],
      isEmpty: false,
      isNotHasUrls: true
    };
  }

  const processedUrlList: string[] = [];
  let resultText = text;
  for (let i = 0; i < urls.length; i++) {
    const processed = await processUrl(urls[i]);
    processedUrlList.push(processed);
    resultText = resultText.replaceAll(urls[i], processed);
  }
  return {
    processedText: resultText,
    processedUrlList: processedUrlList,
    isEmpty: false,
    isNotHasUrls: false
  };
}
